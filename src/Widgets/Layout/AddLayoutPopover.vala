class Pantheon.Keyboard.LayoutPage.AddLayout : Gtk.Popover {
    public signal void layout_added (string language, string layout);
    private Gtk.Widget keyboard_drawing_dialog;

    private Gtk.ListBox input_language_list_box;
    private Gtk.ListBox layout_list_box;
    private GLib.ListStore language_list;
    private GLib.ListStore layout_list;

    construct {
        height_request = 400;
        width_request = 400;

        language_list = new GLib.ListStore (typeof (ListStoreItem));
        layout_list = new GLib.ListStore (typeof (ListStoreItem));

        update_list_store (language_list, handler.languages);
        var first_lang = language_list.get_item (0) as ListStoreItem;
        update_list_store (layout_list, handler.get_variants_for_language (first_lang.id));

        input_language_list_box = new Gtk.ListBox ();
        input_language_list_box.bind_model (language_list, (item) => {
            return new LayoutRow ((item as ListStoreItem).name);
        });

        var input_language_scrolled = new Gtk.ScrolledWindow (null, null);
        input_language_scrolled.add (input_language_list_box);

        var back_button = new Gtk.Button.with_label (_("Input Language"));
        back_button.halign = Gtk.Align.START;
        back_button.margin = 6;
        back_button.get_style_context ().add_class ("back-button");

        var layout_list_title = new Gtk.Label (null);
        layout_list_title.ellipsize = Pango.EllipsizeMode.END;
        layout_list_title.max_width_chars = 20;
        layout_list_title.use_markup = true;

        layout_list_box = new Gtk.ListBox ();
        layout_list_box.bind_model (layout_list, (item) => {
            return new LayoutRow ((item as ListStoreItem).name);
        });
        var layout_scrolled = new Gtk.ScrolledWindow (null, null);
        layout_scrolled.expand = true;
        layout_scrolled.add (layout_list_box);

        var layout_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        layout_header_box.add (back_button);
        layout_header_box.set_center_widget (layout_list_title);

        var layout_grid = new Gtk.Grid ();
        layout_grid.orientation = Gtk.Orientation.VERTICAL;
        layout_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        layout_grid.add (layout_header_box);
        layout_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        layout_grid.add (layout_scrolled);

        var stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add (input_language_scrolled);
        stack.add (layout_grid);

        var keyboard_map_button = new Gtk.Button.from_icon_name ("input-keyboard-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        keyboard_map_button.tooltip_text = (_("Show keyboard layout"));
        keyboard_map_button.sensitive = false;
        keyboard_map_button.clicked.connect (() => {
            keyboard_map_button.sensitive = false;

            Gdk.Window rootwin = Gdk.get_default_root_window ();
            unowned X.Display display = (rootwin.get_display () as Gdk.X11.Display).get_xdisplay ();

            var engine = Xkl.Engine.get_instance (display);
            var registry = Xkl.ConfigRegistry.get_instance (engine);

            keyboard_drawing_dialog = new Gkbd.KeyboardDrawing.dialog_new ();
            ((Gtk.Dialog) keyboard_drawing_dialog).deletable = false;
            keyboard_drawing_dialog.destroy.connect (() => {
                keyboard_map_button.sensitive = true;
            });

            var layout_id = "%s\t%s".printf (get_selected_lang ().id, get_selected_layout ().id);
            Gkbd.KeyboardDrawing.dialog_set_layout (keyboard_drawing_dialog, registry, layout_id);
            keyboard_drawing_dialog.show_all ();
        });

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.add (keyboard_map_button);

        var selection_grid = new Gtk.Grid ();
        selection_grid.orientation = Gtk.Orientation.VERTICAL;
        selection_grid.add (stack);
        selection_grid.add (action_bar);

        var frame = new Gtk.Frame (null);
        frame.add (selection_grid);

        var button_add = new Gtk.Button.with_label (_("Add Layout"));
        button_add.sensitive = false;
        var button_cancel = new Gtk.Button.with_label (_("Cancel"));

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.margin_top = 12;
        button_box.spacing = 6;
        button_box.add (button_cancel);
        button_box.add (button_add);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 12;
        grid.margin = 12;
        grid.attach (frame, 0, 0, 1, 1);
        grid.attach (button_box, 0, 1, 1, 1);

        add (grid);

        button_cancel.clicked.connect (() => {
            this.hide ();
        });

        button_add.clicked.connect (() => {
            this.hide ();
            layout_added (get_selected_lang ().id, get_selected_layout ().id);
        });

        back_button.clicked.connect (() => {
            stack.visible_child = input_language_scrolled;
            layout_list_box.unselect_all ();
        });

        input_language_list_box.row_activated.connect (() => {
            var selected_lang = get_selected_lang ();
            update_list_store (layout_list, handler.get_variants_for_language (selected_lang.id));

            layout_list_title.label = "<b>%s</b>".printf (selected_lang.name);
            layout_list_box.show_all ();
            layout_list_box.select_row (layout_list_box.get_row_at_index (0));
            if (layout_list_box.get_row_at_index (0) != null) {
                layout_list_box.get_row_at_index (0).grab_focus ();
            }

            stack.visible_child = layout_grid;
        });

        layout_list_box.row_selected.connect ((row) => {
            keyboard_map_button.sensitive = row != null;
            button_add.sensitive = row != null;
        });
    }

    private ListStoreItem get_selected_lang () {
        var selected_lang_row = input_language_list_box.get_selected_row ();
        return language_list.get_item (selected_lang_row.get_index ()) as ListStoreItem;
    }

    private ListStoreItem get_selected_layout () {
        var selected_layout_row = layout_list_box.get_selected_row ();
        return layout_list.get_item (selected_layout_row.get_index ()) as ListStoreItem;
    }

    private void update_list_store (GLib.ListStore store, HashTable<string, string> values) {
        store.remove_all ();

        values.foreach ((key, val) => {
            store.append (new ListStoreItem (key, val));
        });

        store.sort ((a, b) => {
            if (((ListStoreItem)a).name == _("Default")) {
                return -1;
            }

            if (((ListStoreItem)b).name == _("Default")) {
                return 1;
            }

            return ((ListStoreItem)a).name.collate (((ListStoreItem)b).name);
        });
    }

    private class ListStoreItem : Object {
        public string id;
        public string name;

        public ListStoreItem (string id, string name) {
            this.id = id;
            this.name = name;
        }
    }

    private class LayoutRow : Gtk.ListBoxRow {
        public LayoutRow (string name) {
            var label = new Gtk.Label (name);
            label.margin = 6;
            label.xalign = 0;
            add (label);
        }
	}
}
