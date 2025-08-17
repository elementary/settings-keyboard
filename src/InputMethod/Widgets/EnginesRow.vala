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

public class Keyboard.InputMethodPage.EnginesRow : Gtk.ListBoxRow {
    public bool selected { get; set; }
    public string engine_name { get; construct; }

    public EnginesRow (string engine_name) {
        Object (
            engine_name: engine_name
        );
    }

    construct {
        var label = new Gtk.Label (engine_name) {
            halign = Gtk.Align.START,
            hexpand = true
        };

        var selection_icon = new Gtk.Image.from_icon_name ("object-select-symbolic") {
            visible = false
        };

        var box = new Gtk.Box (HORIZONTAL, 6) {
            margin_top = 3,
            margin_start = 6,
            margin_bottom = 3,
            margin_end = 6
        };
        box.append (label);
        box.append (selection_icon);

        child = box;

        notify["selected"].connect (() => {
            selection_icon.visible = selected;
        });
    }
}
