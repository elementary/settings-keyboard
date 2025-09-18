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

namespace Keyboard.Shortcuts {
    public enum Schema { WM, MUTTER, GALA, MEDIA, SOUND_INDICATOR, IBUS, DOCK, COUNT }

    // helper class for gsettings
    // note that media key are stored as strings, all others as string vectors
    class Settings : GLib.Object {
        public GLib.Settings[] schemas;

        private string[] schema_names;

        private static GLib.Once<Shortcuts.Settings> instance;
        public static unowned Shortcuts.Settings get_default () {
            return instance.once (() => {
                return new Shortcuts.Settings ();
            });
        }

        private Settings () {}

        construct {
            schema_names = {
                "org.gnome.desktop.wm.keybindings",
                "org.gnome.mutter.keybindings",
                "io.elementary.desktop.wm.keybindings",
                "org.gnome.settings-daemon.plugins.media-keys",
                "io.elementary.desktop.wingpanel.sound",
                "org.freedesktop.ibus.panel.emoji",
                "io.elementary.dock.keybindings"
            };

            foreach (var name in schema_names) {
                var schema_source = GLib.SettingsSchemaSource.get_default ();

                // check if schema exists
                var schema = schema_source.lookup (name, true);

                if (schema == null) {
                    schemas += (GLib.Settings) null;
                } else {
                    schemas += new GLib.Settings.full (schema, null, null);
                }
            }
        }

        public bool valid (Schema schema, string key) {
            // check if schema exists
            if (schema < 0 || schema >= Schema.COUNT)
                return false;

            var gsettings = schemas[schema];
            if (gsettings == null) {
                return false;
            }

             // check if key exists
            foreach (string tmp_key in gsettings.settings_schema.list_keys ()) {
                if (key == tmp_key) {
                    return true;
                }
            }

            return false;
        }

        // get/set methods for shortcuts in gsettings
        // require and return class Shortcut objects
        public Shortcut? get_val (Schema schema, string key) {
            if (!valid (schema, key)) {
                return (Shortcut) null;
            }

            var gsettings = schemas[schema];
            VariantType key_type = gsettings.settings_schema.get_key (key).get_value_type ();
            string? str = null;
            if (key_type.equal (VariantType.STRING)) {
                str = gsettings.get_string (key);
            } else if (key_type.equal (VariantType.STRING_ARRAY)) {
                str = gsettings.get_strv (key)[0];
            }

            return new Shortcut.parse (str);
        }
    }
}
