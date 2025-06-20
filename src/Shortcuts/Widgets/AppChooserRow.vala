/* SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class Keyboard.Shortcuts.AppChooserRow : Gtk.Grid {
    public struct Info {
        GLib.Icon icon;
        GLib.Icon? overlay_icon;
        string? name;
        string? description;
        string? action;
        string filename;
    }

    public Info info { get; construct; }

    public AppChooserRow (Info info) {
        Object (info: info);
    }

    construct {
        var image = new Gtk.Image () {
            pixel_size = 32,
            gicon = info.icon
        };

        Gtk.Overlay? overlay = null;
        if (info.overlay_icon != null) {
            var overlay_image = new Gtk.Image () {
                pixel_size = 16,
                gicon = info.overlay_icon,
                halign = END,
                valign = END
            };

            overlay = new Gtk.Overlay () {
                child = image
            };
            overlay.add_overlay (overlay_image);
        }

        var app_name = new Gtk.Label (info.name) {
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END
        };

        var app_comment = new Gtk.Label (info.description) {
            xalign = 0,
            ellipsize = Pango.EllipsizeMode.END
        };
        app_comment.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        column_spacing = 6;
        if (overlay != null) {
            attach (overlay, 0, 0, 1, 2);
        } else {
            attach (image, 0, 0, 1, 2);
        }
        attach (app_name, 1, 0);
        attach (app_comment, 1, 1);
    }
}
