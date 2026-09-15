pragma Singleton

import Quickshell
import QtQuick

/** Shared clock so every widget ticks in sync and only one timer runs. */
Singleton {
    id: root

    readonly property date now: clock.date
    readonly property string time: Qt.formatDateTime(clock.date, "h:mm AP")
    readonly property string time24: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property string dayName: Qt.formatDateTime(clock.date, "ddd")
    readonly property string dateShort: Qt.formatDateTime(clock.date, "MMM d")
    readonly property string dateLong: Qt.formatDateTime(clock.date, "dddd, MMMM d")

    SystemClock {
        id: clock
        // Minute precision — nothing shows seconds, so this avoids a needless
        // per-second wakeup/re-render across the shell.
        precision: SystemClock.Minutes
    }
}
