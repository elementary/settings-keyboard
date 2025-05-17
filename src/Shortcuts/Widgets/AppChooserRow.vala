/* SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class Keyboard.AppChooserRow : Gtk.Grid {
    public signal void deleted ();

    public AppInfo app_info { get; construct; }

    public AppChooserRow (AppInfo app_info) {
        Object (app_info: app_info);
    }

    construct {
        var image = new Gtk.Image () {
            pixel_size = 32
        };

        var icon_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        if (icon_theme.has_icon (app_info.icon)) {
            image.gicon = new ThemedIcon (app_info.icon);
        } else {
            image.gicon = new ThemedIcon ("application-default-icon");
        }

        var app_name = new Gtk.Label (app_info.name) {
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END
        };

        var app_comment = new Gtk.Label (app_info.comment) {
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END
        };
        app_comment.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        column_spacing = 6;
        attach (image, 0, 0, 1, 2);
        attach (app_name, 1, 0);
        attach (app_comment, 1, 1);
    }
}
