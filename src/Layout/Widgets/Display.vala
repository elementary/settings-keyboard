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

// widget to display/add/remove/move keyboard layouts
public class Keyboard.LayoutPage.Display : Gtk.Frame {
    private SourceSettings settings;
    private Gtk.ListBox list;

    construct {
        settings = SourceSettings.get_instance ();

        list = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.BROWSE,
            hexpand = true
        };
        list.add_css_class (Granite.STYLE_CLASS_RICH_LIST);

        var add_button_label = new Gtk.Label (_("Add Keyboard Layout…"));

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
        add_button_box.append (add_button_label);

        var add_button = new Gtk.Button () {
            child = add_button_box
        };
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        add_button_label.mnemonic_widget = add_button;

        var actionbar = new Gtk.ActionBar ();
        actionbar.pack_start (add_button);
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var box = new Gtk.Box (VERTICAL, 0);
        box.append (list);
        box.append (actionbar);

        child = box;

        add_button.clicked.connect (() => {
            var dialog = new AddLayoutDialog ();
            dialog.transient_for = (Gtk.Window) get_root ();

            dialog.present ();
            dialog.layout_added.connect ((layout, variant) => {
                settings.add_layout (InputSource.new_xkb (layout, variant));
                rebuild_list ();
            });
        });

        list.row_activated.connect (() => {
            settings.active_index = get_cursor_index ();
        });

        settings.notify["active-index"].connect (update_cursor);

        settings.external_layout_change.connect (rebuild_list);

        rebuild_list ();
    }

    /**
     * Returns the index of the selected (xkb) layout in the list of (all) input sources.
     * In case the list contains no layouts, it returns 0.
     */
    private int get_cursor_index () {
        unowned var selected_row = (DisplayRow) list.get_selected_row ();

        if (selected_row == null) {
            return 0;
        }

        return (int) selected_row.index;
    }

    private void update_cursor () {
        if (settings.active_input_source == null) {
            return;
        }

        unowned var child = list.get_first_child ();
        while (child != null) {
            if (child is DisplayRow) {
                unowned var row = (DisplayRow) child;

                if (settings.active_index == row.index) {
                    list.select_row (row);
                    break;
                }
            }

            child = child.get_next_sibling ();
        }
    }

    public void rebuild_list () {
        while (list.get_row_at_index (0) != null) {
            list.remove (list.get_row_at_index (0));
        };

        uint i = 0;
        settings.foreach_layout ((input_source) => {
            if (input_source.layout_type == LayoutType.XKB) {
                var row = new DisplayRow (XkbLayoutHandler.get_instance ().get_display_name (input_source.name), i);
                list.append (row);

                row.remove_layout.connect ((row) => {
                    settings.remove_layout (row.index);
                    rebuild_list ();
                });

                row.move_up.connect ((row) => {
                    settings.switch_items (row.index, true);
                    rebuild_list ();
                });

                row.move_down.connect ((row) => {
                    settings.switch_items (row.index, false);
                    rebuild_list ();
                });
            }

            i++;
        });

        if (list.get_row_at_index (0) != null) {
            unowned var first_child = (DisplayRow) list.get_row_at_index (0);
            first_child.up_button.sensitive = false;

            int index = 0;
            while (list.get_row_at_index (index) != null) { index++; }
            unowned var last_child = (DisplayRow) list.get_row_at_index (index - 1);
            last_child.down_button.sensitive = false;
        }

        update_cursor ();
    }

    private class DisplayRow : Gtk.ListBoxRow {
        public signal void remove_layout ();
        public signal void move_up ();
        public signal void move_down ();

        public string layout_name { get; construct; }
        public uint index { get; construct; }

        public Gtk.Button up_button;
        public Gtk.Button down_button;

        public DisplayRow (string layout_name, uint index) {
            Object (
                layout_name: layout_name,
                index: index
            );
        }

        construct {
            var label = new Gtk.Label (layout_name) {
                hexpand = true,
                halign = START
            };

            var remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic") {
                tooltip_text = _("Remove")
            };

            up_button = new Gtk.Button.from_icon_name ("go-up-symbolic") {
                tooltip_text = _("Move up")
            };

            down_button = new Gtk.Button.from_icon_name ("go-down-symbolic") {
                tooltip_text = _("Move down"),
            };

            var box = new Gtk.Box (HORIZONTAL, 0);
            box.append (label);
            box.append (remove_button);
            box.append (up_button);
            box.append (down_button);

            child = box;

            remove_button.clicked.connect (() => remove_layout ());

            up_button.clicked.connect (() => move_up ());

            down_button.clicked.connect (() => move_down ());
        }
    }
}
