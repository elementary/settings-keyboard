/*
* Copyright 2019-2024 elementary, Inc. (https://elementary.io)
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

public class Keyboard.InputMethodPage.AddEngineDialog : Granite.Dialog {
    public signal void add_engine (string new_engine);

    public unowned List<IBus.EngineDesc> engines { get; construct; }

    private Gtk.SearchEntry search_entry;
    private GLib.ListStore liststore;
    private Gtk.ListBox listbox;

    public AddEngineDialog (List<IBus.EngineDesc> engines) {
        Object (engines: engines);
    }

    construct {
        default_height = 450;
        default_width = 750;

        search_entry = new Gtk.SearchEntry () {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 6,
            margin_start = 12,
            ///TRANSLATORS: This text appears in a search entry and tell users to type some search word
            ///to look for a input method engine they want to add.
            ///It does not mean search engines in web browsers.
            placeholder_text = _("Search engine")
        };

        liststore = new GLib.ListStore (Type.OBJECT);

        listbox = new Gtk.ListBox () {
            activate_on_single_click = false
        };

        var scrolled = new Gtk.ScrolledWindow () {
            child = listbox,
            hexpand = true,
            vexpand = true,
            height_request = 300,
            width_request = 500
        };

        var frame_box = new Gtk.Box (VERTICAL, 0);
        frame_box.append (search_entry);
        frame_box.append (scrolled);

        var frame = new Gtk.Frame (null) {
            child = frame_box,
            margin_start = 10,
            margin_end = 10
        };
        frame.add_css_class (Granite.STYLE_CLASS_VIEW);

        get_content_area ().append (frame);

        var install_button = add_button (_("Install Unlisted Engines…"), Gtk.ResponseType.OK);

        var cancel_button = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var add_button = add_button (_("Add Engine"), Gtk.ResponseType.ACCEPT);
        add_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        listbox.row_activated.connect (trigger_add_engine);

        listbox.set_filter_func ((list_box_row) => {
            var item = (AddEnginesList) liststore.get_item (list_box_row.get_index ());
                //NOTE: xkb engines do not work unless IBus preferences set to not use system keyboard
                //FIXME: Handle this IBus preference in UI or disallow xkb engines if using system keyboard
                return search_entry.text.down () in item.engine_full_name.down ();
        });

        search_entry.search_changed.connect (() => {
            listbox.invalidate_filter ();
        });

        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.OK) {
                var installer = UbuntuInstaller.get_default ();
                var install_dialog = new InstallEngineDialog (this) {
                    modal = true
                };
                install_dialog.response.connect ((response_id) => {
                    if (response_id == Gtk.ResponseType.OK) {
                        string engine_to_install = install_dialog.get_selected_engine_name ();
                        install_dialog.destroy ();
                        installer.install (engine_to_install);

                        var progress_dialog = new ProgressDialog () {
                            transient_for = (Gtk.Window) get_root ()
                        };
                        installer.progress_changed.connect ((p) => {
                            progress_dialog.progress = p;
                        });
                        progress_dialog.present ();
                    } else {
                        install_dialog.destroy ();
                    }
                });
                install_dialog.present ();
            } else if (response_id == Gtk.ResponseType.ACCEPT) {
                trigger_add_engine (listbox.get_selected_row ());
                close ();
            } else {
                close ();
            }
        });

        update_engines_list ();
    }

    private void trigger_add_engine (Gtk.ListBoxRow row) {
        int index = row.get_index ();

        // Signal handler to ensure engine not added twice.
        add_engine (((AddEnginesList) liststore.get_item (index)).engine_id);
        close ();
    }

    private void update_engines_list () {
        var engine_lists = new List<AddEnginesList> ();
        foreach (var engine in engines) {
            var full_name = "%s - %s".printf (
                IBus.get_language_name (engine.language), Utils.gettext_engine_longname (engine)
            );

            engine_lists.append (new AddEnginesList (engine.name, full_name));
        }

        foreach (var engine_list in engine_lists) {
            liststore.append (engine_list);
        }

        liststore.sort ((a, b) => {
            return ((AddEnginesList) a).engine_full_name.collate (((AddEnginesList) b).engine_full_name);
        });

        for (int i = 0; i < liststore.get_n_items (); i++) {
            var label = new Gtk.Label (((AddEnginesList) liststore.get_item (i)).engine_full_name) {
                halign = Gtk.Align.START,
                margin_top = 6,
                margin_end = 12,
                margin_bottom = 6,
                margin_start = 12
            };

            var listboxrow = new Gtk.ListBoxRow () {
                child = label
            };

            listbox.append (listboxrow);
        }

        listbox.select_row (listbox.get_row_at_index (0));
        search_entry.grab_focus ();
    }
}
