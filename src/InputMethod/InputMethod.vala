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

public class Keyboard.InputMethodPage.Page : Gtk.Box {
    private IBus.Bus bus;
    private GLib.Settings ibus_panel_settings;
    private bool selection_changing = false;
    // Stores all installed engines
#if IBUS_1_5_19
    private List<IBus.EngineDesc> engines;
#else
    private List<weak IBus.EngineDesc> engines;
#endif

    private Granite.Placeholder spawn_failed_alert;
    private Gtk.ListBox listbox;
    private SourceSettings settings;
    private Gtk.Button remove_button;
    private Gtk.Stack stack;
    private Gtk.Entry entry_test;
    private Gtk.ComboBoxText keyboard_shortcut_combobox;

    construct {
        settings = SourceSettings.get_instance ();
        bus = new IBus.Bus ();
        ibus_panel_settings = new GLib.Settings ("org.freedesktop.ibus.panel");

        // See https://github.com/elementary/switchboard-plug-keyboard/pull/468
        var keyboard_settings = new GLib.Settings ("io.elementary.settings.keyboard");
        if (keyboard_settings.get_boolean ("first-launch")) {
            keyboard_settings.set_boolean ("first-launch", false);
            Keyboard.Plug.ibus_general_settings.set_strv ("preload-engines", {});
        }

        // no_daemon_runnning view shown if IBus Daemon is not running
        var no_daemon_runnning_alert = new Granite.Placeholder (_("IBus Daemon is not running")) {
            description = _("IBus daemon must run in the background to enable or configure input method engines."),
            icon = new ThemedIcon ("dialog-information"),
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        no_daemon_runnning_alert.remove_css_class (Granite.STYLE_CLASS_VIEW);

        var ibus_button = no_daemon_runnning_alert.append_button (
            new ThemedIcon ("ibus-setup"),
            _("Start IBus Daemon"),
            _("Can be managed in System Settings → Applications → Startup")
        );
        ibus_button.clicked.connect (spawn_ibus_daemon);

        // spawn_failed view shown if IBus Daemon is not running
        spawn_failed_alert = new Granite.Placeholder (
            _("Could not start the IBus daemon")
        ) {
            icon = new ThemedIcon ("dialog-error"),
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };

        // normal view shown if IBus Daemon is already running
        listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true,
            selection_mode = Gtk.SelectionMode.BROWSE  //One or none selected
        };

        listbox.row_selected.connect ((row) => {
            // Multiple "row-selected" signals get emitted for change and this handler
            // is not re-entrant, causing a crash. So a workaround is added to stop this
            if (!selection_changing && row is Gtk.ListBoxRow) {
                selection_changing = true;
                string engine_name = row.get_data ("engine-name");
                settings.set_active_engine_name (engine_name);
                bus.set_global_engine (engine_name);
                update_entry_test_usable ();
                selection_changing = false;
            }
        });

        bus.set_watch_ibus_signal (true);
        bus.global_engine_changed.connect ((name) => {
            update_list_box_selected_row ();
            update_entry_test_usable ();
        });

        var scroll = new Gtk.ScrolledWindow () {
            child = listbox,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        var add_button_label = new Gtk.Label (_("Add Engine…"));

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
        add_button_box.append (add_button_label);

        var add_button = new Gtk.Button () {
            child = add_button_box
        };
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        add_button_label.mnemonic_widget = add_button;

        add_button.clicked.connect (() => {
            var dialog = new AddEngineDialog (engines) {
                transient_for = (Gtk.Window) get_root (),
                modal = true
            };

            dialog.present ();
            dialog.add_engine.connect ((engine) => {
                if (settings.add_active_engine (engine)) {
                    update_engines_list ();
                }
            });
        });

        remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic") {
            tooltip_text = _("Remove")
        };

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        actionbar.pack_start (add_button);
        actionbar.pack_start (remove_button);

        var left_box = new Gtk.Box (VERTICAL, 0);
        left_box.append (scroll);
        left_box.append (actionbar);

        var display = new Gtk.Frame (null) {
            child = left_box
        };

        var keyboard_shortcut_label = new Gtk.Label (_("Switch engines:")) {
            halign = Gtk.Align.END
        };

        keyboard_shortcut_combobox = new Gtk.ComboBoxText () {
            halign = Gtk.Align.START
        };

        keyboard_shortcut_combobox.append ("disabled", _("Disabled"));
        keyboard_shortcut_combobox.append ("alt-space", Granite.accel_to_string ("<Alt>space"));
        keyboard_shortcut_combobox.append ("ctl-space", Granite.accel_to_string ("<Control>space"));
        keyboard_shortcut_combobox.append ("shift-space", Granite.accel_to_string ("<Shift>space"));

        keyboard_shortcut_combobox.notify["active-id"].connect (() => {
            set_keyboard_shortcut (keyboard_shortcut_combobox.active_id);
        });

        var show_ibus_panel_label = new Gtk.Label (_("Show property panel:")) {
            halign = Gtk.Align.END
        };

        var show_ibus_panel_combobox = new Gtk.ComboBoxText () {
            halign = Gtk.Align.START
        };
        show_ibus_panel_combobox.append ("none", _("Do not show"));
        show_ibus_panel_combobox.append ("auto-hide", _("Auto hide"));
        show_ibus_panel_combobox.append ("always-show", _("Always show"));

        var embed_preedit_text_label = new Gtk.Label (_("Embed preedit text in application window:")) {
            halign = Gtk.Align.END
        };

        var embed_preedit_text_switch = new Gtk.Switch () {
            halign = Gtk.Align.START
        };

        entry_test = new Gtk.Entry () {
            hexpand = true,
            valign = Gtk.Align.END
        };

        update_entry_test_usable ();

        var right_grid = new Gtk.Grid () {
            column_spacing = 12,
            halign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12,
            row_spacing = 12
        };
        right_grid.attach (keyboard_shortcut_label, 0, 0);
        right_grid.attach (keyboard_shortcut_combobox, 1, 0);
        right_grid.attach (show_ibus_panel_label, 0, 1);
        right_grid.attach (show_ibus_panel_combobox, 1, 1);
        right_grid.attach (embed_preedit_text_label, 0, 2);
        right_grid.attach (embed_preedit_text_switch, 1, 2);

        var main_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12
        };
        main_grid.attach (display, 0, 0, 1, 2);
        main_grid.attach (right_grid, 1, 0);
        main_grid.attach (entry_test, 1, 1);

        stack = new Gtk.Stack ();
        stack.add_named (no_daemon_runnning_alert, "no_daemon_runnning_view");
        stack.add_named (spawn_failed_alert, "spawn_failed_view");
        stack.add_named (main_grid, "main_view");

        margin_start = 12;
        margin_end = 12;
        margin_bottom = 12;
        margin_top = 12;
        append (stack);

        set_visible_view ();

        remove_button.clicked.connect (() => {
            int index = listbox.get_selected_row ().get_index ();

            // Convert to GLib.Array once, because Vala does not support "-=" operator
            Array<string> removed_lists = new Array<string> ();
            foreach (var active_engine in settings.active_engines) {
                removed_lists.append_val (active_engine);
            }

            // Remove applicable engine from the list
            removed_lists.remove_index (index);

            /*
             * Substitute the contents of removed_lists through another string array,
             * because array concatenation is not supported for public array variables and parameters
             */
            string[] new_engines;
            for (int i = 0; i < removed_lists.length; i++) {
                new_engines += removed_lists.index (i);
            }

            settings.active_engines = new_engines;
            update_engines_list ();
            settings.active_index = 0; // Not obvious what to do when  currently active input source is removed
        });

        ibus_panel_settings.bind ("show", show_ibus_panel_combobox, "active", SettingsBindFlags.DEFAULT);
        Keyboard.Plug.ibus_general_settings.bind ("embed-preedit-text", embed_preedit_text_switch, "active", SettingsBindFlags.DEFAULT);

        settings.notify["active-index"].connect (() => {
            update_list_box_selected_row ();
            update_entry_test_usable ();
        });

        update_list_box_selected_row ();
    }

    private string get_keyboard_shortcut_id () {
        // TODO: Support getting multiple shortcut keys like ibus-setup does
        string[] keyboard_shortcuts = Keyboard.Plug.ibus_general_settings.get_child ("hotkey").get_strv ("triggers");

        string keyboard_shortcut_id = "";
        foreach (var ks in keyboard_shortcuts) {
            switch (ks) {
                case "<Alt>space":
                    keyboard_shortcut_id = "alt-space";
                    break;
                case "<Shift>space":
                    keyboard_shortcut_id = "shift-space";
                    break;
                case "<Control>space":
                    keyboard_shortcut_id = "ctl-space";
                    break;
                default:
                    break;
            }
        }

        return keyboard_shortcut_id;
    }

    private void set_keyboard_shortcut (string combobox_id) {
        // TODO: Support setting multiple shortcut keys like ibus-setup does
        string[] keyboard_shortcuts = {};
        if (combobox_id != null) {
            switch (combobox_id) {
                case "alt-space":
                    keyboard_shortcuts += "<Alt>space";
                    break;
                case "shift-space":
                    keyboard_shortcuts += "<Shift>space";
                    break;
                case "control-space":
                    keyboard_shortcuts += "<Control>space";
                    break;
                case "disabled":
                    break;
                default:
                    assert_not_reached ();
            }
        }

        Keyboard.Plug.ibus_general_settings.get_child ("hotkey").set_strv ("triggers", keyboard_shortcuts);
    }

    private void update_engines_list () {
        engines = bus.list_engines ();

        while (listbox.get_row_at_index (0) != null) {
            listbox.remove (listbox.get_row_at_index (0));
        };

        // Add the language and the name of activated engines
        settings.reset (LayoutType.IBUS);
        foreach (var active_engine in settings.active_engines) {
            foreach (var engine in engines) {
                if (engine.name == active_engine) {
                    var engine_full_name = "%s - %s".printf (
                        IBus.get_language_name (engine.language), Utils.gettext_engine_longname (engine)
                    );

                    var label = new Gtk.Label (engine_full_name) {
                        halign = Gtk.Align.START,
                        margin_top = 6,
                        margin_end = 6,
                        margin_bottom = 6,
                        margin_start = 6
                    };

                    var listboxrow = new Gtk.ListBoxRow () {
                        child = label
                    };
                    listboxrow.set_data<string> ("engine-name", engine.name);

                    listbox.append (listboxrow);
                    settings.add_layout (InputSource.new_ibus (engine.name));
                }
            }
        }

        //Do not autoselect the first entry as that would change the active input method
        remove_button.sensitive = listbox.get_selected_row () != null;
        // If ibus is running, update its autostart file according to whether there are input methods active
        if (stack.visible_child_name == "main_view") {
            write_ibus_autostart_file (listbox.get_row_at_index (0) != null);
        }

        update_keyboard_shortcut_combo ();
    }

    private void spawn_ibus_daemon () {
        bool is_spawn_succeeded = false;
        try {
            is_spawn_succeeded = Process.spawn_sync ("/", { "ibus-daemon", "-drx" }, Environ.get (), SpawnFlags.SEARCH_PATH, null);
        } catch (GLib.SpawnError e) {
            warning (e.message);
            set_visible_view (e.message);
            return;
        }

        uint timeout_start_daemon = Timeout.add (500, () => {
            set_visible_view ();
            return Gdk.EVENT_PROPAGATE;
        });
        timeout_start_daemon = 0;

        if (is_spawn_succeeded & listbox.get_row_at_index (0) != null) {
            write_ibus_autostart_file (true);
        }
    }

    private void write_ibus_autostart_file (bool enable) {
        // Get path to user's startup directory (typically ~/.config/autostart)
        var config_dir = Environment.get_user_config_dir ();
        var startup_dir = Path.build_filename (config_dir, "autostart");

        // If startup directory doesn't exist, create it.
        if (!FileUtils.test (startup_dir, FileTest.EXISTS)) {
            var file = File.new_for_path (startup_dir);

            try {
                file.make_directory_with_parents ();
            } catch (Error e) {
                warning (e.message);
                return;
            }
        }

        // Construct keyfile for ibus-daemon.desktop
        var languages = Intl.get_language_names ();
        var preferred_language = languages [0];

        var keyfile = new GLib.KeyFile ();
        keyfile.set_locale_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME, preferred_language, _("IBus Daemon"));
        keyfile.set_locale_string (
            KeyFileDesktop.GROUP, KeyFileDesktop.KEY_COMMENT, preferred_language,
            _("Use and manage input methods")
        );
        keyfile.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_EXEC, "ibus-daemon -drx");
        keyfile.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON, "ibus-setup");
        keyfile.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE, "Application");
        keyfile.set_boolean (KeyFileDesktop.GROUP, "X-GNOME-Autostart-enabled", enable);

        var path = Path.build_filename (startup_dir, "ibus-daemon.desktop");

        // Create or update desktop file
        try {
            GLib.FileUtils.set_contents (path, keyfile.to_data ());
        } catch (Error e) {
            warning ("Could not write to file %s: %s", path, e.message);
        }
    }

    private void set_visible_view (string error_message = "") {
        if (error_message != "") {
            stack.visible_child_name = "spawn_failed_view";
            spawn_failed_alert.description = error_message;
        } else if (bus.is_connected ()) {
            stack.visible_child_name = "main_view";
            update_engines_list ();
        } else {
            stack.visible_child_name = "no_daemon_runnning_view";
        }
    }

    private void update_entry_test_usable () {
        if (settings.active_input_source != null &&
            settings.active_input_source.layout_type == LayoutType.IBUS) {

            entry_test.placeholder_text = _("Type to test your input method");
            entry_test.sensitive = true;
        } else {
            entry_test.placeholder_text = _("A keyboard layout is active");
            entry_test.sensitive = false;
        }
    }

    private void update_list_box_selected_row () {
        var engine_name = "";

        if (settings.active_input_source != null &&
            settings.active_input_source.layout_type == LayoutType.IBUS) {

            engine_name = settings.active_input_source.name;
            bus.set_global_engine (engine_name);
        }

        /* Emitting "unselect_all ()" on listbox does not unselect rows for some reason so we
         * unselect rows individually */

        unowned var child = listbox.get_first_child ();
        while (child != null) {
            if (child is Gtk.ListBoxRow) {
                var row = (Gtk.ListBoxRow) child;
                var row_name = row.get_data<string> ("engine-name");
                if (row_name == engine_name) {
                    listbox.select_row (row);
                } else {
                    listbox.unselect_row (row);
                }
            }

            child = child.get_next_sibling ();
        }

        remove_button.sensitive = listbox.get_selected_row () != null;
    }

    private void update_keyboard_shortcut_combo () {
        if (settings.active_engines.length < 2) {
            keyboard_shortcut_combobox.sensitive = false;
            keyboard_shortcut_combobox.active_id = "disabled";
        } else {
            keyboard_shortcut_combobox.sensitive = true;
            keyboard_shortcut_combobox.active_id = get_keyboard_shortcut_id ();
        }
    }
}
