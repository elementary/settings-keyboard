/* SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class Keyboard.AppChooser : Granite.Dialog {
    public signal void app_chosen (string path);
    public signal void custom_command_chosen (string command);

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

    public void init_list (GLib.List<AppInfo?> app_infos) {
        foreach (var app_info in app_infos) {
            var app_row = new AppChooserRow (app_info);
            list.prepend (app_row);
        }
    }

    private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        unowned AppChooserRow row_1 = (AppChooserRow) row1.get_child ();
        unowned AppChooserRow row_2 = (AppChooserRow) row2.get_child ();

        var name_1 = row_1.app_info.name;
        var name_2 = row_2.app_info.name;

        return name_1.collate (name_2);
    }

    private bool filter_function (Gtk.ListBoxRow list_box_row) {
        var app_row = (AppChooserRow) list_box_row.get_child ();
        return search_entry.text.down () in app_row.app_info.name.down ()
            || search_entry.text.down () in app_row.app_info.comment.down ();
    }

    private void on_app_selected (Gtk.ListBoxRow list_box_row) {
        var app_row = (AppChooserRow) list_box_row.get_child ();
        app_chosen (app_row.app_info.path);
        hide ();
    }

    private void on_custom_command_entered () {
        custom_command_chosen (custom_entry.text);
        hide ();
    }
}
