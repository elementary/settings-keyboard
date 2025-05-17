xkbconf = dependency('xkeyboard-config')
xkb_base = xkbconf.get_pkgconfig_variable('xkb_base')

conf_data = configuration_data()
conf_data.set('XKB_BASE', xkb_base)
conf_data.set('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf_data.set('GETTEXT_PACKAGE', gettext_name)
config_file = configure_file (
    input: 'Config.vala.in',
    output: 'Config.vala',
    configuration: conf_data
)

plug_files = files(
    'Behavior/Behavior.vala',
    'InputMethod/Installer/aptd-client.vala',
    'InputMethod/Installer/InstallList.vala',
    'InputMethod/Installer/UbuntuInstaller.vala',
    'InputMethod/Widgets/AddEngineDialog.vala',
    'InputMethod/Widgets/EnginesRow.vala',
    'InputMethod/Widgets/InstallEngineDialog.vala',
    'InputMethod/Widgets/LanguagesRow.vala',
    'InputMethod/Widgets/ProgressDialog.vala',
    'InputMethod/AddEnginesList.vala',
    'InputMethod/InputMethod.vala',
    'InputMethod/Utils.vala',
    'InputSources/InputSource.vala',
    'InputSources/SourceSettings.vala',
    'InputSources/XkbLayoutHandler.vala',
    'InputSources/XkbModifier.vala',
    'Layout/Widgets/AddLayoutDialog.vala',
    'Layout/Widgets/AdvancedSettingsPanel.vala',
    'Layout/Widgets/Display.vala',
    'Layout/Layout.vala',
    'Shortcuts/Backend/ConflictsManager.vala',
    'Shortcuts/Backend/CustomShortcutSettings.vala',
    'Shortcuts/Backend/Settings.vala',
    'Shortcuts/Backend/Shortcut.vala',
    'Shortcuts/Backend/ShortcutsList.vala',
    'Shortcuts/Widgets/ConflictDialog.vala',
    'Shortcuts/Widgets/CustomShortcutListBox.vala',
    'Shortcuts/Widgets/CustomShortcutRow.vala',
    'Shortcuts/Widgets/ShortcutListBox.vala',
    'Shortcuts/Shortcuts.vala',
    'Plug.vala'
)

switchboard_dep = dependency('switchboard-3')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

posix_dep = meson.get_compiler('vala').find_library('posix')

ibus_dep = dependency('ibus-1.0')
if(ibus_dep.version().version_compare('>=1.5.19'))
    add_project_arguments(['--define', 'IBUS_1_5_19'], language: 'vala')
endif

shared_module(
    meson.project_name(),
    plug_files,
    config_file,
    gresources,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gobject-2.0'),
        dependency('granite-7'),
        dependency('gtk4'),
        dependency('libadwaita-1'),
        dependency('libxml-2.0'),
        posix_dep,
        ibus_dep,
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'hardware')
)
