pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Battery state: reads /sys/class/power_supply/BAT* every 15s.
// Discovers the first available battery automatically.
Singleton {
    id: root

    // ---- Public API ----
    readonly property int    percent:   _pct           // 0..100
    readonly property string status:    _status        // "Charging" | "Discharging" | "Full" | "Unknown"
    readonly property bool   charging:  _status === "Charging"
    readonly property bool   full:      _status === "Full" || _pct >= 99
    readonly property bool   present:   _bat !== ""
    readonly property real   watt:      _watt          // current power draw / charge rate, W
    readonly property int    minutesLeft: _min         // estimated time remaining (0 = unknown)

    // Thresholds (overrideable from Settings)
    property int warnAt:     20   // warn below this %
    property int critAt:     10   // critical below this %

    readonly property string stateLabel: {
        if (!present)      return I18n.t("нет батареи",   "No battery");
        if (full)          return I18n.t("заряжено ♡",    "Full ♡");
        if (charging)      return I18n.t("заряжается",    "Charging");
        if (_min > 0) {
            const h = Math.floor(_min / 60);
            const m = _min % 60;
            return h > 0 ? h + I18n.t(" ч ", " h ") + m + I18n.t(" мин", " min")
                         : m + I18n.t(" мин", " min");
        }
        return I18n.t("разряжается", "Discharging");
    }

    readonly property string icon: {
        if (!present)   return "batteryUnknown";
        if (charging)   return "batteryCharging";
        if (full)       return "batteryFull";
        if (_pct >= 80) return "batteryFull";
        if (_pct >= 50) return "batteryHalf";
        if (_pct >= 20) return "batteryLow";
        return "batteryEmpty";
    }

    // ---- Internals ----
    property string _bat:    ""      // e.g. "BAT1"
    property int    _pct:    0
    property string _status: "Unknown"
    property real   _watt:   0
    property int    _min:    0

    // Find first available battery in /sys/class/power_supply/
    Process {
        id: finder
        command: ["sh", "-c",
            "for d in /sys/class/power_supply/BAT* /sys/class/power_supply/bat*; do [ -f \"$d/capacity\" ] && basename \"$d\" && exit; done; echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const b = text.trim();
                root._bat = b;
                if (b) poller.running = true;
            }
        }
        stderr: StdioCollector {}
        Component.onCompleted: running = true
    }

    // Poll /sys files directly — no external process, instant & lightweight.
    Timer {
        id: poller
        interval: 15000
        running: false
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root._bat) return;
            capView.reload();
            statusView.reload();
            energyNowView.reload();
            energyFullView.reload();
            powerNowView.reload();
        }
    }

    FileView {
        id: capView
        path: root._bat ? "/sys/class/power_supply/" + root._bat + "/capacity" : ""
        onLoaded: {
            const v = parseInt(text().trim());
            if (!isNaN(v)) root._pct = Math.max(0, Math.min(100, v));
        }
        onLoadFailed: {}
    }
    FileView {
        id: statusView
        path: root._bat ? "/sys/class/power_supply/" + root._bat + "/status" : ""
        onLoaded: root._status = text().trim() || "Unknown"
        onLoadFailed: {}
    }
    FileView {
        id: energyNowView
        path: root._bat ? "/sys/class/power_supply/" + root._bat + "/energy_now" : ""
        onLoaded: root._energyNow = parseInt(text().trim()) || 0
        onLoadFailed: {}
        property int value: 0
    }
    FileView {
        id: energyFullView
        path: root._bat ? "/sys/class/power_supply/" + root._bat + "/energy_full" : ""
        onLoaded: root._energyFull = parseInt(text().trim()) || 0
        onLoadFailed: {}
        property int value: 0
    }
    FileView {
        id: powerNowView
        path: root._bat ? "/sys/class/power_supply/" + root._bat + "/power_now" : ""
        onLoaded: {
            const uw = parseInt(text().trim());
            root._watt = isNaN(uw) || uw === 0 ? 0 : Math.round(uw / 1000) / 1000;
            _recalcTime();
        }
        onLoadFailed: { root._watt = 0; }
    }

    property int _energyNow:  0
    property int _energyFull: 0

    function _recalcTime() {
        if (_watt <= 0 || _energyFull <= 0) { _min = 0; return; }
        const ew = _energyNow / 1e6;   // µWh → Wh
        const fw = _energyFull / 1e6;
        const w  = _watt;
        if (charging) {
            _min = Math.round((fw - ew) / w * 60);
        } else {
            _min = Math.round(ew / w * 60);
        }
        if (_min < 0 || _min > 1440) _min = 0;
    }
}
