import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar
import "."

// Bar widget: pixel battery meter + percentage text.
// Click → popup with details.
Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow

    // Hide when no battery present (desktop PC)
    visible: BatteryState.present
    implicitWidth:  visible ? row.implicitWidth + Theme.u * 4 : 0
    implicitHeight: Theme.u * 13

    // ---- Color helpers ----
    function _color(pct, hell) {
        if (pct <= BatteryState.critAt)
            return hell ? Theme.hellBlood  : Theme.danger;
        if (pct <= BatteryState.warnAt)
            return hell ? Theme.hellEmber  : Theme.accent3;
        if (BatteryState.charging || BatteryState.full)
            return hell ? Theme.hellGold   : Theme.ok;
        return hell ? Theme.hellFlame : Theme.accent;
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.u * 2

        // ---- Pixel battery icon ----
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width:  cells * (cw + gap) - gap + Theme.u * 3   // body + nub
            height: bh

            readonly property int cells: 5
            readonly property int cw: Theme.u * 4
            readonly property int ch: Theme.u * 7
            readonly property int bh: ch
            readonly property int gap: Theme.u

            // outer border
            Rectangle {
                x: 0; y: (parent.bh - parent.ch) / 2
                width:  parent.cells * (parent.cw + parent.gap) - parent.gap
                height: parent.ch
                color: "transparent"
                border.color: Theme.hell
                    ? (root._color(BatteryState.percent, true))
                    : Theme.edge
                border.width: Theme.u
                radius: Theme.u
            }

            // nub on the right
            Rectangle {
                x:  parent.cells * (parent.cw + parent.gap) - parent.gap
                y:  (parent.bh - parent.ch / 2) / 2
                width:  Theme.u * 2
                height: parent.ch / 2
                color: Theme.hell
                    ? root._color(BatteryState.percent, true)
                    : Theme.edge
                radius: Theme.u
            }

            // lit cells
            Row {
                x: Theme.u; y: (parent.bh - parent.ch) / 2 + Theme.u
                spacing: parent.gap

                Repeater {
                    model: parent.parent.cells
                    Rectangle {
                        required property int index
                        readonly property int litCount: Math.round(BatteryState.percent / 100 * parent.parent.parent.cells)
                        readonly property bool lit: index < litCount

                        width:  parent.parent.parent.cw
                        height: parent.parent.parent.ch - Theme.u * 2
                        color: lit
                            ? root._color(BatteryState.percent, Theme.hell)
                            : "transparent"
                        radius: Math.max(0, Theme.u - 1)

                        // charging bolt blink on the rightmost lit cell
                        Rectangle {
                            visible: lit && BatteryState.charging && index === parent.litCount - 1
                            anchors.centerIn: parent
                            width:  Theme.u * 2
                            height: Theme.u * 2
                            radius: width / 2
                            color: Theme.hell ? Theme.hellFaceAlt : "#ffffff"
                            opacity: chargeBlink.running ? 0.9 : 0.0

                            SequentialAnimation on opacity {
                                id: chargeBlink
                                running: BatteryState.charging && parent.visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.9; duration: 500 }
                                NumberAnimation { to: 0.0; duration: 500 }
                            }
                        }
                    }
                }
            }
        }

        // ---- Percentage text ----
        PxText {
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryState.percent + "%"
            font.bold: BatteryState.percent <= BatteryState.warnAt
            color: root._color(BatteryState.percent, Theme.hell)
        }
    }

    // ---- Click → popup ----
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup
        panelId: "battery-meter"
        anchorItem: root
        above: BarLayout.bottom
        title: I18n.t("Батарея", "Battery")
        icon: "battery"
        contentWidth:  Theme.u * 140
        contentHeight: popCol.implicitHeight + Theme.u * 8

        Column {
            id: popCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.u * 4 }
            spacing: Theme.u * 4

            // Header row: big % + status
            Row {
                spacing: Theme.u * 4

                PxText {
                    text: BatteryState.percent + "%"
                    kind: "title"
                    font.bold: true
                    color: root._color(BatteryState.percent, Theme.hell)
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    PxText {
                        text: BatteryState.stateLabel
                        font.bold: true
                        color: Theme.hell
                            ? root._color(BatteryState.percent, true)
                            : root._color(BatteryState.percent, false)
                    }
                    PxText {
                        visible: BatteryState.watt > 0
                        text: BatteryState.watt.toFixed(1) + " W"
                        kind: "tiny"
                        dim: true
                    }
                }
            }

            // Pixel bar — 20 segments
            PxBox {
                width:  parent.width
                height: Theme.u * 8
                sunken: true
                hell: Theme.hell
                color: Theme.hell ? Theme.hellSunken : Theme.sunken

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.u
                    spacing: Math.max(1, Theme.u / 2)

                    Repeater {
                        model: 20
                        Rectangle {
                            required property int index
                            readonly property bool lit: index < Math.round(BatteryState.percent / 100 * 20)
                            width:  (parent.width - 19 * parent.spacing) / 20
                            height: parent.height
                            radius: Theme.u / 2
                            color: !lit ? "transparent"
                                : !Theme.hell
                                    ? root._color(BatteryState.percent, false)
                                    : index < 4  ? Theme.hellBlood
                                    : index < 10 ? Theme.hellEmber
                                    : index < 17 ? Theme.hellFlame
                                    : Theme.hellGold
                        }
                    }
                }
            }

            // Bat path info
            PxText {
                width: parent.width
                elide: Text.ElideRight
                text: "/sys/class/power_supply/" + BatteryState._bat
                kind: "tiny"
                dim: true
            }
        }
    }
}
