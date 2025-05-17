/*
* Copyright 2017-2020 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class Keyboard.LayoutPage.AddLayoutDialog : Granite.Dialog {
    private const string INPUT_LANGUAGE = N_("Input Language");
    private const string LAYOUT_LIST = N_("Layout List");

    public signal void layout_added (string language, string layout);
    private Gtk.ListBox input_language_list_box;
    private Gtk.ListBox layout_list_box;
    private GLib.ListStore language_list;
    private GLib.ListStore layout_list;
    private XkbLayoutHandler handler;

    private string layout_id;

    construct {
        default_height = 450;
        default_width = 750;

        var search_entry = new Gtk.SearchEntry () {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 6,
            margin_start = 12,
            placeholder_text = _("Search input language")
        };

        handler = XkbLayoutHandler.get_instance ();

        language_list = new GLib.ListStore (typeof (ListStoreItem));
        layout_list = new GLib.ListStore (typeof (ListStoreItem));

        update_list_store (language_list, handler.languages);
        var first_lang = language_list.get_item (0) as ListStoreItem;
        update_list_store (layout_list, handler.get_variants_for_language (first_lang.id));

        input_language_list_box = new Gtk.ListBox ();
        for (int i = 0; i < language_list.get_n_items (); i++) {
            var item = language_list.get_item (i) as ListStoreItem;
            var row = new LayoutRow (item.name);

            input_language_list_box.append (row);
        }

        var input_language_scrolled = new Gtk.ScrolledWindow () {
            child = input_language_list_box,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        var input_language_box = new Gtk.Box (VERTICAL, 0);
        input_language_box.append (search_entry);
        input_language_box.append (input_language_scrolled);

        var back_button = new Gtk.Button.with_label (_(INPUT_LANGUAGE)) {
            halign = Gtk.Align.START,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        back_button.add_css_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var layout_list_title = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.END,
            use_markup = true
        };

        layout_list_box = new Gtk.ListBox () {
            margin_top = 3
        };

        layout_list_box.bind_model (layout_list, (item) => {
            return new LayoutRow (((ListStoreItem)item).name);
        });

        var layout_scrolled = new Gtk.ScrolledWindow () {
            child = layout_list_box,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        var keyboard_map_button = new Gtk.Button.with_label (_("Preview Layout")) {
            halign = Gtk.Align.END,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };

        var keyboard_map_revealer = new Gtk.Revealer () {
            child = keyboard_map_button,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };

        var header_box = new Gtk.CenterBox () {
            start_widget = back_button,
            center_widget = layout_list_title,
            end_widget = keyboard_map_revealer,
            hexpand = true
        };

        var header_grid = new Gtk.Grid ();
        header_grid.attach (header_box, 0, 0);
        header_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 1);

        var header_revealer = new Gtk.Revealer () {
            child = header_grid
        };

        var deck = new Adw.Leaflet () {
            can_navigate_back = true,
            can_unfold = false,
            hexpand = true,
            vexpand = true
        };
        deck.append (input_language_box);
        deck.append (layout_scrolled);

        var frame_box = new Gtk.Box (VERTICAL, 0);
        frame_box.append (header_revealer);
        frame_box.append (deck);

        var frame = new Gtk.Frame (null) {
            child = frame_box,
            margin_start = 10,
            margin_end = 10
        };
        frame.add_css_class (Granite.STYLE_CLASS_VIEW);

        var button_cancel = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var button_add = add_button (_("Add Layout"), Gtk.ResponseType.ACCEPT);
        button_add.sensitive = false;
        button_add.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        deletable = false;
        modal = true;
        get_content_area ().append (frame);

        search_entry.grab_focus ();

        deck.notify["visible-child"].connect (() => {
            if (deck.visible_child == input_language_box) {
                header_revealer.reveal_child = false;
                layout_list_box.unselect_all ();
            } else if (deck.visible_child == layout_scrolled) {
                header_revealer.reveal_child = true;
                keyboard_map_revealer.reveal_child = true;

                back_button.label = _(INPUT_LANGUAGE);
                layout_list_title.label = "<b>%s</b>".printf (get_selected_lang ().name);
            }
        });

        input_language_list_box.set_filter_func ((list_box_row) => {
            var item = language_list.get_item (list_box_row.get_index ()) as ListStoreItem;
            return search_entry.text.down () in item.name.down ();
        });

        search_entry.search_changed.connect (() => {
            input_language_list_box.invalidate_filter ();
        });

        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.HELP) {
                return;
            } else if (response_id == Gtk.ResponseType.ACCEPT) {
                layout_added (get_selected_lang ().id, get_selected_layout ().id);
            }
            destroy ();
        });

        back_button.clicked.connect (() => {
            deck.navigate (Adw.NavigationDirection.BACK);
        });

        input_language_list_box.row_activated.connect (() => {
            var selected_lang = get_selected_lang ();
            update_list_store (layout_list, handler.get_variants_for_language (selected_lang.id));
            layout_list_box.select_row (layout_list_box.get_row_at_index (0));
            if (layout_list_box.get_row_at_index (0) != null) {
                layout_list_box.get_row_at_index (0).grab_focus ();
            }

            deck.visible_child = layout_scrolled;
        });

        keyboard_map_button.clicked.connect (() => {
            string command = "gkbd-keyboard-display \"--layout=" + layout_id + "\"";
            try {
                GLib.AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.NONE).launch (null, null);
            } catch (Error e) {
                warning ("Error launching keyboard layout display: %s", e.message);
            }
        });

        layout_list_box.row_selected.connect ((row) => {
            keyboard_map_button.sensitive = row != null;
            button_add.sensitive = row != null;

            if (row != null) {
                layout_id = "%s\t%s".printf (get_selected_lang ().id, get_selected_layout ().id);
            }
        });
    }

    private ListStoreItem get_selected_lang () {
        var selected_lang_row = input_language_list_box.get_selected_row ();
        return language_list.get_item (selected_lang_row.get_index ()) as ListStoreItem;
    }

    private ListStoreItem get_selected_layout () {
        var selected_layout_row = layout_list_box.get_selected_row ();
        return layout_list.get_item (selected_layout_row.get_index ()) as ListStoreItem;
    }

    private void update_list_store (GLib.ListStore store, HashTable<string, string> values) {
        store.remove_all ();

        values.foreach ((key, val) => {
            store.append (new ListStoreItem (key, val));
        });

        store.sort ((a, b) => {
            if (((ListStoreItem)a).name == _("Default")) {
                return -1;
            }

            if (((ListStoreItem)b).name == _("Default")) {
                return 1;
            }

            return ((ListStoreItem)a).name.collate (((ListStoreItem)b).name);
        });
    }

    private class ListStoreItem : Object {
        public string id { get; construct; }
        public string name { get; construct; }

        public ListStoreItem (string id, string name) {
            Object (
                id: id,
                name: name
            );
        }
    }

    private class LayoutRow : Gtk.ListBoxRow {
        public string rname { get; construct; }
        public LayoutRow (string name) {
            Object (rname: name);
        }

        construct {
            var label = new Gtk.Label (rname) {
                margin_top = 6,
                margin_end = 12,
                margin_bottom = 6,
                margin_start = 12,
                xalign = 0
            };

            child = label;
        }
    }
}
