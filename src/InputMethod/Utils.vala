/*
* 2019-2020 elementary, Inc. (https://elementary.io)
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

namespace Keyboard.InputMethodPage.Utils {
    // From https://github.com/ibus/ibus/blob/master/ui/gtk2/i18n.py#L47-L54
    private string gettext_engine_longname (IBus.EngineDesc engine) {
        string name = engine.name;
        if (name.has_prefix ("xkb:")) {
            return dgettext ("xkeyboard-config", engine.longname);
        }

        string textdomain = engine.textdomain;
        if (textdomain == "") {
            return engine.longname;
        }

        return dgettext (textdomain, engine.longname);
    }
}
