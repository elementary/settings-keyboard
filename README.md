# Keyboard Settings
[![Translation status](https://l10n.elementaryos.org/widget/settings/keyboard/svg-badge.svg)](https://l10n.elementaryos.org/engage/settings/)

![screenshot](data/screenshot-layout.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libswitchboard-3-dev
* libgnomekbd-dev
* libgranite-70dev
* libgtk-4-dev
* libadwaita-1-dev
* libibus-1.0-dev
* libxklavier-dev
* libxml2-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
