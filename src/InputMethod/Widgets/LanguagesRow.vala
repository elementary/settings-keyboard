/*
* 2019-2020 elementary, Inc. (https://elementary.io)
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

public class Keyboard.InputMethodPage.LanguagesRow : Gtk.ListBoxRow {
    public InstallList language { get; construct; }

    public LanguagesRow (InstallList language) {
        Object (language: language);
    }

    construct {
        var label = new Gtk.Label (language.get_name ()) {
            halign = Gtk.Align.START,
            hexpand = true
        };

        var caret = new Gtk.Image.from_icon_name ("pan-end-symbolic");

        var box = new Gtk.Box (HORIZONTAL, 0) {
            margin_top = 3,
            margin_start = 6,
            margin_bottom = 3,
            margin_end = 6
        };
        box.append (label);
        box.append (caret);

        child = box;
    }
}
