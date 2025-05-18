/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

private class Keyboard.Shortcuts.CustomShortcutRow : Gtk.ListBoxRow {
    public signal void shortcut_changed ();

    public CustomShortcuts.ParsedShortcut? shortcut { get; construct set; }

    private Gtk.Button clear_button;
    private Gtk.Box keycap_box;
    private Gtk.Label status_label;
    private Gtk.Stack keycap_stack;

    private bool is_editing_shortcut = false;

    public CustomShortcutRow (CustomShortcuts.ParsedShortcut shortcut) {
        Object (shortcut: shortcut);
    }

    construct {
        GLib.Icon icon;
        string name, description;
        if (shortcut.type == DESKTOP_FILE) {
            var desktop_file = new DesktopAppInfo (shortcut.target);
            icon = desktop_file.get_icon () ?? new ThemedIcon ("application-default-icon");
            name = desktop_file.get_name ();
            description = (
                "action" in shortcut.parameters ?
                desktop_file.get_action_name (shortcut.parameters["action"].get_string ()) :
                desktop_file.get_description ()
            );
        } else {
            icon = new ThemedIcon ("application-default-icon");
            name = _("Custom Command");
            description = shortcut.target;
        }

        var image = new Gtk.Image () {
            pixel_size = 32,
            gicon = icon
        };

        var app_name = new Gtk.Label (name) {
            xalign = 0
        };

        var app_comment = new Gtk.Label (description) {
            ellipsize = Pango.EllipsizeMode.END,
            hexpand = true,
            xalign = 0
        };
        app_comment.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var app_grid = new Gtk.Grid () {
            column_spacing = 6,
            hexpand = true
        };
        app_grid.attach (image, 0, 0, 1, 2);
        app_grid.attach (app_name, 1, 0);
        app_grid.attach (app_comment, 1, 1);

        status_label = new Gtk.Label (_("Disabled")) {
            halign = END
        };
        status_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        keycap_box = new Gtk.Box (HORIZONTAL, 6) {
            valign = CENTER,
            halign = END
        };

        // We create a dummy grid representing a long four key accelerator to force the stack in each row to the same size
        // This seems a bit hacky but it is hard to find a solution across rows not involving a hard-coded width value
        // (which would not take into account internationalization). This grid is never shown but controls the size of
        // of the homogeneous stack.
        var four_key_box = new Gtk.Box (HORIZONTAL, 6) { // must have same format as keycap_box
            valign = CENTER,
            halign = END
        };

        build_keycap_box ("<Shift><Alt><Control>F10", ref four_key_box);

        keycap_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            vhomogeneous = true
        };
        keycap_stack.add_child (four_key_box); // This ensures sufficient space is allocated for longest reasonable shortcut
        keycap_stack.add_child (keycap_box);
        keycap_stack.add_child (status_label); // This becomes initial visible child

        var set_accel_button = new Gtk.Button () {
            child = new Gtk.Label (_("Set New Shortcut")) { halign = START }
        };
        set_accel_button.add_css_class (Granite.STYLE_CLASS_MENUITEM);

        clear_button = new Gtk.Button () {
            child = new Gtk.Label (_("Disable")) { halign = START }
        };
        clear_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
        clear_button.add_css_class (Granite.STYLE_CLASS_MENUITEM);

        var remove_button = new Gtk.Button () {
            child = new Gtk.Label (_("Remove")) { halign = START }
        };
        remove_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
        remove_button.add_css_class (Granite.STYLE_CLASS_MENUITEM);

        var action_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        action_box.append (set_accel_button);
        action_box.append (clear_button);
        action_box.append (remove_button);

        var popover = new Gtk.Popover () {
            child = action_box
        };
        popover.add_css_class (Granite.STYLE_CLASS_MENU);

        var menubutton = new Gtk.MenuButton () {
            has_frame = false,
            valign = CENTER,
            icon_name = "open-menu-symbolic",
            popover = popover
        };

        var box = new Gtk.Box (HORIZONTAL, 12) {
            margin_top = 3,
            margin_end = 12, // Allow space for scrollbar to expand
            margin_bottom = 3,
            margin_start = 6,
            valign = CENTER
        };
        box.append (app_grid);
        box.append (keycap_stack);
        box.append (menubutton);

        child = box;

        render_keycaps ();

        clear_button.clicked.connect (() => {
            popover.popdown ();
            if (!is_editing_shortcut) {
                shortcut.keybindings = {};
                render_keycaps ();
                shortcut_changed ();
            }
        });

        remove_button.clicked.connect (() => {
            popover.popdown ();
            shortcut = null;
            shortcut_changed ();
            unparent ();
        });

        set_accel_button.clicked.connect (() => {
            popover.popdown ();
            edit_shortcut (true);
        });

        var keycap_controller = new Gtk.GestureClick ();
        keycap_stack.add_controller (keycap_controller);
        keycap_controller.released.connect (() => {
            edit_shortcut (true);
        });

        var status_controller = new Gtk.GestureClick ();
        status_label.add_controller (status_controller);
        status_controller.released.connect (() => {
            edit_shortcut (true);
        });

        var key_controller = new Gtk.EventControllerKey ();
        key_controller.key_released.connect (on_key_released);
        add_controller (key_controller);

        var focus_controller = new Gtk.EventControllerFocus ();
        focus_controller.leave.connect (() => {
            edit_shortcut (false);
        });
        add_controller (focus_controller);
    }

    private void edit_shortcut (bool start_editing) {
        //Ensure device grabs are paired
        if (start_editing && !is_editing_shortcut) {
            ((Gdk.Toplevel) get_root ().get_surface ()).inhibit_system_shortcuts (null);

            keycap_stack.visible_child = status_label;
            status_label.label = _("Enter new shortcut…");
            ((Gtk.ListBox) parent).select_row (this);
            grab_focus ();
        } else if (!start_editing && is_editing_shortcut) {
            ((Gdk.Toplevel) get_root ().get_surface ()).restore_system_shortcuts ();
            render_keycaps ();
        }

        is_editing_shortcut = start_editing;
    }

    private void on_key_released (Gtk.EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType state) {
        // For a custom shortcut, require modifier key(s) and one non-modifier key
        if (!is_editing_shortcut) {
            return;
        }

        var mods = state & Gtk.accelerator_get_default_mod_mask ();
        if (mods > 0) {
            var shortcut = new Keyboard.Shortcuts.Shortcut (keyval, mods);
            update_binding (shortcut);
        } else {
            switch (keyval) {
                case Gdk.Key.Escape:
                    // Cancel editing
                    break;
                // case Gdk.Key.F1: May be used for system help
                case Gdk.Key.F2:
                case Gdk.Key.F3:
                case Gdk.Key.F4:
                case Gdk.Key.F5:
                case Gdk.Key.F6:
                case Gdk.Key.F7:
                case Gdk.Key.F8:
                case Gdk.Key.F9:
                case Gdk.Key.F10:
                // case Gdk.Key.F11: Already used for fullscreen
                case Gdk.Key.F12:
                case Gdk.Key.Menu:
                case Gdk.Key.Print:
                case Gdk.Key.Mail:
                case Gdk.Key.Explorer:
                case Gdk.Key.AudioMedia:
                case Gdk.Key.WWW:
                case Gdk.Key.AudioRaiseVolume:
                case Gdk.Key.AudioLowerVolume:
                case Gdk.Key.AudioMute:
                case Gdk.Key.AudioPlay:
                case Gdk.Key.AudioPause:
                case Gdk.Key.AudioStop:
                case Gdk.Key.AudioPrev:
                case Gdk.Key.AudioNext:
                case Gdk.Key.Eject:
                    // Accept certain keys as single key accelerators
                    var shortcut = new Keyboard.Shortcuts.Shortcut (keyval, mods);
                    update_binding (shortcut);
                    break;
                default:
                    return;
            }
        }

        edit_shortcut (false);

        return ;
        }

    private void update_binding (Shortcut new_shortcut) {
        string conflict_name = "";
        string group = "";
        if (ConflictsManager.shortcut_conflicts (new_shortcut, out conflict_name, out group)) {
            var message_dialog = new Granite.MessageDialog (
                _("Unable to set new shortcut due to conflicts"),
                _("“%s” is already used for “%s → %s”.").printf (
                    new_shortcut.to_readable (), group, conflict_name
                ),
                new ThemedIcon ("preferences-desktop-keyboard"),
                Gtk.ButtonsType.CLOSE
            ) {
                badge_icon = new ThemedIcon ("dialog-error"),
                modal = true,
                transient_for = (Gtk.Window) get_root ()
            };

            message_dialog.response.connect (() => {
                message_dialog.destroy ();
            });

            message_dialog.present ();
            return;
        } else {
            shortcut.keybindings = { new_shortcut.to_gsettings () };
            shortcut_changed ();
        }
    }

    private void render_keycaps () {
        var value_string = shortcut.keybindings.length > 0 ? shortcut.keybindings[0] : "";

        if (value_string != "") {
            build_keycap_box (value_string, ref keycap_box);
            keycap_stack.visible_child = keycap_box;
            clear_button.sensitive = true;
        } else {
            clear_button.sensitive = false;
            keycap_stack.visible_child = status_label;
            status_label.label = _("Disabled");
        }
    }

    private void build_keycap_box (string value_string, ref Gtk.Box box) {
        var accels_string = Granite.accel_to_string (value_string);

        string[] accels = {};
        if (accels_string != null) {
            accels = accels_string.split (" + ");
        }

        while (box.get_first_child () != null) {
            box.remove (box.get_first_child ());
        }

        foreach (unowned string accel in accels) {
            if (accel == "") {
                continue;
            }
            var keycap_label = new Gtk.Label (accel);
            keycap_label.add_css_class ("keycap");
            box.append (keycap_label);
        }
    }
}
