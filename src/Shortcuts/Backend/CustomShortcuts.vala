/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

namespace Keyboard.Shortcuts.CustomShortcuts {
    public enum ActionType {
        DESKTOP_FILE,
        COMMAND_LINE
    }

    public struct ParsedShortcut {
        ActionType type;
        string target;
        GLib.HashTable<string, Variant> parameters;
        string[] keybindings;
    }

    public const string SETTINGS_SCHEMA = "io.elementary.settings-daemon.applications";
    public const string APPLICATION_SHORTCUTS = "application-shortcuts";
}
