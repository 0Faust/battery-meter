import QtQuick
import Quickshell
import qs.services

// Background service: wires plugin settings into BatteryState thresholds
// and owns low-battery notifications.
Item {
    id: root

    property var plugin

    BatteryNotifications {
        plugin: root.plugin
    }

    onPluginChanged: _sync()

    function _sync() {
        if (!plugin)
            return;

        BatteryState.warnAt = plugin.get("warnAt", 20);
        BatteryState.critAt = plugin.get("critAt", 10);
    }

    Component.onCompleted: _sync()
}
