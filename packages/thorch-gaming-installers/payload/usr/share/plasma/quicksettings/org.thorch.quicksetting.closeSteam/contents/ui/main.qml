// SPDX-FileCopyrightText: 2026 Thorch contributors
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import org.kde.plasma.private.mobileshell.quicksettingsplugin as QS
import org.kde.plasma.plasma5support 2.0 as P5Support

QS.QuickSetting {
    id: root

    text: steamRunning ? i18n("Close Steam") : i18n("Open Steam")
    status: actionRunning ? (steamRunning ? i18n("Closing Steam") : i18n("Opening Steam"))
                          : (steamRunning ? i18n("Steam is open") : i18n("Steam is closed"))
    icon: steamRunning ? "process-stop" : "steam"
    enabled: steamRunning

    property bool actionRunning: false
    property bool steamRunning: false

    function refreshSteamState() {
        statusSource.connectSource("/usr/bin/thorch-steamos-mode is-running");
    }

    function toggle() {
        if (actionRunning) {
            return;
        }
        actionRunning = true;
        actionSource.connectSource("/usr/bin/thorch-steamos-mode " + (steamRunning ? "stop" : "start"));
    }

    P5Support.DataSource {
        id: statusSource
        engine: "executable"

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            if (data.stdout !== undefined) {
                root.steamRunning = data.stdout.trim() === "running";
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
        onTriggered: root.refreshSteamState()
    }

    Timer {
        id: refreshAfterAction
        interval: 1000
        repeat: false
        onTriggered: root.refreshSteamState()
    }
}
