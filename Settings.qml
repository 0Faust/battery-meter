import QtQuick
import qs.config
import qs.widgets
import "."

// Settings → Плагины → Батарея
Column {
    property var plugin
    width: parent ? parent.width : 400
    spacing: Theme.u * 5

    PxGroup {
        title: I18n.t("Батарея", "Battery")
        icon: "battery"
        width: parent.width

        SettingRow {
            label: I18n.t("Предупреждение (%), ≤", "Warn below (%)")
            hint: I18n.t("жёлтый цвет на панели", "yellow color on bar")
            PxSlider {
                width: parent.width
                from: 5
                to: 50
                stepSize: 5
                value: plugin ? plugin.get("warnAt", 20) : 20
                suffix: "%"
                onReleased: v => plugin.set("warnAt", v)
            }
        }

        SettingRow {
            label: I18n.t("Критически мало (%), ≤", "Critical below (%)")
            hint: I18n.t("красный цвет на панели", "red color on bar")
            PxSlider {
                width: parent.width
                from: 1
                to: 20
                stepSize: 1
                value: plugin ? plugin.get("critAt", 10) : 10
                suffix: "%"
                onReleased: v => plugin.set("critAt", v)
            }
        }

        SettingRow {
            label: I18n.t("Уведомления о низком заряде", "Low battery notifications")
            hint: I18n.t("20%, 15%, 10% и 5%", "20%, 15%, 10% and 5%")
            PxToggle {
                checked: plugin ? plugin.get("notificationsEnabled", true) : true
                onToggled: c => plugin.set("notificationsEnabled", c)
            }
        }

        SettingRow {
            label: I18n.t("Виджет на рабочем столе", "Desktop widget")
            PxToggle {
                checked: plugin ? plugin.get("desktopVisible", true) : true
                onToggled: c => plugin.set("desktopVisible", c)
            }
        }
    }

    PxGroup {
        title: I18n.t("Текущий статус", "Current status")
        icon: "info"
        width: parent.width

        SettingRow {
            label: I18n.t("Заряд", "Charge")
            PxText {
                text: BatteryState.percent + "%"
                font.bold: true
            }
        }
        SettingRow {
            label: I18n.t("Статус", "Status")
            PxText {
                text: BatteryState.stateLabel
            }
        }
        SettingRow {
            label: I18n.t("Мощность", "Power")
            PxText {
                text: BatteryState.watt > 0 ? BatteryState.watt.toFixed(1) + " W" : "—"
                dim: BatteryState.watt <= 0
            }
        }
        SettingRow {
            label: I18n.t("Батарея", "Battery")
            PxText {
                text: BatteryState._bat || I18n.t("не найдена", "not found")
                dim: !BatteryState.present
            }
        }
    }
}
