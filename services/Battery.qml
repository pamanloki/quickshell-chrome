pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "root:/config"

/** Battery state from UPower, with ChromeOS-style rounding & icons. */
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: device && device.isLaptopBattery
    readonly property int percent: available ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: available
        && (device.state === UPowerDeviceState.Charging
            || device.state === UPowerDeviceState.FullyCharged)
    readonly property bool full: available && device.state === UPowerDeviceState.FullyCharged

    // Seconds to full/empty -> human string
    readonly property string timeRemaining: {
        if (!available) return "";
        const secs = charging ? device.timeToFull : device.timeToEmpty;
        if (secs <= 0) return "";
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        if (h > 0) return h + " hr " + m + " min";
        return m + " min";
    }

    readonly property string icon: {
        if (!available) return "power";
        if (charging) return "battery_charging_full";
        if (percent >= 95) return "battery_full";
        if (percent >= 85) return "battery_6_bar";
        if (percent >= 70) return "battery_5_bar";
        if (percent >= 55) return "battery_4_bar";
        if (percent >= 40) return "battery_3_bar";
        if (percent >= 25) return "battery_2_bar";
        if (percent >= 10) return "battery_1_bar";
        return "battery_alert";
    }

    readonly property color color: {
        if (charging) return Theme.good;
        if (percent <= 15) return Theme.bad;
        if (percent <= 30) return Theme.warn;
        return Theme.text;
    }
}
