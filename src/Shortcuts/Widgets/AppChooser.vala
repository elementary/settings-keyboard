/* SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class Keyboard.AppChooser : Granite.Dialog {
    public signal void app_chosen (string filename, GLib.HashTable<string, Variant> parameters);
    public signal void custom_command_chosen (string command, GLib.HashTable<string, Variant> parameters);

    private Gtk.ListBox list;
    private Gtk.SearchEntry search_entry;
    private Gtk.Entry custom_entry;

    construct {
        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search Applications")
        };

        list = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        list.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        list.set_sort_func (sort_function);
        list.set_filter_func (filter_function);

        var scrolled = new Gtk.ScrolledWindow () {
            child = list
        };

        var frame = new Gtk.Frame (null) {
            child = scrolled
        };

        custom_entry = new Gtk.Entry () {
            placeholder_text = _("Type in a custom command"),
            primary_icon_activatable = false,
            primary_icon_name = "utilities-terminal-symbolic"
        };

        var box = new Gtk.Box (VERTICAL, 6);
        box.append (search_entry);
        box.append (frame);
        box.append (custom_entry);

        modal = true;
        default_height = 500;
        default_width = 400;
        get_content_area ().append (box);
        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        // TRANSLATORS: This string is used by screen reader
        update_property (Gtk.AccessibleProperty.LABEL, _("Select startup app"), -1);

        search_entry.grab_focus ();
        search_entry.search_changed.connect (() => {
            list.invalidate_filter ();
        });

        response.connect (hide);

        list.row_activated.connect (on_app_selected);
        custom_entry.activate.connect (on_custom_command_entered);
    }

    public void init_list (GLib.List<GLib.DesktopAppInfo> app_infos) {
        foreach (var app_info in app_infos) {
            var icon = app_info.get_icon () ?? new ThemedIcon ("application-default-icon");
            var name = app_info.get_name ();
            var filename = File.new_for_path (app_info.get_filename ()).get_basename ();

            list.prepend (new AppChooserRow ({icon, name, app_info.get_description (), null, filename}));

            var actions = app_info.list_actions ();
            for (var i = 0; i < actions.length; i++) {
                var action = actions[i];
                list.prepend (new AppChooserRow ({icon, name, app_info.get_action_name (action), action, filename}));
            }
        }
    }

    private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        unowned AppChooserRow row_1 = (AppChooserRow) row1.get_child ();
        unowned AppChooserRow row_2 = (AppChooserRow) row2.get_child ();

        var name_1 = row_1.info.name;
        var name_2 = row_2.info.name;

        return name_1.collate (name_2);
    }

    private bool filter_function (Gtk.ListBoxRow list_box_row) {
        var app_row = (AppChooserRow) list_box_row.get_child ();
        return search_entry.text.down () in app_row.info.name.down ()
            || search_entry.text.down () in app_row.info.name.down ();
    }

    private void on_app_selected (Gtk.ListBoxRow list_box_row) {
        var app_row = (AppChooserRow) list_box_row.get_child ();

        var parameters = new GLib.HashTable<string, Variant> (null, null);
        if (app_row.info.action != null) {
            parameters["action"] = app_row.info.action;
        }

        app_chosen (app_row.info.filename, parameters);
        hide ();
    }

    private void on_custom_command_entered () {
        custom_command_chosen (
            custom_entry.text,
            new GLib.HashTable<string, Variant> (null, null)
        );
        hide ();
    }
}
