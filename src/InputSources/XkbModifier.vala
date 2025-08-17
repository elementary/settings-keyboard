/*
* Copyright 2017-2020 elementary, Inc. (https://elementary.io)
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

class Keyboard.XkbModifier : Object {
    public signal void active_command_updated ();

    public string gsettings_key { get; construct; }
    public string gsettings_schema { get; construct; }
    public string name { get; construct; }

    public string [] option_descriptions;
    public string [] xkb_option_commands;

    private GLib.Settings settings;
    private string active_command;
    private string default_command = "";

    public XkbModifier (string name = "",
                        string schem = "org.gnome.desktop.input-sources",
                        string key = "xkb-options") {
        Object (
            name: name,
            gsettings_schema: schem,
            gsettings_key: key
        );
    }

    construct {
        settings = new GLib.Settings (gsettings_schema);
        settings.changed[gsettings_key].connect (update_from_gsettings);
    }

    public string get_active_command () {
        if ( active_command == null ) {
            return default_command;
        } else {
            return active_command;
        }
    }

    public void update_from_gsettings () {
        string [] xkb_options = settings.get_strv (this.gsettings_key);
        bool found = false;
        foreach (string xkb_command in this.xkb_option_commands) {
            bool command_is_valid = true;
            if (xkb_command != "") {
                var com_arr = xkb_command.split (",", 4);
                foreach (string opt in com_arr) {
                    if (!(opt in xkb_options)) {
                        command_is_valid = false;
                    }
                }
                if (command_is_valid) {
                    update_active_command (xkb_command);
                    found = true;
                    break;
                }
            }
        }
        if (!found) {
            update_active_command (default_command);
        }
    }

    public void update_active_command ( string val ) {
        if (!(val in xkb_option_commands) || val == active_command) {
            return;
        }

        string old_opt = get_active_command ();
        if (val != active_command && val in xkb_option_commands) {
            active_command = val;
        }

        string [] new_xkb_options = {};
        string [] old_xkb_options = settings.get_strv (gsettings_key);
        var old_arr = old_opt.split (",", 4);
        var new_arr = val.split (",", 4);

        foreach (string xkb_command in old_xkb_options) {
            if (!(xkb_command in old_arr) || (xkb_command in new_arr)) {
                new_xkb_options += xkb_command;
            }
        }

        foreach (string xkb_command in new_arr) {
            if (!(xkb_command in new_xkb_options)) {
                new_xkb_options += xkb_command;
            }
        }

        settings.changed[gsettings_key].disconnect (update_from_gsettings);
        settings.set_strv (gsettings_key, new_xkb_options);
        settings.changed[gsettings_key].connect (update_from_gsettings);

        active_command_updated ();
    }

    public void set_default_command ( string val ) {
        if ( val in xkb_option_commands ) {
            default_command = val;
        } else {
            return;
        }
    }

    public void append_xkb_option (string xkb_command, string description) {
        xkb_option_commands += xkb_command;
        option_descriptions += description;
    }
}
