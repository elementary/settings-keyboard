/*
* Copyright 2017-2019 elementary, Inc. (https://elementary.io)
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
    // array of shortcut views, one for each section
    private Gtk.Widget[] shortcut_views;

    public enum SectionID {
        WINDOWS,
        WORKSPACES,
        SCREENSHOTS,
        APPS,
        MEDIA,
        A11Y,
        SYSTEM,
        KEYBOARD_LAYOUTS,
        CUSTOM,
        COUNT;

        public string to_string () {
            switch (this) {
                case WINDOWS:
                    return (_("Windows"));
                case WORKSPACES:
                    return (_("Workspaces"));
                case SCREENSHOTS:
                    return (_("Screenshots"));
                case APPS:
                    return (_("Applications"));
                case MEDIA:
                    return (_("Media"));
                case A11Y:
                    return (_("Accessibility"));
                case SYSTEM:
                    return (_("System"));
                case CUSTOM:
                    return (_("Custom"));
                default:
                    return "";
            }
        }
    }

    class Page : Gtk.Box {
        private Gtk.ListBox section_switcher;
        private SwitcherRow custom_shortcuts_row;

        construct {
            unowned var list = Shortcuts.ShortcutsList.get_default ();

            section_switcher = new Gtk.ListBox ();
            section_switcher.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
            section_switcher.append (new SwitcherRow (list.windows_group));
            section_switcher.append (new SwitcherRow (list.workspaces_group));
            section_switcher.append (new SwitcherRow (list.screenshot_group));
            section_switcher.append (new SwitcherRow (list.launchers_group));
            section_switcher.append (new SwitcherRow (list.media_group));
            section_switcher.append (new SwitcherRow (list.a11y_group));
            section_switcher.append (new SwitcherRow (list.system_group));
            section_switcher.append (new SwitcherRow (list.keyboard_layouts_group));

            custom_shortcuts_row = new SwitcherRow (list.custom_group);
            section_switcher.append (custom_shortcuts_row);

            var switcher_scrolled = new Gtk.ScrolledWindow () {
                child = section_switcher,
                hscrollbar_policy = NEVER
            };

            var switcher_frame = new Gtk.Frame (null) {
                child = switcher_scrolled
            };

            var stack = new Gtk.Stack () {
                vhomogeneous = false, // Prevents extra scrollbar in short lists
                vexpand = true
            };

            var stack_scrolled = new Gtk.ScrolledWindow () {
                child = stack
            };

            var frame = new Gtk.Frame (null) {
                child = stack_scrolled
            };

            spacing = 12;
            margin_start = 12;
            margin_end = 12;
            margin_bottom = 12;
            margin_top = 12;
            append (switcher_frame);
            append (frame);

            for (int id = 0; id < SectionID.CUSTOM; id++) {
                shortcut_views += new ShortcutListBox ((SectionID) id);
            }
            shortcut_views += new CustomShortcutListBox ();

            foreach (unowned Gtk.Widget view in shortcut_views) {
                stack.add_child (view);
            }

            section_switcher.row_selected.connect ((row) => {
                var index = row.get_index ();
                stack.visible_child = shortcut_views[index];
            });

            // Doing this too early makes the actionbar show by default
            realize.connect (() => {
                section_switcher.select_row (section_switcher.get_row_at_index (0));
            });
        }

        public void open_custom_shortcuts () {
            section_switcher.select_row (custom_shortcuts_row);
        }

        private class SwitcherRow : Gtk.ListBoxRow {
            public Keyboard.Shortcuts.Group group { get; construct; }

            public SwitcherRow (Keyboard.Shortcuts.Group group) {
                Object (group: group);
            }

            construct {
                var icon = new Gtk.Image.from_icon_name (group.icon_name) {
                    icon_size = LARGE
                };

                var label = new Gtk.Label (group.label) {
                    xalign = 0
                };

                var box = new Gtk.Box (HORIZONTAL, 6);
                box.append (icon);
                box.append (label);

                child = box;
            }
        }
    }
}
