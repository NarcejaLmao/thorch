// SPDX-FileCopyrightText: 2026 Thorch contributors
// SPDX-License-Identifier: GPL-2.0-or-later

import org.kde.plasma.private.mobileshell.quicksettingsplugin as QS
import org.kde.plasma.plasma5support 2.0 as P5Support

QS.QuickSetting {
    id: root

    text: i18n("Move Steam Up")
    status: running ? i18n("Moving Steam") : i18n("Steam to top screen")
    icon: "go-top"
    enabled: false

    property bool running: false

    function toggle() {
        if (running) {
            return;
        }
        running = true;
        actionSource.connectSource("/usr/bin/thorch-steamos-mode move-steam-top");
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
