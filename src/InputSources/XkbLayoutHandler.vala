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

public class Keyboard.XkbLayoutHandler : GLib.Object {
    private const string XKB_RULES_FILE = "evdev.xml";

    private static XkbLayoutHandler? instance = null;

    public static XkbLayoutHandler get_instance () {
        if (instance == null) {
            instance = new XkbLayoutHandler ();
        }

        return instance;
    }

    public HashTable<string, string> languages { get; private set; }

    private XkbLayoutHandler () {}

    construct {
        languages = new HashTable<string, string> (str_hash, str_equal);

        Xml.Doc* doc = Xml.Parser.parse_file (get_xml_rules_file_path ());
        if (doc == null) {
            critical ("'%s' not found or permissions missing\n", XKB_RULES_FILE);
            return;
        }

        Xml.XPath.Context cntx = new Xml.XPath.Context (doc);
        Xml.XPath.Object* res = cntx.eval_expression ("/xkbConfigRegistry/layoutList/layout/configItem");

        if (res == null) {
            delete doc;
            critical ("Unable to parse '%s'", XKB_RULES_FILE);
            return;
        }

        if (res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null) {
            delete res;
            delete doc;
            critical ("No layouts found in '%s'", XKB_RULES_FILE);
            return;
        }

        for (int i = 0; i < res->nodesetval->length (); i++) {
            Xml.Node* node = res->nodesetval->item (i);
            string? name = null;
            string? description = null;
            for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                    if (iter->name == "name") {
                        name = iter->get_content ();
                    } else if (iter->name == "description") {
                        description = dgettext ("xkeyboard-config", iter->get_content ());
                    }
                }
            }
            if (name != null && description != null) {
                languages.set (name, description);
            }
        }

        delete res;
        delete doc;
    }

    private string get_xml_rules_file_path () {
        unowned string? base_path = GLib.Environment.get_variable ("XKB_CONFIG_ROOT");
        if (base_path == null) {
            base_path = Constants.XKB_BASE;
        }

        return Path.build_filename (base_path, "rules", XKB_RULES_FILE);
    }

    public HashTable<string, string> get_variants_for_language (string language) {
        var returned_table = new HashTable<string, string> (str_hash, str_equal);
        returned_table.set ("", _("Default"));

        string file_path = get_xml_rules_file_path ();
        Xml.Doc* doc = Xml.Parser.parse_file (file_path);
        if (doc == null) {
            critical ("'%s' not found or permissions incorrect\n", XKB_RULES_FILE);
            return returned_table;
        }

        Xml.XPath.Context cntx = new Xml.XPath.Context (doc);
        var xpath = @"/xkbConfigRegistry/layoutList/layout/configItem/name[text()='$language']/../../variantList/variant/configItem";//vala-lint=line-leng //vala-lint=line-length
        Xml.XPath.Object* res = cntx.eval_expression (xpath);

        if (res == null) {
            delete doc;
            critical ("Unable to parse '%s'", XKB_RULES_FILE);
            return returned_table;
        }

        if (res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null) {
            delete res;
            delete doc;
            warning (@"No variants for $language found in '%s'", XKB_RULES_FILE);
            return returned_table;
        }

        for (int i = 0; i < res->nodesetval->length (); i++) {
            Xml.Node* node = res->nodesetval->item (i);

            string? name = null;
            string? description = null;
            for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                    if (iter->name == "name") {
                        name = iter->get_content ();
                    } else if (iter->name == "description") {
                        description = dgettext ("xkeyboard-config", iter->get_content ());
                    }
                }
            }
            if (name != null && description != null) {
                returned_table.set (name, description);
            }
        }

        delete res;
        delete doc;

        return returned_table;
    }

    public string get_display_name (string variant) {
        if ("+" in variant) {
            var parts = variant.split ("+", 2);
            return get_variants_for_language (parts[0]).get (parts[1]);
        } else {
            return languages.get (variant);
        }
    }
}
