/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

namespace Keyboard.Shortcuts.Utils {
    public GLib.Icon? get_action_icon (GLib.DesktopAppInfo app_info, string action) {
        unowned var icon_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());

        GLib.Icon? action_icon = null;
        try {
            var keyfile = new GLib.KeyFile ();
            keyfile.load_from_file (app_info.get_filename (), GLib.KeyFileFlags.NONE);

            var group = "Desktop Action %s".printf (action);
            if (keyfile.has_key (group, GLib.KeyFileDesktop.KEY_ICON)) {
                var icon_name = keyfile.get_string (group, GLib.KeyFileDesktop.KEY_ICON);

                if (icon_theme.has_icon (icon_name)) {
                    action_icon = new ThemedIcon (icon_name);
                }
            }
        } catch (Error e) {
            warning (e.message);
        }

        return action_icon;
    }
}
