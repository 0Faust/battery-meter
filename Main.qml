import QtQuick
import Quickshell
import qs.services

// Background service: wires plugin settings into BatteryState thresholds.
Item {
    property var plugin

    onPluginChanged: _sync()
    function _sync() {
        if (!plugin) return;
        BatteryState.warnAt = plugin.get("warnAt", 20);
        BatteryState.critAt = plugin.get("critAt", 10);
    }

    Component.onCompleted: _sync()
}
