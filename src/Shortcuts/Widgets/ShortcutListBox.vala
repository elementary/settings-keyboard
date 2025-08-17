/*
* Copyright 2022 elementary, Inc. (https://elementary.io)
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

private class Keyboard.Shortcuts.ShortcutListBox : Gtk.Box {
    public SectionID group { get; construct; }

    private string[] actions;
    private Schema[] schemas;
    private string[] keys;

    public ShortcutListBox (SectionID group) {
        Object (group: group);
    }

    construct {
        ShortcutsList.get_default ().get_group (group, out actions, out schemas, out keys);

        var list_box = new Gtk.ListBox () {
            hexpand = true
        };

        var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.VERTICAL);

        for (int i = 0; i < actions.length; i++) {
            if (Settings.get_default ().valid (schemas[i], keys[i])) {
                var row = new ShortcutRow (actions[i], schemas[i], keys[i]);
                list_box.append (row);

                sizegroup.add_widget (row);
            }
        }

        append (list_box);
    }

    private class ShortcutRow : Gtk.ListBoxRow {
        public string action { get; construct; }
        public Schema schema { get; construct; }
        public string gsettings_key { get; construct; }

        private Gtk.Button clear_button;
        private Gtk.Button reset_button;
        private Gtk.Box keycap_box;
        private Gtk.Label status_label;
        private Gtk.Stack keycap_stack;
        private bool is_editing_shortcut = false;
        private Gdk.Device? keyboard_device = null;

        public ShortcutRow (string action, Schema schema, string gsettings_key) {
            Object (
                action: action,
                schema: schema,
                gsettings_key: gsettings_key
            );
        }

        construct {
            var display = Gdk.Display.get_default ();
            if (display != null) {
                var seat = display.get_default_seat ();
                if (seat != null) {
                    keyboard_device = seat.get_keyboard ();
                }
            }
            var label = new Gtk.Label (action) {
                halign = Gtk.Align.START,
                hexpand = true
            };

            status_label = new Gtk.Label (_("Disabled")) {
                halign = Gtk.Align.END
            };
            status_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            keycap_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.END
            };

            keycap_stack = new Gtk.Stack () {
                transition_type = Gtk.StackTransitionType.CROSSFADE
            };
            keycap_stack.add_child (keycap_box);
            keycap_stack.add_child (status_label);

            var set_accel_button = new Gtk.Button () {
                child = new Gtk.Label (_("Set New Shortcut")) { halign = START }
            };
            set_accel_button.add_css_class (Granite.STYLE_CLASS_MENUITEM);

            reset_button = new Gtk.Button () {
                child = new Gtk.Label (_("Reset to Default")) { halign = START }
            };
            reset_button.add_css_class (Granite.STYLE_CLASS_MENUITEM);

            clear_button = new Gtk.Button () {
                child = new Gtk.Label (_("Disable")) { halign = START }
            };
            clear_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
            clear_button.add_css_class (Granite.STYLE_CLASS_MENUITEM);

            var action_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            action_box.append (set_accel_button);
            action_box.append (reset_button);
            action_box.append (clear_button);

            var popover = new Gtk.Popover () {
                child = action_box
            };
            popover.add_css_class (Granite.STYLE_CLASS_MENU);

            var menubutton = new Gtk.MenuButton () {
                has_frame = false,
                icon_name = "open-menu-symbolic",
                popover = popover,
            };

            var box = new Gtk.Box (HORIZONTAL, 12) {
                margin_top = 3,
                margin_end = 12, // Allow space for scrollbar to expand
                margin_bottom = 3,
                margin_start = 6,
                valign = Gtk.Align.CENTER
            };
            box.append (label);
            box.append (keycap_stack);
            box.append (menubutton);

            child = box;

            render_keycaps ();

            unowned var settings = Shortcuts.Settings.get_default ();

            settings.schemas[schema].changed[gsettings_key].connect (render_keycaps);

            clear_button.clicked.connect (() => {
                popover.popdown ();
                var key_value = settings.schemas[schema].get_value (gsettings_key);
                if (key_value.is_of_type (VariantType.ARRAY)) {
                    settings.schemas[schema].set_strv (gsettings_key, {""});
                } else {
                    settings.schemas[schema].set_string (gsettings_key, "");
                }
            });

            reset_button.clicked.connect (() => {
                popover.popdown ();
                settings.schemas[schema].reset (gsettings_key);
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

            var key_controller = new Gtk.EventControllerKey ();
            key_controller.key_released.connect (on_key_released);

            add_controller (key_controller);
        }

        private void edit_shortcut (bool start_editing) {
            //Ensure device grabs are paired
            if (start_editing && !is_editing_shortcut) {
                ((Gdk.Toplevel) get_root ().get_surface ()).inhibit_system_shortcuts (null);

                keycap_stack.visible_child = status_label;
                status_label.label = _("Enter new shortcut…");

                ((Gtk.ListBox)parent).select_row (this);
                grab_focus ();

                var focus_controller = new Gtk.EventControllerFocus ();
                focus_controller.leave.connect (() => {
                    focus_controller.dispose ();
                    edit_shortcut (false);
                });

                add_controller (focus_controller);
            } else if (!start_editing && is_editing_shortcut) {
                ((Gdk.Toplevel) get_root ().get_surface ()).restore_system_shortcuts ();
                render_keycaps ();
            }

            is_editing_shortcut = start_editing;
        }

        private void on_key_released (Gtk.EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType state) {
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
                    case Gdk.Key.Tools:
                        // Accept certain keys as single key accelerators
                        var shortcut = new Keyboard.Shortcuts.Shortcut (keyval, mods);
                        update_binding (shortcut);
                        break;
                    default:
                        return;
                }
            }

            edit_shortcut (false);
            render_keycaps ();

            return;
        }

        private void update_binding (Shortcut shortcut) {
            string conflict_name = "";
            string group = "";
            if (ConflictsManager.shortcut_conflicts (shortcut, out conflict_name, out group)) {

                var message_dialog = new Granite.MessageDialog (
                    _("Unable to set new shortcut due to conflicts"),
                    _("“%s” is already used for “%s → %s”.").printf (
                        shortcut.to_readable (), group, conflict_name
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
            } else {
                unowned var settings = Settings.get_default ();
                var key_value = settings.schemas[schema].get_value (gsettings_key);
                if (key_value.is_of_type (VariantType.ARRAY)) {
                    settings.schemas[schema].set_strv (gsettings_key, {shortcut.to_gsettings ()});
                } else {
                    settings.schemas[schema].set_string (gsettings_key, shortcut.to_gsettings ());
                }
            }
        }

        private void render_keycaps () {
            unowned var settings = Settings.get_default ();
            var key_value = settings.schemas[schema].get_value (gsettings_key);

            string[] accels = {""};
            if (key_value.is_of_type (VariantType.ARRAY)) {
                var key_value_strv = key_value.get_strv ();
                if (key_value_strv.length > 0 && key_value_strv[0] != "") {
                    var accels_string = Granite.accel_to_string (key_value_strv[0]);
                    if (accels_string != null) {
                        accels = accels_string.split (" + ");
                    }
                }
            } else {
                var value_string = key_value.dup_string ();
                if (value_string != "") {
                    var accels_string = Granite.accel_to_string (value_string);
                    if (accels_string != null) {
                        accels = accels_string.split (" + ");
                    }
                }
            }

            if (accels[0] != "") {
                while (keycap_box.get_first_child () != null) {
                    keycap_box.remove (keycap_box.get_first_child ());
                }

                foreach (unowned string accel in accels) {
                    if (accel == "") {
                        continue;
                    }
                    var keycap_label = new Gtk.Label (accel);
                    keycap_label.add_css_class ("keycap");
                    keycap_box.append (keycap_label);
                }

                clear_button.sensitive = true;
                keycap_stack.visible_child = keycap_box;
            } else {
                clear_button.sensitive = false;
                keycap_stack.visible_child = status_label;
                status_label.label = _("Disabled");
            }

            if (settings.schemas[schema].get_user_value (gsettings_key) == null) {
                reset_button.sensitive = false;
            } else {
                reset_button.sensitive = true;
            }
        }
    }
}
