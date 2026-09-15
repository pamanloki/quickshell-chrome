import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"

/**
 * Rounded display corners (ChromeOS look): a click-through overlay per screen
 * that paints four black quarter-circle masks over the corners. Set
 * Theme.screenCornerRadius to 0 to disable.
 */
PanelWindow {
    id: corners
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell:corners"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"
    visible: Theme.screenCornerRadius > 0

    // fully click-through
    mask: Region {}

    Repeater {
        model: [
            { x: 0, y: 0, cx: 1, cy: 1 },   // top-left
            { x: 1, y: 0, cx: 0, cy: 1 },   // top-right
            { x: 0, y: 1, cx: 1, cy: 0 },   // bottom-left
            { x: 1, y: 1, cx: 0, cy: 0 }    // bottom-right
        ]
        delegate: Canvas {
            required property var modelData
            readonly property int r: Theme.screenCornerRadius
            width: r
            height: r
            x: modelData.x === 0 ? 0 : parent.width - r
            y: modelData.y === 0 ? 0 : parent.height - r
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "#000000";
                ctx.fillRect(0, 0, width, height);
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(modelData.cx * r, modelData.cy * r, r, 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }
}
