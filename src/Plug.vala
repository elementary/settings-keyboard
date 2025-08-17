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

public class Keyboard.Plug : Switchboard.Plug {
    public static GLib.Settings ibus_general_settings;

    private Adw.ToolbarView toolbarview;
    private Gtk.Stack stack;

    public Plug () {
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");

        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("input/keyboard", "Layout");
        settings.set ("input/keyboard/layout", "Layout");
        settings.set ("input/keyboard/behavior", "Behavior");
        settings.set ("input/keyboard/inputmethod", "Input Method");
        settings.set ("input/keyboard/shortcuts", "Shortcuts");
        settings.set ("input/keyboard/shortcuts/custom", "Custom Shortcuts");
        Object (category: Category.HARDWARE,
                code_name: "io.elementary.settings.keyboard",
                display_name: _("Keyboard"),
                description: _("Configure keyboard behavior, layouts, and shortcuts"),
                icon: "preferences-desktop-keyboard",
                supported_settings: settings);
    }

    static construct {
        ibus_general_settings = new GLib.Settings ("org.freedesktop.ibus.general");
    }

    public override Gtk.Widget get_widget () {
        if (toolbarview == null) {
            Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).add_resource_path ("/io/elementary/settings/keyboard");

            stack = new Gtk.Stack ();
            stack.add_titled (new Keyboard.LayoutPage.Page (), "layout", _("Layout"));
            stack.add_titled (new Keyboard.InputMethodPage.Page (), "inputmethod", _("Input Method"));
            stack.add_titled (new Keyboard.Shortcuts.Page (), "shortcuts", _("Shortcuts"));
            stack.add_titled (new Keyboard.Behaviour.Page (), "behavior", _("Behavior"));

            var stack_switcher = new Gtk.StackSwitcher () {
                stack = stack
            };

            var size_group = new Gtk.SizeGroup (HORIZONTAL);
            unowned var switcher_child = stack_switcher.get_first_child ();
            while (switcher_child != null) {
                size_group.add_widget (switcher_child);
                switcher_child = switcher_child.get_next_sibling ();
            }

            var headerbar = new Adw.HeaderBar () {
                title_widget = stack_switcher
            };
            headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

            toolbarview = new Adw.ToolbarView () {
                content = stack
            };
            toolbarview.add_top_bar (headerbar);
        }

        return toolbarview;
    }

    public override void shown () {

    }

    public override void hidden () {

    }

    public override void search_callback (string location) {
        switch (location) {
            default:
            case "Custom Shortcuts":
                stack.visible_child_name = "shortcuts";
                ((Keyboard.Shortcuts.Page) stack.get_child_by_name ("shortcuts")).open_custom_shortcuts ();
                break;
            case "Shortcuts":
                stack.visible_child_name = "shortcuts";
                break;
            case "Behavior":
                stack.visible_child_name = "behavior";
                break;
            case "Input Method":
                stack.visible_child_name = "inputmethod";
                break;
            case "Layout":
                stack.visible_child_name = "layout";
                break;
        }
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        search_results.set ("%s → %s".printf (display_name, _("Layout")), "Layout");
        search_results.set ("%s → %s → %s".printf (display_name, _("Layout"), _("Switch layout")), "Layout");
        search_results.set ("%s → %s → %s".printf (display_name, _("Layout"), _("Compose Key")), "Layout");
        search_results.set ("%s → %s → %s".printf (display_name, _("Layout"), _("⌘ key behavior")), "Layout");
        search_results.set ("%s → %s → %s".printf (display_name, _("Layout"), _("Caps Lock behavior")), "Layout");
        search_results.set ("%s → %s".printf (display_name, _("Input Method")), "Input Method");
        search_results.set ("%s → %s → %s".printf (display_name, _("Input Method"), _("Switch engines")), "Input Method");
        search_results.set ("%s → %s → %s".printf (display_name, _("Input Method"), _("Show candidate window")), "Input Method");
        search_results.set ("%s → %s → %s".printf (display_name, _("Input Method"), _("Embed preedit text in application window")), "Input Method");
        search_results.set ("%s → %s".printf (display_name, _("Shortcuts")), "Shortcuts");
        search_results.set ("%s → %s".printf (display_name, _("Behavior")), "Behavior");
        search_results.set ("%s → %s → %s".printf (display_name, _("Behavior"), _("Show On-screen Keyboard")), "Behavior");
        search_results.set ("%s → %s → %s".printf (display_name, _("Behavior"), _("Bounce Keys")), "Behavior");
        search_results.set ("%s → %s → %s".printf (display_name, _("Behavior"), _("Cursor Blinking")), "Behavior");
        search_results.set ("%s → %s → %s".printf (display_name, _("Behavior"), _("Repeat Keys")), "Behavior");
        search_results.set ("%s → %s → %s".printf (display_name, _("Behavior"), _("Slow Keys")), "Behavior");
        search_results.set ("%s → %s → %s".printf (display_name, _("Behavior"), _("Sticky Keys")), "Behavior");
        return search_results;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Keyboard plug");
    IBus.init ();
    var plug = new Keyboard.Plug ();
    return plug;
}
