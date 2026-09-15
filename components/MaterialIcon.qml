import QtQuick
import "root:/config"

/**
 * A single icon glyph rendered from JetBrains Mono Nerd Font. `icon` is a
 * semantic name (e.g. "settings", "wifi") resolved to a Nerd Font glyph via the
 * Icons map; passing a literal glyph works too. `fill`/`grade`/`weight` are
 * kept for call-site compatibility (Nerd Font glyphs are not variable-axis).
 */
Text {
    id: root

    property string icon: ""
    property int size: 22
    property int fill: 0
    property int grade: 0
    property int weight: 400

    text: Icons.glyph(icon)
    color: Theme.text
    font.family: Theme.iconFamily
    font.pixelSize: size
    font.weight: weight

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
}
