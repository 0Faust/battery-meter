import QtQuick
import qs.config
import qs.widgets
import "."

// Desktop widget: big pixel battery display for the desktop.
Item {
    property var plugin
    property string screenName
    property var widget

    readonly property bool wantVisible: !plugin || plugin.get("desktopVisible", true)

    implicitWidth:  Theme.u * 100
    implicitHeight: col.implicitHeight

    function _color(pct, hell) {
        if (pct <= BatteryState.critAt)
            return hell ? Theme.hellBlood : Theme.danger;
        if (pct <= BatteryState.warnAt)
            return hell ? Theme.hellEmber : Theme.accent3;
        if (BatteryState.charging || BatteryState.full)
            return hell ? Theme.hellGold  : Theme.ok;
        return hell ? Theme.hellFlame : Theme.accent;
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.u * 3

        // Title
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Theme.hell
                ? I18n.t("ЗАРЯД ТЬМЫ", "DARK CHARGE")
                : I18n.t("Батарея", "Battery")
            kind: "title"
            font.family: Theme.hell && Theme.latin(text) ? Theme.fontHell : Theme.fontTitle
            font.pixelSize: Theme.hell && Theme.latin(text) ? Theme.hellPx(Theme.fs) : Theme.sizeTitle
            color: _color(BatteryState.percent, Theme.hell)
        }

        // Big percentage
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: BatteryState.percent + "%"
            font.bold: true
            font.pixelSize: Theme.sizeTitle * 2
            color: _color(BatteryState.percent, Theme.hell)
        }

        // 20-segment pixel bar
        PxBox {
            width: parent.width
            height: Theme.u * 10
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
                        radius: Theme.u
                        color: !lit ? "transparent"
                            : !Theme.hell
                                ? _color(BatteryState.percent, false)
                                : index < 4  ? Theme.hellBlood
                                : index < 10 ? Theme.hellEmber
                                : index < 17 ? Theme.hellFlame
                                : Theme.hellGold
                    }
                }
            }
        }

        // Status + time
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: BatteryState.stateLabel
            color: _color(BatteryState.percent, Theme.hell)
            font.bold: true
        }

        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: BatteryState.watt > 0
            text: BatteryState.watt.toFixed(1) + " W"
            kind: "tiny"
            dim: !Theme.hell
            color: Theme.hell ? Theme.hellTextDim : Theme.textDim
        }
    }
}
