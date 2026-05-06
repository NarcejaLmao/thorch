// SPDX-FileCopyrightText: 2026 Thorch contributors
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.15
import org.kde.plasma.private.mobileshell.quicksettingsplugin as QS
import org.kde.plasma.plasma5support 2.0 as P5Support

QS.QuickSetting {
    id: root

    text: i18n("USB Gadget")
    status: actionRunning ? (serviceRunning ? i18n("Turning USB off") : i18n("Turning USB on"))
                          : (serviceRunning ? i18n("USB gadget is on") : i18n("USB gadget is off"))
    icon: "drive-removable-media-usb"
    enabled: serviceRunning

    property bool actionRunning: false
    property bool serviceRunning: false
    readonly property string helperCommand: "/usr/bin/thorch-quicksetting-toggle usb"

    function refreshState() {
        statusSource.connectSource(helperCommand + " status");
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
            if (data.stdout !== undefined) {
                root.serviceRunning = data.stdout.trim() === "on";
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
