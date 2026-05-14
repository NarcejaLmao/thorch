// SPDX-FileCopyrightText: 2026 Thorch contributors
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import org.kde.plasma.private.mobileshell.quicksettingsplugin as QS
import org.kde.plasma.plasma5support 2.0 as P5Support

QS.QuickSetting {
    id: root

    text: i18n("RGB")
    status: actionRunning ? (rgbEnabled ? i18n("Turning RGB off") : i18n("Restoring RGB"))
                          : idleStatus
    icon: "preferences-color"
    enabled: rgbEnabled

    property bool actionRunning: false
    property bool rgbEnabled: false
    property string rgbMode: "off"
    property string rgbStaticHex: "#0080FF"
    readonly property string helperCommand: "thorch-quicksetting-toggle rgb"
    readonly property string statusCommand: "thorch-hardwarectl status-json"
    readonly property string idleStatus: {
        if (rgbMode === "battery") {
            return i18n("Battery status");
        }
        if (rgbMode === "static") {
            return i18n("Static %1").arg(rgbStaticHex);
        }
        return i18n("Off");
    }

    function refreshState() {
        statusSource.connectSource(statusCommand);
    }

    function toggle() {
        if (actionRunning) {
            return;
        }
        actionRunning = true;
        actionSource.connectSource(helperCommand + " toggle");
    }

    P5Support.DataSource {
        id: statusSource
        engine: "executable"

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            if (data.stdout !== undefined && data.stdout.trim().length > 0) {
                try {
                    const payload = JSON.parse(data.stdout.trim());
                    root.rgbMode = payload.rgb_mode || "off";
                    root.rgbEnabled = payload.rgb_enabled === true;
                    root.rgbStaticHex = payload.rgb_static_hex || "#0080FF";
                } catch (error) {
                    root.rgbMode = "off";
                    root.rgbEnabled = false;
                    root.rgbStaticHex = "#0080FF";
                }
            }
        }
    }

    P5Support.DataSource {
        id: actionSource
        engine: "executable"

        onNewData: sourceName => {
            disconnectSource(sourceName);
            root.actionRunning = false;
            refreshAfterAction.restart();
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshState()
    }

    Timer {
        id: refreshAfterAction
        interval: 1000
        repeat: false
        onTriggered: root.refreshState()
    }
}
