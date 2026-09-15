import QtQuick
import "root:/config"

/**
 * A single Material Symbols glyph. Requires the "Material Symbols Rounded" font
 * (see README). `icon` is the ligature name, e.g. "settings", "wifi".
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
    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.weight: weight
    // Material Symbols variable-font axes
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
