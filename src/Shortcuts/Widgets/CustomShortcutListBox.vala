/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2017-2025 elementary, Inc. (https://elementary.io)
 */

class Keyboard.Shortcuts.CustomShortcutListBox : Gtk.Box {
    private GLib.Settings settings;
    private string[] preferred_languages;
    private ulong settings_load_id = 0;

    private Gtk.ListBox list_box;
    private AppChooser app_chooser;

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

        settings = new GLib.Settings ("io.elementary.settings-daemon.applications");
        preferred_languages = Intl.get_language_names ();

        load_and_display_custom_shortcuts ();
        settings_load_id = settings.changed.connect (load_and_display_custom_shortcuts);

        var app_infos = new GLib.List<GLib.DesktopAppInfo> ();
        foreach (var app_info in GLib.AppInfo.get_all ()) {
            if (app_info is GLib.DesktopAppInfo && app_info.should_show ()) {
                app_infos.append ((GLib.DesktopAppInfo) app_info);
            }
        }

        app_chooser = new AppChooser ();
        app_chooser.init_list (app_infos);

        add_button.clicked.connect (() => {
            app_chooser.transient_for = (Gtk.Window) get_root ();
            app_chooser.present ();
        });

        app_chooser.app_chosen.connect ((filename, parameters) => {
            add_new_shortcut (CustomShortcuts.ActionType.DESKTOP_FILE, filename, parameters);
        });

        app_chooser.custom_command_chosen.connect ((command, parameters) => {
            add_new_shortcut (CustomShortcuts.ActionType.COMMAND_LINE, command, parameters);
        });
    }

    private void load_and_display_custom_shortcuts () {
        while (list_box.get_row_at_index (0) != null) {
            list_box.remove (list_box.get_row_at_index (0));
        }

        var shortcuts = (CustomShortcuts.ParsedShortcut[]) settings.get_value (CustomShortcuts.APPLICATION_SHORTCUTS);
        for (var i = 0; i < shortcuts.length; i++) {
            var row = new CustomShortcutRow (shortcuts[i]);
            row.shortcut_changed.connect (sync_shortcuts);
            list_box.append (row);
        }
    }

    private void add_new_shortcut (CustomShortcuts.ActionType type, string target, GLib.HashTable<string, Variant> parameters) {
        CustomShortcuts.ParsedShortcut new_shortcut = {
            type,
            target,
            parameters,
            {}
        };

        var shortcuts = (CustomShortcuts.ParsedShortcut[]) settings.get_value (CustomShortcuts.APPLICATION_SHORTCUTS);
        shortcuts += new_shortcut;
        settings.set_value (CustomShortcuts.APPLICATION_SHORTCUTS, shortcuts);
    }

    private void sync_shortcuts () {
        Gtk.Widget? _row = list_box.get_first_child ();
        if (_row == null) {
            return;
        }

        var should_rebuild_list = false;
        CustomShortcuts.ParsedShortcut[] shortcuts = {};
        do {
            var row = (CustomShortcutRow) _row;
            if (row.shortcut == null) {
                should_rebuild_list = true;
                continue;
            }

            shortcuts += row.shortcut;
        } while ((_row = _row.get_next_sibling ()) != null);

        if (!should_rebuild_list) {
            GLib.SignalHandler.block (settings, settings_load_id);
        }

        settings.set_value (CustomShortcuts.APPLICATION_SHORTCUTS, shortcuts);

        if (!should_rebuild_list) {
            GLib.SignalHandler.unblock (settings, settings_load_id);
        }
    }
}
