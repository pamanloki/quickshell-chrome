import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/services"

/**
 * Month calendar popup, opened by clicking the clock. Bottom-right above the
 * shelf; scrim / Esc closes. Prev/next month navigation, today highlighted.
 */
PanelWindow {
    id: cal

    WlrLayershell.namespace: "quickshell:calendar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"

    property int viewYear: Time.now.getFullYear()
    property int viewMonth: Time.now.getMonth()   // 0..11

    function shift(delta) {
        let m = viewMonth + delta, y = viewYear;
        if (m < 0) { m = 11; y--; } else if (m > 11) { m = 0; y++; }
        viewMonth = m; viewYear = y;
    }
    function today() { viewYear = Time.now.getFullYear(); viewMonth = Time.now.getMonth(); }

    readonly property int _daysIn: new Date(viewYear, viewMonth + 1, 0).getDate()
    readonly property int _firstDow: new Date(viewYear, viewMonth, 1).getDay()
    readonly property string _monthName: Qt.formatDate(new Date(viewYear, viewMonth, 1), "MMMM yyyy")

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
            width: 320
            implicitHeight: box.implicitHeight + 2 * Theme.gapLarge
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
                id: box
                anchors.fill: parent
                anchors.margins: Theme.gapLarge
                spacing: Theme.gap

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: cal._monthName
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.Bold
                    }
                    NavBtn { icon: "chevron_left"; onClicked: cal.shift(-1) }
                    NavBtn { icon: "today"; onClicked: cal.today() }
                    NavBtn { icon: "chevron_right"; onClicked: cal.shift(1) }
                }

                // Weekday labels
                Row {
                    Layout.fillWidth: true
                    Repeater {
                        model: ["S", "M", "T", "W", "T", "F", "S"]
                        delegate: Item {
                            required property var modelData
                            width: (box.width) / 7
                            height: 24
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                // Day grid (6 weeks)
                Grid {
                    Layout.fillWidth: true
                    columns: 7
                    Repeater {
                        model: 42
                        delegate: Item {
                            id: dayCell
                            required property int index
                            readonly property int day: index - cal._firstDow + 1
                            readonly property bool inMonth: day >= 1 && day <= cal._daysIn
                            readonly property bool isToday: inMonth
                                && day === Time.now.getDate()
                                && cal.viewMonth === Time.now.getMonth()
                                && cal.viewYear === Time.now.getFullYear()
                            width: box.width / 7
                            height: 36

                            Rectangle {
                                anchors.centerIn: parent
                                width: 30
                                height: 30
                                radius: 15
                                color: dayCell.isToday ? Theme.accent : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: dayCell.inMonth ? dayCell.day : ""
                                    color: dayCell.isToday ? Theme.textOnAccent : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: dayCell.isToday ? Font.Bold : Font.Normal
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component NavBtn: Rectangle {
        property string icon: ""
        signal clicked()
        width: 32
        height: 32
        radius: 16
        color: navMa.containsMouse ? Theme.hover : "transparent"
        MaterialIcon { anchors.centerIn: parent; icon: parent.icon; size: 20; color: Theme.text }
        MouseArea {
            id: navMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
