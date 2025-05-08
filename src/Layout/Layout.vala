/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2017-2023 elementary, Inc. (https://elementary.io)
 */

public class Keyboard.LayoutPage.Page : Gtk.Grid {
    private const string MULTITASKING_VIEW_COMMAND = "dbus-send --session --dest=org.pantheon.gala --print-reply /org/pantheon/gala org.pantheon.gala.PerformAction int32:1";

    private AdvancedSettingsPanel? [] panels;
    private Display display;
    private HashTable <string, string> panel_for_layout;
    private SourceSettings settings;
    private Gtk.SizeGroup [] size_group;
    private Gtk.Entry entry_test;
    private Gtk.Stack stack;
    private GLib.Settings input_sources_settings;

    construct {
        settings = SourceSettings.get_instance ();

        size_group = {
            new Gtk.SizeGroup (HORIZONTAL),
            new Gtk.SizeGroup (HORIZONTAL)
        };

        // tree view to display the current layouts
        display = new LayoutPage.Display ();

        // Layout switching keybinding
        var modifier = new XkbModifier ("switch-layout");
        modifier.append_xkb_option ("", _("Disabled"));
        modifier.append_xkb_option ("grp:alt_caps_toggle", _("Alt + Caps Lock"));
        modifier.append_xkb_option ("grp:alt_shift_toggle", _("Alt + Shift"));
        modifier.append_xkb_option ("grp:alt_space_toggle", _("Alt + Space"));
        modifier.append_xkb_option ("grp:shifts_toggle", _("Both Shift keys together"));
        modifier.append_xkb_option ("grp:caps_toggle", _("Caps Lock"));
        modifier.append_xkb_option ("grp:ctrl_alt_toggle", _("Ctrl + Alt"));
        modifier.append_xkb_option ("grp:ctrl_shift_toggle", _("Ctrl + Shift"));
        modifier.append_xkb_option ("grp:shift_caps_toggle", _("Shift + Caps Lock"));
        modifier.set_default_command ("");

        settings.add_xkb_modifier (modifier);

        var switch_layout_combo = create_xkb_combobox (modifier);

        var switch_layout_label = create_settings_label (
            _("Switch layout:"),
            switch_layout_combo
        );

        // Compose key position menu
        modifier = new XkbModifier ();
        modifier.append_xkb_option ("", _("Disabled"));
        modifier.append_xkb_option ("compose:caps", _("Caps Lock"));
        modifier.append_xkb_option ("compose:menu", _("Menu"));
        modifier.append_xkb_option ("compose:ralt", _("Right Alt"));
        modifier.append_xkb_option ("compose:rctrl", _("Right Ctrl"));
        modifier.append_xkb_option ("compose:rwin", _("Right ⌘"));
        modifier.set_default_command ("");

        settings.add_xkb_modifier (modifier);

        var compose_key_combo = create_xkb_combobox (modifier);

        var compose_key_label = create_settings_label (
            _("Compose key:"),
            compose_key_combo
        );

        // ⌘ key behavior
        var overlay_key_combo = new Gtk.ComboBoxText () {
            halign = START
        };
        overlay_key_combo.append_text (_("Disabled"));
        overlay_key_combo.append_text (_("Applications Menu"));
        overlay_key_combo.append_text (_("Multitasking View"));

        var overlay_key_label = create_settings_label (
            _("⌘ key behavior:"),
            overlay_key_combo
        );

        string? cheatsheet_path = Environment.find_program_in_path ("io.elementary.shortcut-overlay");
        if (cheatsheet_path != null) {
            overlay_key_combo.append_text (_("Shortcut Overlay"));
        }

        size_group[1].add_widget (overlay_key_combo);

        // Caps Lock key functionality
        modifier = new XkbModifier ();
        modifier.append_xkb_option ("", _("Default"));
        modifier.append_xkb_option ("caps:none", _("Disabled"));
        modifier.append_xkb_option ("caps:backspace", _("as Backspace"));
        modifier.append_xkb_option ("ctrl:nocaps", _("as Ctrl"));
        modifier.append_xkb_option ("caps:escape", _("as Escape"));
        modifier.append_xkb_option ("caps:numlock", _("as Num Lock"));
        modifier.append_xkb_option ("caps:super", _("as ⌘"));
        modifier.append_xkb_option ("ctrl:swapcaps", _("Swap with Ctrl"));
        modifier.append_xkb_option ("caps:swapescape", _("Swap with Escape"));

        modifier.set_default_command ("");
        settings.add_xkb_modifier (modifier);

        var caps_lock_combo = create_xkb_combobox (modifier);

        var caps_lock_label = create_settings_label (
            _("Caps Lock behavior:"),
            caps_lock_combo
        );

        var per_window_switch = new Gtk.Switch () {
            halign = START,
            valign = CENTER,
            action_name = "layout-settings.per-window"
        };

        var per_window_label = create_settings_label (
            _("Different layout per window:"),
            per_window_switch
        );

        stack = new Gtk.Stack () {
            hexpand = true,
            vhomogeneous = false
        };

        var blank_panel = new Gtk.Box (VERTICAL, 0);
        stack.add_named (blank_panel, "none");
        blank_panel.show ();

        panels = {
            fifth_level_layouts_panel (),
            japanese_layouts_panel (),
            korean_layouts_panel (),
            third_level_layouts_panel ()
        };

        panel_for_layout = new HashTable <string, string> (str_hash, str_equal);

        foreach (unowned var panel in panels) {
            stack.add_named (panel, panel.panel_name);
            foreach (string layout_name in panel.input_sources) {
                // currently we only want *one* panel per input-source
                panel_for_layout.insert (layout_name, panel.panel_name);
            }
        }

        entry_test = new Gtk.Entry () {
            vexpand = true,
            valign = END
        };

        update_entry_test_usable ();

        column_homogeneous = true;
        column_spacing = 12;
        row_spacing = 12;
        margin_start = 12;
        margin_end = 12;
        margin_bottom = 12;
        margin_top = 12;
        attach (display, 0, 0, 1, 12);
        attach (switch_layout_label, 1, 0);
        attach (switch_layout_combo, 2, 0);
        attach (compose_key_label, 1, 1);
        attach (compose_key_combo, 2, 1);
        attach (overlay_key_label, 1, 2);
        attach (overlay_key_combo, 2, 2);
        attach (caps_lock_label, 1, 3);
        attach (caps_lock_combo, 2, 3);
        attach (per_window_label, 1, 4);
        attach (per_window_switch, 2, 4);
        attach (stack, 1, 5, 2);
        attach (entry_test, 1, 11, 2);

        // Cannot be just called from the constructor because the stack switcher
        // shows every child after the constructor has been called
        map.connect (() => {
            show_panel_for_active_layout ();
        });

        settings.notify["active-index"].connect (() => {
            update_entry_test_usable ();
            show_panel_for_active_layout ();
        });

        var gala_behavior_settings = new GLib.Settings ("io.elementary.desktop.wm.behavior");

        var overlay_string = gala_behavior_settings.get_string ("overlay-action");

        switch (overlay_string) {
            case "":
                overlay_key_combo.active = 0;
                break;
            case "io.elementary.wingpanel --toggle-indicator=app-launcher":
                overlay_key_combo.active = 1;
                break;
            case MULTITASKING_VIEW_COMMAND:
                overlay_key_combo.active = 2;
                break;
            case "io.elementary.shortcut-overlay":
                overlay_key_combo.active = 3;
                break;
        }

        overlay_key_combo.changed.connect (() => {
            var combo_active = overlay_key_combo.active;

            if (combo_active == 0) {
                gala_behavior_settings.set_string ("overlay-action", "");
            } else if (combo_active == 1) {
                gala_behavior_settings.set_string ("overlay-action", "io.elementary.wingpanel --toggle-indicator=app-launcher");
            } else if (combo_active == 2) {
                gala_behavior_settings.set_string ("overlay-action", MULTITASKING_VIEW_COMMAND);
            } else if (combo_active == 3) {
                gala_behavior_settings.set_string ("overlay-action", "io.elementary.shortcut-overlay");
            }
        });

        input_sources_settings = new GLib.Settings ("org.gnome.desktop.input-sources");
        var per_window_action = new SimpleAction.stateful (
            "per-window",
            null,
            new Variant.boolean (input_sources_settings.get_boolean ("per-window"))
        );
        var action_group = new SimpleActionGroup ();
        action_group.add_action (per_window_action);
        insert_action_group ("layout-settings", action_group);

        per_window_action.change_state.connect ((value) => {
            if (!per_window_action.get_state ().equal (value)) {
                per_window_action.set_state (value);
                input_sources_settings.set_boolean ("per-window", value.get_boolean ());
            }
        });

    }

    private AdvancedSettingsPanel? third_level_layouts_panel () {
        var modifier = settings.get_xkb_modifier_by_name ("third_level_key");

        if (modifier == null) {
            return null;
        }

        string [] invalid_input_sources = {
            "am*", "ara*", "az+cyrillic",
           "bg*", "by", "by+legacy",
           "ca+eng", "ca+ike", "cm", "cn*", "cz+ucw",
           "fr+dvorak",
           "ge+os", "ge+ru", "gr+nodeadkeys", "gr+simple",
           "ie+ogam", "il*", "in+ben_gitanjali", "in+ben_inscript", "in+tam_keyboard_with_numerals",
           "in+tam_TAB", "in+tam_TSCII", "in+tam_unicode", "iq",
           "jp*",
           "kg*", "kz*",
           "la*", "lk+tam_TAB", "lk+tam_unicode",
           "mk*", "mv*",
           "no+mac", "no+mac_nodeadkeys", "np*",
           "pk+ara",
           "ru", "ru+dos", "ru+legacy", "ru+mac", "ru+os_legacy", "ru+os_winkeys",
           "ru+phonetic", "ru+phonetic_winkeys", "ru+typewriter", "ru+typewriter-legacy",
           "sy", "sy+syc", "sy+syc_phonetic",
           "th*", "tz*",
           "ua+homophonic", "ua+legacy", "ua+phonetic", "ua+rstu", "ua+rstu_ru",
           "ua+typewriter", "ua+winkeys", "us", "us+chr", "us+dvorak", "us+dvorak-classic",
           "us+dvorak-l", "us+dvorak-r", "uz*"
        };

        var third_level_combo = create_xkb_combobox (modifier);

        var third_level_label = create_settings_label (
            _("Key to choose 3rd level:"),
            third_level_combo
        );

        var panel = new AdvancedSettingsPanel ("third_level_layouts", {}, invalid_input_sources);
        panel.attach (third_level_label, 0, 0);
        panel.attach (third_level_combo, 1, 0);

        return panel;
    }

    private AdvancedSettingsPanel fifth_level_layouts_panel () {
        var modifier = new XkbModifier ("third_level_key");
        modifier.append_xkb_option ("", _("Default"));
        modifier.append_xkb_option ("lv3:caps_switch", _("Caps Lock"));
        modifier.append_xkb_option ("lv3:lalt_switch", _("Left Alt"));
        modifier.append_xkb_option ("lv3:ralt_switch", _("Right Alt"));
        modifier.append_xkb_option ("lv3:switch", _("Right Ctrl"));
        modifier.append_xkb_option ("lv3:rwin", _("Right ⌘"));

        modifier.set_default_command ("");
        settings.add_xkb_modifier (modifier);

        var third_level_combo = create_xkb_combobox (modifier);

        var third_level_label = create_settings_label (
            _("Key to choose 3rd level:"),
            third_level_combo
        );

        modifier = new XkbModifier ();
        modifier.append_xkb_option ("lv5:ralt_switch_lock", _("Right Alt"));
        modifier.append_xkb_option ("", _("Right Ctrl"));
        modifier.append_xkb_option ("lv5:rwin_switch_lock", _("Right ⌘"));
        modifier.set_default_command ("");
        settings.add_xkb_modifier (modifier);

        var fifth_level_combo = create_xkb_combobox (modifier);

        var fifth_level_label = create_settings_label (
            _("Key to choose 5th level:"),
            fifth_level_combo
        );

        var panel = new AdvancedSettingsPanel ("fifth_level_layouts", {"ca+multix"});
        panel.attach (third_level_label, 0, 0);
        panel.attach (third_level_combo, 1, 0);
        panel.attach (fifth_level_label, 0, 1);
        panel.attach (fifth_level_combo, 1, 1);

        return panel;
    }

    private AdvancedSettingsPanel japanese_layouts_panel () {
        var kana_lock_switch = create_xkb_option_switch (settings, "japan:kana_lock");

        var kana_lock_label = create_settings_label (
            _("Kana Lock:"),
            kana_lock_switch
        );

        var nicola_backspace_switch = create_xkb_option_switch (settings, "japan:nicola_f_bs");

        var nicola_backspace_label = create_settings_label (
            _("Nicola F Backspace:"),
            nicola_backspace_switch
        );

        var zenkaku_switch = create_xkb_option_switch (settings, "japan:hztg_escape");

        var zenkaku_label = create_settings_label (
            _("Hankaku Zenkaku as Escape:"),
            zenkaku_switch
        );

        var panel = new AdvancedSettingsPanel ("japanese_layouts", {"jp"});
        panel.attach (kana_lock_label, 0, 0);
        panel.attach (kana_lock_switch, 1, 0);
        panel.attach (nicola_backspace_label, 0, 1);
        panel.attach (nicola_backspace_switch, 1, 1);
        panel.attach (zenkaku_label, 0, 2);
        panel.attach (zenkaku_switch, 1, 2);

        return panel;
    }

    private AdvancedSettingsPanel korean_layouts_panel () {
        var hangul_switch = create_xkb_option_switch (settings, "korean:ralt_rctrl");

        var hangul_label = create_settings_label (
            _("Hangul/Hanja keys on Right Alt/Ctrl:"),
            hangul_switch
        );

        var panel = new AdvancedSettingsPanel ("korean_layouts", {"kr"});
        panel.attach (hangul_label, 0, 0);
        panel.attach (hangul_switch, 1, 0);

        return panel;
    }

    private void show_panel_for_active_layout () {
        var active_layout = settings.active_input_source;
        if (active_layout != null) {
            set_visible_panel_from_layout (active_layout.name);
        } else {
            set_visible_panel_from_layout (null);
        }
    }

    private Gtk.ComboBoxText create_xkb_combobox (XkbModifier modifier) {
        var combo_box = new Gtk.ComboBoxText () {
            halign = START,
            valign = CENTER
        };

        size_group[1].add_widget (combo_box);

        for (int i = 0; i < modifier.xkb_option_commands.length; i++) {
            combo_box.append (modifier.xkb_option_commands[i], modifier.option_descriptions[i]);
        }

        combo_box.set_active_id (modifier.get_active_command ());

        combo_box.changed.connect (() => {
            modifier.update_active_command (combo_box.active_id);
        });

        modifier.active_command_updated.connect (() => {
            combo_box.set_active_id (modifier.get_active_command ());
        });

        return combo_box;
    }

    private Gtk.Switch create_xkb_option_switch (SourceSettings settings, string xkb_command) {
        var option_switch = new Gtk.Switch () {
            halign = START,
            valign = START
        };

        var modifier = new XkbModifier ("" + xkb_command);
        modifier.append_xkb_option ("", "option off");
        modifier.append_xkb_option (xkb_command, "option on");

        settings.add_xkb_modifier (modifier);

        if (modifier.get_active_command () == "") {
            option_switch.active = false;
        } else {
            option_switch.active = true;
        }

        option_switch.notify["active"].connect (() => {
            if (option_switch.active) {
                modifier.update_active_command (xkb_command);
            } else {
                modifier.update_active_command ("");
            }
        });

        return option_switch;
    }

    private void update_entry_test_usable () {
        if (settings.active_input_source != null &&
            settings.active_input_source.layout_type == LayoutType.XKB) {

            entry_test.placeholder_text = _("Type to test your layout");
            entry_test.sensitive = true;
        } else {
            entry_test.placeholder_text = _("Input Method is active");
            entry_test.sensitive = false;
        }
    }

    private Gtk.Label create_settings_label (string label, Gtk.Widget mnemonic_widget) {
        var settings_label = new Gtk.Label (label) {
            mnemonic_widget = mnemonic_widget,
            xalign = 1
        };

        size_group[0].add_widget (settings_label);

        return settings_label;
    }

    private void set_visible_panel_from_layout (string? layout_name) {
        string panel_name = "none";
        string[] split_name = {};
        if (layout_name != null) {
            if (!panel_for_layout.lookup_extended (layout_name, null, out panel_name)) {
                panel_name = "";
            }
            split_name = layout_name.split ("+");

            if (panel_name == "" && "+" in layout_name) {
                // if layout_name was not found we look for the layout without variant
                if (!panel_for_layout.lookup_extended (split_name[0], null, out panel_name)) {
                    panel_name = "";
                }
            }
        }

        if (panel_name == "") {
            foreach (unowned var panel in panels) {
                if (panel == null || panel.exclusions.length == 0) {
                    continue;
                }

                if (!(split_name[0] + "*" in panel.exclusions || layout_name in panel.exclusions)) {
                    panel_name = panel.panel_name;
                    break;
                }
            }
        }

        if (panel_name == "") {
            // this.hide() cannot be used because it messes the alignment
            stack.set_visible_child_name ("none");
            return;
        } else {
            stack.set_visible_child_name (panel_name);
        }
    }
}
