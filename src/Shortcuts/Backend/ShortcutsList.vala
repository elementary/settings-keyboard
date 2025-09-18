/*
* Copyright (c) 2017-2018 elementary, LLC. (https://elementary.io)
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
    struct Group {
        public string icon_name;
        public string label;

        public GLib.ListStore list;
    }

    public class Action : Object {
        public Schema schema { get; construct; }
        public string action { get; construct; }
        public string key { get; construct; }

        public Action (Schema schema, string action, string key) {
            Object (
                schema: schema,
                action: action,
                key: key
            );
        }
    }

    class ShortcutsList : GLib.Object {
        public Group[] groups;
        public Group windows_group;
        public Group workspaces_group;
        public Group screenshot_group;
        public Group launchers_group;
        public Group media_group;
        public Group a11y_group;
        public Group system_group;
        public Group keyboard_layouts_group;
        public Group custom_group;

        private static GLib.Once<ShortcutsList> instance;
        public static unowned ShortcutsList get_default () {
            return instance.once (() => {
                return new ShortcutsList ();
            });
        }

        private ShortcutsList () {}

        construct {
            windows_group = Group () {
                list = new GLib.ListStore (typeof (Keyboard.Shortcuts.Action))
            };
            windows_group.icon_name = "io.elementary.settings.keyboard.windows";
            windows_group.label = _("Windows");
            add_action (ref windows_group, Schema.WM, _("Close"), "close");
            add_action (ref windows_group, Schema.WM, _("Lower"), "lower");
            add_action (ref windows_group, Schema.WM, _("Maximize"), "maximize");
            add_action (ref windows_group, Schema.WM, _("Unmaximize"), "unmaximize");
            add_action (ref windows_group, Schema.WM, _("Toggle Maximized"), "toggle-maximized");
            add_action (ref windows_group, Schema.WM, _("Hide"), "minimize");
            add_action (ref windows_group, Schema.WM, _("Toggle Fullscreen"), "toggle-fullscreen");
            add_action (ref windows_group, Schema.WM, _("Toggle on all Workspaces"), "toggle-on-all-workspaces");
            add_action (ref windows_group, Schema.WM, _("Toggle always on Top"), "toggle-above");
            add_action (ref windows_group, Schema.WM, _("Cycle Windows"), "switch-windows");
            add_action (ref windows_group, Schema.WM, _("Cycle Windows backwards"), "switch-windows-backward");
            add_action (ref windows_group, Schema.WM, _("Cycle Windows of application"), "switch-group");
            add_action (ref windows_group, Schema.WM, _("Cycle Windows of application backwards"), "switch-group-backward");
            add_action (ref windows_group, Schema.MUTTER, _("Tile Left"), "toggle-tiled-left");
            add_action (ref windows_group, Schema.MUTTER, _("Tile Right"), "toggle-tiled-right");
            add_action (ref windows_group, Schema.GALA, _("Window Overview"), "expose-windows");
            add_action (ref windows_group, Schema.GALA, _("Show All Windows"), "expose-all-windows");
            add_action (ref windows_group, Schema.GALA, _("Picture in Picture Mode"), "pip");
            add_action (ref windows_group, Schema.WM, _("Move to display above"), "move-to-monitor-up");
            add_action (ref windows_group, Schema.WM, _("Move to display below"), "move-to-monitor-down");
            add_action (ref windows_group, Schema.WM, _("Move to right display"), "move-to-monitor-right");
            add_action (ref windows_group, Schema.WM, _("Move to left display"), "move-to-monitor-left");

            workspaces_group = Group () {
                list = new GLib.ListStore (typeof (Keyboard.Shortcuts.Action))
            };
            workspaces_group.icon_name = "preferences-desktop-workspaces";
            workspaces_group.label = _("Workspaces");
            add_action (ref workspaces_group, Schema.GALA, _("Multitasking View"), "toggle-multitasking-view");
            add_action (ref workspaces_group, Schema.WM, _("Switch left"), "switch-to-workspace-left");
            add_action (ref workspaces_group, Schema.WM, _("Switch right"), "switch-to-workspace-right");
            add_action (ref workspaces_group, Schema.GALA, _("Switch to first"), "switch-to-workspace-first");
            add_action (ref workspaces_group, Schema.GALA, _("Switch to new"), "switch-to-workspace-last");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 1"), "switch-to-workspace-1");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 2"), "switch-to-workspace-2");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 3"), "switch-to-workspace-3");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 4"), "switch-to-workspace-4");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 5"), "switch-to-workspace-5");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 6"), "switch-to-workspace-6");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 7"), "switch-to-workspace-7");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 8"), "switch-to-workspace-8");
            add_action (ref workspaces_group, Schema.WM, _("Switch to workspace 9"), "switch-to-workspace-9");
            add_action (ref workspaces_group, Schema.GALA, _("Cycle workspaces"), "cycle-workspaces-next");
            add_action (ref workspaces_group, Schema.GALA, _("Cycle workspaces backwards"), "cycle-workspaces-previous");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 1"), "move-to-workspace-1");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 2"), "move-to-workspace-2");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 3"), "move-to-workspace-3");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 4"), "move-to-workspace-4");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 5"), "move-to-workspace-5");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 6"), "move-to-workspace-6");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 7"), "move-to-workspace-7");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 8"), "move-to-workspace-8");
            add_action (ref workspaces_group, Schema.WM, _("Move to workspace 9"), "move-to-workspace-9");
            add_action (ref workspaces_group, Schema.WM, _("Move to left workspace"), "move-to-workspace-left");
            add_action (ref workspaces_group, Schema.WM, _("Move to right workspace"), "move-to-workspace-right");

            screenshot_group = Group () {
                list = new GLib.ListStore (typeof (Keyboard.Shortcuts.Action))
            };
            screenshot_group.icon_name = "accessories-screenshot-tool";
            screenshot_group.label = _("Screenshots");
            add_action (ref screenshot_group, Schema.GALA, _("Grab the whole screen"), "screenshot");
            add_action (ref screenshot_group, Schema.GALA, _("Copy the whole screen to clipboard"), "screenshot-clip");
            add_action (ref screenshot_group, Schema.GALA, _("Grab the current window"), "window-screenshot");
            add_action (ref screenshot_group, Schema.GALA, _("Copy the current window to clipboard"), "window-screenshot-clip");
            add_action (ref screenshot_group, Schema.GALA, _("Select an area to grab"), "area-screenshot");
            add_action (ref screenshot_group, Schema.GALA, _("Copy an area to clipboard"), "area-screenshot-clip");

            launchers_group = Group () {
                list = new GLib.ListStore (typeof (Keyboard.Shortcuts.Action))
            };
            launchers_group.icon_name = "io.elementary.settings.keyboard.applications";
            launchers_group.label = _("Applications");
            add_action (ref launchers_group, Schema.MEDIA, _("Email"), "email");
            add_action (ref launchers_group, Schema.MEDIA, _("Home Folder"), "home");
            add_action (ref launchers_group, Schema.MEDIA, _("Music"), "media");
            add_action (ref launchers_group, Schema.MEDIA, _("Terminal"), "terminal");
            add_action (ref launchers_group, Schema.MEDIA, _("Internet Browser"), "www");
            add_action (ref launchers_group, Schema.DOCK, _("Launch first dock item"), "launch-dock-1");
            add_action (ref launchers_group, Schema.DOCK, _("Launch second dock item"), "launch-dock-2");
            add_action (ref launchers_group, Schema.DOCK, _("Launch third dock item"), "launch-dock-3");
            add_action (ref launchers_group, Schema.DOCK, _("Launch fourth dock item"), "launch-dock-4");
            add_action (ref launchers_group, Schema.DOCK, _("Launch fifth dock item"), "launch-dock-5");
            add_action (ref launchers_group, Schema.DOCK, _("Launch sixth dock item"), "launch-dock-6");
            add_action (ref launchers_group, Schema.DOCK, _("Launch seventh dock item"), "launch-dock-7");
            add_action (ref launchers_group, Schema.DOCK, _("Launch eighth dock item"), "launch-dock-8");
            add_action (ref launchers_group, Schema.DOCK, _("Launch ninth dock item"), "launch-dock-9");

            media_group = Group () {
                list = new GLib.ListStore (typeof (Keyboard.Shortcuts.Action))
            };
            media_group.icon_name = "applications-multimedia";
            media_group.label = _("Media");
            add_action (ref media_group, Schema.SOUND_INDICATOR, _("Volume Up"), "volume-up");
            add_action (ref media_group, Schema.SOUND_INDICATOR, _("Volume Down"), "volume-down");
            add_action (ref media_group, Schema.SOUND_INDICATOR, _("Mute"), "volume-mute");
            add_action (ref media_group, Schema.MEDIA, _("Play/Pause"), "play");
            add_action (ref media_group, Schema.MEDIA, _("Pause"), "pause");
            add_action (ref media_group, Schema.MEDIA, _("Stop"), "stop");
            add_action (ref media_group, Schema.MEDIA, _("Previous Track"), "previous");
            add_action (ref media_group, Schema.MEDIA, _("Next Track"), "next");
            add_action (ref media_group, Schema.MEDIA, _("Eject"), "eject");

            a11y_group = Group () {
                list = new GLib.ListStore (typeof (Keyboard.Shortcuts.Action))
            };
            a11y_group.icon_name = "preferences-desktop-accessibility";
            a11y_group.label = _("Universal Access");
            add_action (ref a11y_group, Schema.MEDIA, _("Decrease Text Size"), "decrease-text-size");
            add_action (ref a11y_group, Schema.MEDIA, _("Increase Text Size"), "increase-text-size");
            add_action (ref a11y_group, Schema.GALA, _("Magnifier Zoom in"), "zoom-in");
            add_action (ref a11y_group, Schema.GALA, _("Magnifier Zoom out"), "zoom-out");
            add_action (ref a11y_group, Schema.MEDIA, _("Toggle On Screen Keyboard"), "on-screen-keyboard");
            add_action (ref a11y_group, Schema.MEDIA, _("Toggle Screenreader"), "screenreader");

            system_group = Group () {
                list = new GLib.ListStore (typeof (Keyboard.Shortcuts.Action))
            };
            system_group.icon_name = "preferences-system";
            system_group.label = _("System");
            add_action (ref system_group, Schema.GALA, _("Applications Menu"), "panel-main-menu");
            add_action (ref system_group, Schema.MEDIA, _("Lock"), "screensaver");
            add_action (ref system_group, Schema.MEDIA, _("Log Out"), "logout");
            add_action (ref system_group, Schema.MUTTER, _("Cycle display mode"), "switch-monitor");

            keyboard_layouts_group = Group () {
                list = new GLib.ListStore (typeof (Keyboard.Shortcuts.Action))
            };
            keyboard_layouts_group.icon_name = "preferences-desktop-locale";
            keyboard_layouts_group.label = _("Keyboard Layouts");
            add_action (ref keyboard_layouts_group, Schema.GALA, _("Switch Keyboard Layout"), "switch-input-source");
            add_action (ref keyboard_layouts_group, Schema.GALA, _("Switch Keyboard Layout Backwards"), "switch-input-source-backward");
            add_action (ref keyboard_layouts_group, Schema.IBUS, _("Enable Emoji Typing"), "hotkey");
            add_action (ref keyboard_layouts_group, Schema.IBUS, _("Enable Unicode Typing"), "unicode-hotkey");

            custom_group = Group () {
                list = new GLib.ListStore (typeof (Keyboard.Shortcuts.Action))
            };
            custom_group.icon_name = "applications-other";
            custom_group.label = _("Custom");

            groups = {
                windows_group,
                workspaces_group,
                screenshot_group,
                launchers_group,
                media_group,
                a11y_group,
                system_group,
                keyboard_layouts_group
            };
        }

        public ListStore get_model (SectionID group) {
            return groups[group].list;
        }

        public void add_action (ref Group group, Schema schema, string action, string key) {
            var action_object = new Keyboard.Shortcuts.Action (schema, action, key);

            if (Settings.get_default ().valid (schema, key)) {
                group.list.append (action_object);
            }
        }
    }
}
