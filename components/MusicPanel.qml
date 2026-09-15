import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * Standalone Now Playing popup (MPRIS), opened from the shelf music glyph —
 * separate from Quick Settings. Album art, title/artist, transport controls
 * and a seek bar. Bottom-right above the shelf; scrim / Esc closes.
 */
PanelWindow {
    id: music

    WlrLayershell.namespace: "quickshell:music"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    MouseArea { anchors.fill: parent; onPressed: ShellState.closeAll() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: ShellState.closeAll() }

    Loader {
        active: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Theme.gapLarge
        anchors.bottomMargin: Theme.gap

        sourceComponent: Rectangle {
            id: bubble
            width: 340
            implicitHeight: col.implicitHeight + 2 * Theme.gapLarge
            height: implicitHeight
            radius: Theme.radiusLarge
            color: Theme.surfaceGlass
            border.width: 1
            border.color: Theme.outline

            transformOrigin: Item.BottomRight
            Component.onCompleted: { scale = 0.94; opacity = 0; anim.start(); }
            ParallelAnimation {
                id: anim
                NumberAnimation { target: bubble; property: "scale"; to: 1; duration: Theme.durNormal; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
                NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: Theme.durNormal }
            }

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.margins: Theme.gapLarge
                spacing: Theme.gap

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    // Album art
                    Rectangle {
                        width: 72; height: 72; radius: Theme.radius
                        color: Theme.surfaceHigh
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: Player.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: Player.artUrl.length > 0
                        }
                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: "music_note"; size: 32; color: Theme.textDim
                            visible: Player.artUrl.length === 0
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: Player.title || "Nothing playing"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTitle
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: Player.artist.length > 0
                            text: Player.artist
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            elide: Text.ElideRight
                        }
                    }
                }

                // scrubber
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    visible: Player.length > 0
                    height: 6
                    radius: 3
                    color: Theme.surfaceHigh
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        radius: 3
                        width: parent.width * Player.fraction
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: -6
                        anchors.bottomMargin: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (m) => Player.seek(m.x / width)
                    }
                }

                // transport controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 2
                    spacing: Theme.gapLarge
                    QsIconButton { diameter: 40; icon: "skip_previous"; onClicked: Player.previous() }
                    QsIconButton { diameter: 52; icon: Player.playing ? "pause" : "play_arrow"; iconColor: Theme.accent; onClicked: Player.playPause() }
                    QsIconButton { diameter: 40; icon: "skip_next"; onClicked: Player.next() }
                }
            }
        }
    }
}
