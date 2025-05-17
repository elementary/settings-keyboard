/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2017-2025 elementary, Inc. (https://elementary.io)
 */

class Keyboard.Shortcuts.CustomShortcutListBox : Gtk.Box {
    private Gtk.ListBox list_box;
    construct {
        list_box = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true,
            selection_mode = Gtk.SelectionMode.BROWSE
        };

        var add_button_label = new Gtk.Label (_("Add Shortcut"));

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
        add_button_box.append (add_button_label);

        var add_button = new Gtk.Button () {
            child = add_button_box,
            margin_top = 3,
            margin_bottom = 3
        };
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        add_button_label.mnemonic_widget = add_button;

        var actionbar = new Gtk.ActionBar () {
            hexpand = true
        };
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        actionbar.pack_start (add_button);

        orientation = VERTICAL;
        append (list_box);
        append (actionbar);

        load_and_display_custom_shortcuts ();

        add_button.clicked.connect (on_add_clicked);
    }

    private void load_and_display_custom_shortcuts () {
        while (list_box.get_row_at_index (0) != null) {
            list_box.remove (list_box.get_row_at_index (0));
        }

        foreach (var custom_shortcut in CustomShortcutSettings.list_custom_shortcuts ()) {
            list_box.append (new CustomShortcutRow (custom_shortcut));
        }
    }

    private void add_row (CustomShortcut? shortcut) {
        CustomShortcutRow new_row;
        if (shortcut != null) {
            new_row = new CustomShortcutRow (shortcut);
        } else {
            var relocatable_schema = CustomShortcutSettings.create_shortcut ();
            CustomShortcut new_custom_shortcut = {"", "", relocatable_schema};
            new_row = new CustomShortcutRow (new_custom_shortcut);
        }

        list_box.append (new_row);
        list_box.select_row (new_row);
    }

    private void on_add_clicked () {
        add_row (null);
        list_box.unselect_all ();
    }
}
