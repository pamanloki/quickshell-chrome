import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * On-screen display for volume & brightness: a rounded pill near the bottom
 * that pops up on change and auto-hides. One per screen; a shared ShellState
 * drives visibility so it shows everywhere at once.
 */
PanelWindow {
    id: osd
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { bottom: true }
    margins.bottom: Theme.shelfHeight + Theme.gapLarge
    exclusiveZone: 0
    color: "transparent"
    implicitWidth: 300
    implicitHeight: 56
    visible: ShellState.osdVisible || card.opacity > 0.01

    property bool ready: false
    Timer { running: true; interval: 1200; onTriggered: osd.ready = true }

    function pop(kind, value, muted) {
        // Don't pop while adjusting the same thing inside quick settings.
        if (!ready || ShellState.quickSettingsOpen)
            return;
        ShellState.showOsd(kind, value, muted);
    }

    Connections {
        target: Audio
        function onVolumeChanged() { osd.pop("volume", Math.round(Audio.volume * 100), Audio.muted); }
        function onMutedChanged()  { osd.pop("volume", Math.round(Audio.volume * 100), Audio.muted); }
    }
    Connections {
        target: Brightness
        function onFractionChanged() { osd.pop("brightness", Math.round(Brightness.fraction * 100), false); }
    }

    readonly property bool isVol: ShellState.osdKind === "volume"
    readonly property string glyph: {
        if (!isVol) return "brightness_high";
        if (ShellState.osdMuted || ShellState.osdValue <= 0) return "volume_off";
        if (ShellState.osdValue < 50) return "volume_down";
        return "volume_up";
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceGlass
        border.width: 1
        border.color: Theme.outline

        opacity: ShellState.osdVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: osd.glyph
                size: 24
                fill: 1
                color: (osd.isVol && ShellState.osdMuted) ? Theme.bad : Theme.text
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 24 - 14 - 46
                height: 6
                radius: 3
                color: Theme.surfaceHigh
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    radius: height / 2
                    width: parent.width * Math.max(0, Math.min(1, ShellState.osdValue / 100))
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                horizontalAlignment: Text.AlignRight
                text: ShellState.osdValue + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Font.Medium
            }
        }
    }
}
