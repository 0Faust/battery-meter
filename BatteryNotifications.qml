import QtQuick
import Quickshell
import qs.services

Item {
    id: root

    property var plugin
    readonly property var thresholds: [20, 15, 10, 5]

    property int previousPercent: -1
    property bool initialized: false

    function notificationFor(percent) {
        let title;
        let body;
        let urgency;

        if (percent === 20) {
            title = I18n.t("Низкий заряд", "Low battery");
            body = I18n.t(
                "Осталось 20%. Подключите зарядное устройство.",
                "20% battery remaining. Please connect the charger."
            );
            urgency = "normal";
        } else if (percent === 15) {
            title = I18n.t("Низкий заряд", "Low battery");
            body = I18n.t(
                "Осталось 15%. Рекомендуется подключить зарядное устройство.",
                "15% battery remaining. It is recommended to connect the charger."
            );
            urgency = "normal";
        } else if (percent === 10) {
            title = I18n.t("Критический заряд", "Critical battery");
            body = I18n.t(
                "Осталось 10%. Подключите зарядное устройство.",
                "10% battery remaining. Connect the charger."
            );
            urgency = "critical";
        } else {
            title = I18n.t("Очень низкий заряд", "Very low battery");
            body = I18n.t(
                "Осталось 5%. Немедленно подключите зарядное устройство.",
                "5% battery remaining. Connect the charger immediately."
            );
            urgency = "critical";
        }

        Quickshell.execDetached([
            "notify-send",
            "--app-name=Battery",
            "--icon=battery",
            "--urgency=" + urgency,
            "--expire-time=6000",
            title,
            body
        ]);
    }

    function checkThresholds(oldPercent, newPercent) {
        if (plugin && !plugin.get("notificationsEnabled", true))
            return;

        if (oldPercent < 0)
            return;

        if (BatteryState.charging || BatteryState.full)
            return;

        if (newPercent < oldPercent) {
            for (let i = 0; i < thresholds.length; ++i) {
                const threshold = thresholds[i];

                if (oldPercent > threshold && newPercent <= threshold)
                    notificationFor(threshold);
            }
        }
    }

    Connections {
        target: BatteryState

        function onPercentChanged() {
            const current = BatteryState.percent;

            if (!BatteryState.present)
                return;

            if (!root.initialized) {
                root.previousPercent = current;
                root.initialized = true;
                return;
            }

            root.checkThresholds(root.previousPercent, current);
            root.previousPercent = current;
        }

        function onChargingChanged() {
            if (BatteryState.charging)
                root.previousPercent = BatteryState.percent;
        }
    }

    Timer {
        interval: 1000
        repeat: false
        running: true

        onTriggered: {
            if (BatteryState.present) {
                root.previousPercent = BatteryState.percent;
                root.initialized = true;
            }
        }
    }
}
