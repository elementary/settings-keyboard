/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2017-2025 elementary, Inc. (https://elementary.io)
 */

class Keyboard.Shortcuts.ConflictsManager : GLib.Object {
    private struct StandardShortcut {
        Shortcut shortcut;
        string group;
        string name;
    }

    private static StandardShortcut[]? standard_shortcuts = null;

    public static bool shortcut_conflicts (Shortcut shortcut, out string name, out string group) {
        name = "";
        group = SectionID.SYSTEM.to_string ();
        return (
            general_shortcut_conflicts (shortcut, out name, out group) ||
            custom_shortcut_conflicts (shortcut, out name, out group) ||
            standard_shortcut_conflicts (shortcut, out name, out group)
        );
    }

    private static bool general_shortcut_conflicts (Shortcut shortcut, out string name, out string group) {
        unowned var list = ShortcutsList.get_default ();

        for (int group_id = 0; group_id < SectionID.CUSTOM; group_id++) {
            string[] actions, keys;
            Schema[] schemas;

            name = "";
            group = ((SectionID) group_id).to_string ();
            list.get_group (group_id, out actions, out schemas, out keys);

            // For every action in group there is a corresponding schema and key entry
            // so only need to iterate actions
            for (int i = 0; i < actions.length; i++) {
                var action_shortcut = Settings.get_default ().get_val (schemas[i], keys[i]);
                if (shortcut.is_equal (action_shortcut)) {
                    name = actions[i];
                    return true;
                }
            }
        }

        name = "";
        group = SectionID.SYSTEM.to_string ();
        return false;
    }

    private static bool custom_shortcut_conflicts (Shortcut shortcut, out string name, out string group) {
        name = "";
        group = SectionID.CUSTOM.to_string ();

        var application_shortcuts = new GLib.Settings (CustomShortcuts.SETTINGS_SCHEMA);
        var shortcuts = (CustomShortcuts.ParsedShortcut[]) application_shortcuts.get_value (CustomShortcuts.APPLICATION_SHORTCUTS);
        for (int i = 0; i < shortcuts.length; i++) {
            for (int j = 0; j < shortcuts[i].keybindings.length; j++) {
                var action_shortcut = new Shortcut.parse (shortcuts[i].keybindings[j]);
                if (shortcut.is_equal (action_shortcut)) {
                    name = shortcuts[i].target;
                    return true;
                }
            }
        }

        return false;
    }

    private static bool standard_shortcut_conflicts (Shortcut shortcut, out string name, out string group) {
        // putting this in standard_shortcuts initially doesn't work because we don't create an instance of ConflictsManager
        if (standard_shortcuts == null) {
            standard_shortcuts = {
                /// The name of Ctrl + C shortcut: "Edit -> Copy"
                {new Shortcut.parse ("<Ctrl>C"), _("Edit"), _("Copy")},
                /// The name of Ctrl + V shortcut: "Edit -> Paste"
                {new Shortcut.parse ("<Ctrl>V"), _("Edit"), _("Paste")},
                /// The name of Ctrl + X shortcut: "Edit -> Cut"
                {new Shortcut.parse ("<Ctrl>X"), _("Edit"), _("Cut")},
                /// The name of Ctrl + Z shortcut: "Edit -> Undo"
                {new Shortcut.parse ("<Ctrl>Z"), _("Edit"), _("Undo")},
                /// The name of Ctrl + Y shortcut: "Edit -> Redo"
                {new Shortcut.parse ("<Ctrl>Y"), _("Edit"), _("Redo")},
                /// The name of Ctrl + F shortcut: "Edit -> Find"
                {new Shortcut.parse ("<Ctrl>F"), _("Edit"), _("Find")},

                /// The name of Ctrl + A shortcut: "Selection -> Select All"
                {new Shortcut.parse ("<Ctrl>A"), _("Selection"), _("Select All")},
                /// The name of Ctrl + Right shortcut: "Selection -> Move Right by Word"
                {new Shortcut.parse ("<Shift>Right"), _("Selection"), _("Move Right by Word")},
                /// The name of Ctrl + Left shortcut: "Selection -> Move Left by Word"
                {new Shortcut.parse ("<Ctrl>Left"), _("Selection"), _("Move Left by Word")},
                /// The name of Shift + Right shortcut: "Selection -> Expand Selection"
                {new Shortcut.parse ("<Shift>Right"), _("Selection"), _("Expand Selection")},
                /// The name of Shift + Left shortcut: "Selection -> Shrink Selection"
                {new Shortcut.parse ("<Shift>Left"), _("Selection"), _("Shrink Selection")},
                /// The name of Shift + Ctrl + Right shortcut: "Selection -> Expand Selection by Word"
                {new Shortcut.parse ("<Shift><Ctrl>Right"), _("Selection"), _("Expand Selection by Word")},
                /// The name of Shift + Ctrl + Left shortcut: "Selection -> Shrink Selection by Word"
                {new Shortcut.parse ("<Shift><Ctrl>Left"), _("Selection"), _("Shrink Selection by Word")},
                /// The name of Shift + Up shortcut: "Selection -> Expand Selection Up"
                {new Shortcut.parse ("<Shift>Up"), _("Selection"), _("Expand Selection Up")},
                /// The name of Shift + Down shortcut: "Selection -> Expand Selection Down"
                {new Shortcut.parse ("<Shift>Down"), _("Selection"), _("Expand Selection Down")},

                /// The name of Ctrl + S shortcut: "File -> Save"
                {new Shortcut.parse ("<Ctrl>S"), _("File"), _("Save")},
                /// The name of Ctrl + Shift + S shortcut: "File -> Save As"
                {new Shortcut.parse ("<Ctrl><Shift>S"), _("File"), _("Save As")},
                /// The name of Ctrl + N shortcut: "File -> New"
                {new Shortcut.parse ("<Ctrl>N"), _("File"), _("New")},
                /// The name of Ctrl + W shortcut: "File -> Close"
                {new Shortcut.parse ("<Ctrl>W"), _("File"), _("Close")},
                /// The name of Ctrl + T shortcut: "File -> New Tab"
                {new Shortcut.parse ("<Ctrl>T"), _("File"), _("New Tab")},
                /// The name of Ctrl + Shift + T shortcut: "File -> Restore Closed Tab"
                {new Shortcut.parse ("<Ctrl><Shift>T"), _("File"), _("Restore Closed Tab")},
                /// The name of Ctrl + R shortcut: "File -> Refresh"
                {new Shortcut.parse ("<Ctrl>R"), _("File"), C_("keyboard", "Refresh")},
                /// The name of Ctrl + Q shortcut: "File -> Quit"
                {new Shortcut.parse ("<Ctrl>Q"), _("File"), _("Quit")},
            };
        }

        for (var i = 0; i < standard_shortcuts.length; i++) {
            var standard_shortcut = standard_shortcuts[i];
            if (shortcut.is_equal (standard_shortcut.shortcut)) {
                group = standard_shortcut.group;
                name = standard_shortcut.name;
                return true;
            }
        }

        return false;
    }
}
