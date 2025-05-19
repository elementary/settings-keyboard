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
        return CustomShortcutSettings.shortcut_conflicts (shortcut, out name, null);
    }

    private static bool standard_shortcut_conflicts (Shortcut shortcut, out string name, out string group) {
        // putting this in standard_shortcuts initially doesn't work because we don't create an instance of ConflictsManager
        if (standard_shortcuts == null) {
            standard_shortcuts = {
                {new Shortcut.parse ("<Ctrl>C"), _("Edit"), _("Copy")},
                {new Shortcut.parse ("<Ctrl>V"), _("Edit"), _("Paste")},
                {new Shortcut.parse ("<Ctrl>X"), _("Edit"), _("Cut")},
                {new Shortcut.parse ("<Ctrl>Z"), _("Edit"), _("Undo")},
                {new Shortcut.parse ("<Ctrl>Y"), _("Edit"), _("Redo")},
                {new Shortcut.parse ("<Ctrl>F"), _("Edit"), _("Find")},

                {new Shortcut.parse ("<Ctrl>A"), _("Selection"), _("Select All")},
                {new Shortcut.parse ("<Shift>Right"), _("Selection"), _("Move Right by Word")},
                {new Shortcut.parse ("<Ctrl>Left"), _("Selection"), _("Move Left by Word")},
                {new Shortcut.parse ("<Shift>Right"), _("Selection"), _("Expand Selection")},
                {new Shortcut.parse ("<Shift>Left"), _("Selection"), _("Shrink Selection")},
                {new Shortcut.parse ("<Shift><Ctrl>Right"), _("Selection"), _("Expand Selection by Word")},
                {new Shortcut.parse ("<Shift><Ctrl>Left"), _("Selection"), _("Shrink Selection by Word")},
                {new Shortcut.parse ("<Shift>Up"), _("Selection"), _("Expand Selection Up")},
                {new Shortcut.parse ("<Shift>Down"), _("Selection"), _("Expand Selection Down")},
                
                {new Shortcut.parse ("<Ctrl>S"), _("File"), _("Save")},
                {new Shortcut.parse ("<Ctrl><Shift>S"), _("File"), _("Save As")},
                {new Shortcut.parse ("<Ctrl>N"), _("File"), _("New")},
                {new Shortcut.parse ("<Ctrl>W"), _("File"), _("Close")},
                {new Shortcut.parse ("<Ctrl>T"), _("File"), _("New Tab")},
                {new Shortcut.parse ("<Ctrl><Shift>T"), _("File"), _("Restore Closed Tab")},
                {new Shortcut.parse ("<Ctrl>R"), _("File"), _("Refresh")},
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
