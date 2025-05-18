/*
* Copyright (c) 2017 elementary, LLC. (https://elementary.io)
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

// stores a shortcut, converts to gsettings format and readable format
// and checks for validity
public class Keyboard.Shortcuts.Shortcut : GLib.Object {
    public Gdk.ModifierType modifiers { get; construct; }
    public uint accel_key { get; construct; }

    private const string SEPARATOR = " + ";

    public Shortcut (uint key = 0, Gdk.ModifierType mod = (Gdk.ModifierType) 0) {
        Object (
            accel_key: (uint) (((char) key).to_string ().ascii_down ()[0]),
            modifiers: mod
        );
    }

    public Shortcut.parse (string? str) {
        uint key = 0;
        Gdk.ModifierType mod = (Gdk.ModifierType) 0;
        if (str != null) {
            Gtk.accelerator_parse (str, out key, out mod);
        }

        this (key, mod);
    }

    // converters
    public string to_gsettings () {
        if (!valid ()) {
            return "";
        }
        return Gtk.accelerator_name (accel_key, modifiers);
    }

    public string to_readable () {
        if (!valid ()) {
            return _("Disabled");
        }

        string tmp = "";

        if ((modifiers & Gdk.ModifierType.SHIFT_MASK) > 0) {
            tmp += _("Shift") + SEPARATOR;
        }

        if ((modifiers & Gdk.ModifierType.SUPER_MASK) > 0) {
            tmp += "⌘" + SEPARATOR;
        }

        if ((modifiers & Gdk.ModifierType.CONTROL_MASK) > 0) {
            tmp += _("Ctrl") + SEPARATOR;
        }

        if ((modifiers & Gdk.ModifierType.ALT_MASK) > 0) {
            tmp += _("Alt") + SEPARATOR;
        }

        if ((modifiers & Gdk.ModifierType.META_MASK) > 0) {
            tmp += _("Meta") + SEPARATOR;
        }

        switch (accel_key) {
            case Gdk.Key.Up:
                tmp += "↑";
                break;
            case Gdk.Key.Down:
                tmp += "↓";
                break;
            case Gdk.Key.Left:
                tmp += "←";
                break;
            case Gdk.Key.Right:
                tmp += "→";
                break;
            default:
                tmp += Gtk.accelerator_get_label (accel_key, 0);
                break;
        }

        return tmp;
    }

    public bool is_equal (Shortcut shortcut) {
        return shortcut.modifiers == modifiers && shortcut.accel_key == accel_key;
    }

    // validator
    private bool valid () {
        if (accel_key == 0) {
            return false;
        }

        if (modifiers == (Gdk.ModifierType) 0 || modifiers == Gdk.ModifierType.SHIFT_MASK) {
            if ((accel_key >= Gdk.Key.a && accel_key <= Gdk.Key.z)
            || (accel_key >= Gdk.Key.A && accel_key <= Gdk.Key.Z)
            || (accel_key >= Gdk.Key.@0 && accel_key <= Gdk.Key.@9)
            || (accel_key >= Gdk.Key.kana_fullstop && accel_key <= Gdk.Key.semivoicedsound)
            || (accel_key >= Gdk.Key.Arabic_comma && accel_key <= Gdk.Key.Arabic_sukun)
            || (accel_key >= Gdk.Key.Serbian_dje && accel_key <= Gdk.Key.Cyrillic_HARDSIGN)
            || (accel_key >= Gdk.Key.Greek_ALPHAaccent && accel_key <= Gdk.Key.Greek_omega)
            || (accel_key >= Gdk.Key.hebrew_doublelowline && accel_key <= Gdk.Key.hebrew_taf)
            || (accel_key >= Gdk.Key.Thai_kokai && accel_key <= Gdk.Key.Thai_lekkao)
            || (accel_key >= Gdk.Key.Hangul && accel_key <= Gdk.Key.Hangul_Special)
            || (accel_key >= Gdk.Key.Hangul_Kiyeog && accel_key <= Gdk.Key.Hangul_J_YeorinHieuh)
            || (accel_key == Gdk.Key.Left)
            || (accel_key == Gdk.Key.Up)
            || (accel_key == Gdk.Key.Right)
            || (accel_key == Gdk.Key.Down)
            || (accel_key == Gdk.Key.Tab)
            || (accel_key == Gdk.Key.KP_Enter)
            || (accel_key == Gdk.Key.Return)) {
               return false;
           }
        }

        if (modifiers == (Gdk.ModifierType) 0) {
            if ((accel_key == Gdk.Key.backslash)
            || (accel_key == Gdk.Key.bracketright)
            || (accel_key == Gdk.Key.bracketleft)
            || (accel_key == Gdk.Key.apostrophe)
            || (accel_key == Gdk.Key.semicolon)
            || (accel_key == Gdk.Key.slash)
            || (accel_key == Gdk.Key.period)
            || (accel_key == Gdk.Key.comma)
            || (accel_key == Gdk.Key.space)
            || (accel_key == Gdk.Key.grave)) {
               return false;
           }
        }

        return true;
    }
}
