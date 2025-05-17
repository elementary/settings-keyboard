/*
* Copyright (c) 2017-2025 elementary, LLC. (https://elementary.io)
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

        var data_dirs = Environment.get_system_data_dirs ();
        data_dirs += Environment.get_user_data_dir ();

        var app_infos = new GLib.List<AppInfo?> ();
        foreach (unowned string data_dir in data_dirs) {
            var app_dir = Path.build_filename (data_dir, "applications");
            if (FileUtils.test (app_dir, FileTest.EXISTS)) {
                try {
                    foreach (var name in enumerate_children (app_dir)) {
                        if (!name.contains ("~") && name.has_suffix (".desktop")) {
                            var app_info = get_app_info_for_file (Path.build_filename (app_dir, name));
                            if (app_info != null) {
                                app_infos.append (app_info);
                            }
                        }
                    }
                } catch (Error e) {
                    debug ("Error inside %s: %s", app_dir, e.message);
                }
            }
        }

        app_chooser = new AppChooser ();
        app_chooser.init_list (app_infos);

        realize.connect (() => {
            list_box.select_row (list_box.get_row_at_index (0));
        });

        add_button.clicked.connect (() => {
            list_box.unselect_all ();

            app_chooser.transient_for = (Gtk.Window) get_root ();
            app_chooser.present ();
        });

        app_chooser.app_chosen.connect ((path) => {
            var filename = GLib.File.new_for_path (path).get_basename ();
            if (filename == null) {
                return;
            }

            add_new_shortcut (CustomShortcuts.ActionType.DESKTOP_FILE, filename);
        });

        app_chooser.custom_command_chosen.connect ((command) => {
            add_new_shortcut (CustomShortcuts.ActionType.COMMAND_LINE, command);
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

    private string[] enumerate_children (string dir) throws Error {
        string[] result = {};
        FileInfo file_info;
        var enumerator = File.new_for_path (dir).enumerate_children (FileAttribute.STANDARD_NAME, 0);
        while ((file_info = enumerator.next_file ()) != null)
            result += file_info.get_name ();
        return result;
    }

    private AppInfo? get_app_info_for_file (string path) {
        try {
            var keyfile = new GLib.KeyFile ();
            keyfile.load_from_file (path, GLib.KeyFileFlags.KEEP_TRANSLATIONS);

            return AppInfo () {
                name = keyfile_get_locale_string (keyfile, KeyFileDesktop.KEY_NAME),
                comment = keyfile_get_locale_string (keyfile, KeyFileDesktop.KEY_COMMENT),
                icon = keyfile_get_locale_string (keyfile, KeyFileDesktop.KEY_ICON),
                path = path
            };
        } catch (Error e) {
            warning (e.message);
            return null;
        }
    }

    private string keyfile_get_locale_string (GLib.KeyFile keyfile, string key) {
        foreach (var lang in preferred_languages) {
            try {
                return keyfile.get_locale_string (KeyFileDesktop.GROUP, key, lang);
            } catch (KeyFileError e) {
                debug (e.message);
            }
        }

        return "";
    }

    private void add_new_shortcut (CustomShortcuts.ActionType type, string target) {
        CustomShortcuts.ParsedShortcut new_shortcut = {
            type,
            target,
            new GLib.HashTable<string, Variant> (GLib.str_hash, GLib.str_equal),
            {}
        };

        var shortcuts = (CustomShortcuts.ParsedShortcut[]) settings.get_value (CustomShortcuts.APPLICATION_SHORTCUTS);
        shortcuts += new_shortcut;
        settings.set_value (CustomShortcuts.APPLICATION_SHORTCUTS, shortcuts);
    }

    private void sync_shortcuts () {
        GLib.SignalHandler.block (settings, settings_load_id);

        Gtk.Widget? _row = list_box.get_first_child ();
        if (_row == null) {
            return;
        }

        CustomShortcuts.ParsedShortcut[] shortcuts = {};
        do {
            var row = (CustomShortcutRow) _row;
            shortcuts += row.shortcut;
        } while ((_row = _row.get_next_sibling ()) != null);

        settings.set_value (CustomShortcuts.APPLICATION_SHORTCUTS, shortcuts);

        GLib.SignalHandler.unblock (settings, settings_load_id);
    }
}
