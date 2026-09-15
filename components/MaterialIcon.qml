import QtQuick
import "root:/config"

/**
 * A single Material Symbols Rounded glyph. `icon` is the ligature name, e.g.
 * "settings", "wifi", "battery_full". `fill` (0/1) toggles the filled variant
 * via the variable font's FILL axis (needs Qt 6.7+).
 */
Text {
    id: root

    property string icon: ""
    property int size: 22
    property int fill: 0        // 0 = outline, 1 = filled
    property int grade: 0
    property int weight: 400

    text: icon
    color: Theme.text
    font.family: Theme.iconFamily
    font.pixelSize: size
    font.weight: weight
    font.variableAxes: ({
        "FILL": fill,
        "GRAD": grade,
        "opsz": Math.max(20, Math.min(48, size)),
        "wght": weight
    })

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
}
