import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

SetupPage {
    id: page

    required property var flow
    required property int optionMaxWidth

    title: qsTr("Connect to Wi-Fi")
    description: qsTr("You can skip this for now, but Wi-Fi is recommended before installing Steam, Waydroid, or updates.")
    bodySpacing: 20

    RowLayout {
        spacing: 12

        Button {
            text: page.flow.wifiScanning ? qsTr("Scanning") : qsTr("Scan")
            icon.name: "view-refresh"
            enabled: !page.flow.wifiScanning && !page.flow.wifiConnecting
            onClicked: {
                page.flow.wifiScanning = true;
                page.flow.wifiMessage = qsTr("Looking for Wi-Fi networks...");
                page.flow.backend.scanWifi();
            }
        }

        BusyIndicator {
            running: page.flow.wifiScanning || page.flow.wifiConnecting
            visible: running
        }
    }

    Label {
        text: page.flow.wifiMessage
        color: "#89a0aa"
        font.pixelSize: 15
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    ColumnLayout {
        spacing: 10
        Layout.maximumWidth: page.optionMaxWidth
        visible: page.flow.wifiNetworks.length > 0

        Repeater {
            model: page.flow.wifiNetworks

            ChoiceRow {
                text: page.flow.wifiLabel(modelData)
                checked: page.flow.wifiSelectedIndex === index
                onClicked: page.flow.selectWifiNetwork(index)
            }
        }
    }

    TextField {
        placeholderText: !page.flow.selectedWifiSsid()
            ? qsTr("Wi-Fi password")
            : (page.flow.selectedWifiRequiresPassword()
                ? qsTr("Wi-Fi password for %1").arg(page.flow.selectedWifiSsid())
                : qsTr("No password needed for %1").arg(page.flow.selectedWifiSsid()))
        echoMode: TextInput.Password
        text: page.flow.wifiPassword
        font.pixelSize: 20
        enabled: page.flow.selectedWifiRequiresPassword() && !page.flow.wifiConnecting
        Layout.maximumWidth: page.optionMaxWidth
        Layout.fillWidth: true
        onTextChanged: page.flow.wifiPassword = text
    }

    Label {
        text: qsTr("Enter the Wi-Fi password to connect.")
        color: "#89a0aa"
        font.pixelSize: 14
        visible: page.flow.selectedWifiRequiresPassword() && page.flow.wifiPassword.length === 0
        Layout.maximumWidth: page.optionMaxWidth
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    Button {
        text: page.flow.wifiConnecting ? qsTr("Connecting") : qsTr("Connect")
        icon.name: "network-wireless"
        enabled: page.flow.canConnectSelectedWifi()
        onClicked: {
            page.flow.wifiConnecting = true;
            page.flow.wifiMessage = qsTr("Connecting to %1...").arg(page.flow.selectedWifiSsid());
            page.flow.backend.connectWifi(
                page.flow.selectedWifiSsid(),
                page.flow.wifiPassword,
                page.flow.selectedWifiSecurity()
            );
        }
    }
}
