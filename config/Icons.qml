pragma Singleton

import Quickshell
import QtQuick

/**
 * Maps the semantic icon names used across the shell to Nerd Font glyphs.
 * Codepoints are from the stable Font Awesome block (U+F000–U+F2FF) that every
 * Nerd Font ships, so a single JetBrains Mono Nerd Font renders text + icons.
 * Unknown names fall through to the raw string (so a literal glyph also works).
 */
Singleton {
    id: root

    readonly property var map: ({
        // general / system
        "search":             0xf002,  //
        "settings":           0xf013,  //
        "lock":               0xf023,  //
        "power_settings_new": 0xf011,  //
        "power":              0xf1e6,  //
        "chevron_right":      0xf054,  //
        "notifications":      0xf0f3,  //
        "do_not_disturb_on":  0xf1f6,  //
        "nightlight":         0xf186,  //
        "brightness_high":    0xf185,  //
        "brightness_medium":  0xf185,  //

        // volume
        "volume_up":          0xf028,  //
        "volume_down":        0xf027,  //
        "volume_mute":        0xf027,  //
        "volume_off":         0xf026,  //

        // network (Font Awesome has one wifi glyph; levels reuse it)
        "network_wifi":              0xf1eb,  //
        "network_wifi_3_bar":        0xf1eb,
        "network_wifi_2_bar":        0xf1eb,
        "network_wifi_1_bar":        0xf1eb,
        "signal_wifi_statusbar_null":0xf1eb,
        "signal_wifi_off":           0xf1eb,
        "wifi_off":                  0xf1eb,
        "settings_ethernet":         0xf0e8,  //  (sitemap / wired)

        // bluetooth
        "bluetooth":            0xf293,  //
        "bluetooth_connected":  0xf294,  //
        "bluetooth_disabled":   0xf293,  //

        // battery
        "battery_charging_full": 0xf0e7, //  (bolt)
        "battery_full":          0xf240, //
        "battery_6_bar":         0xf240,
        "battery_5_bar":         0xf241, //
        "battery_4_bar":         0xf241,
        "battery_3_bar":         0xf242, //
        "battery_2_bar":         0xf243, //
        "battery_1_bar":         0xf243,
        "battery_alert":         0xf244, //
    })

    function glyph(name) {
        if (!name)
            return "";
        const cp = map[name];
        return cp !== undefined ? String.fromCharCode(cp) : name;
    }
}
