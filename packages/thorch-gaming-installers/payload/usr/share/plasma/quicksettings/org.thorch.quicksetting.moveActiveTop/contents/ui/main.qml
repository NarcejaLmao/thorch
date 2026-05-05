// SPDX-FileCopyrightText: 2026 Thorch contributors
// SPDX-License-Identifier: GPL-2.0-or-later

import org.kde.plasma.private.mobileshell.quicksettingsplugin as QS
import org.kde.plasma.plasma5support 2.0 as P5Support

QS.QuickSetting {
    id: root

    text: i18n("Move Active Up")
    status: running ? i18n("Moving window") : i18n("Active window to top")
    icon: "go-up"
    enabled: false

    property bool running: false

    function toggle() {
        if (running) {
            return;
        }
        running = true;
        actionSource.connectSource("/usr/bin/thorch-steamos-mode move-active-top");
    }

    P5Support.DataSource {
        id: actionSource
        engine: "executable"

        onNewData: sourceName => {
            disconnectSource(sourceName);
            root.running = false;
        }
    }
}
