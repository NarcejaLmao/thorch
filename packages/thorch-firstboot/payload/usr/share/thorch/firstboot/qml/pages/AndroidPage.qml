import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

SetupPage {
    id: page

    required property var flow
    required property int optionMaxWidth

    title: qsTr("Android Apps")
    description: page.flow.hasNetwork()
        ? qsTr("Install Waydroid during setup to run Android apps from Plasma.")
        : qsTr("Connect to Wi-Fi first to install Waydroid during setup, or install it later from the app launcher.")

    ColumnLayout {
        spacing: 14
        Layout.maximumWidth: page.optionMaxWidth

        ChoiceRow {
            text: qsTr("Install Waydroid during setup")
            checked: page.flow.installWaydroid
            enabled: page.flow.hasNetwork()
            onClicked: {
                page.flow.installWaydroid = true;
                page.flow.waydroidChoiceTouched = true;
            }
        }

        ChoiceRow {
            text: qsTr("Install later")
            checked: !page.flow.installWaydroid
            onClicked: {
                page.flow.installWaydroid = false;
                page.flow.waydroidChoiceTouched = true;
            }
        }
    }

    Label {
        text: page.flow.hasNetwork()
            ? qsTr("The installer downloads Waydroid and vanilla Android images after your account is created.")
            : qsTr("You can install Waydroid later from the app launcher after connecting to Wi-Fi.")
        color: "#89a0aa"
        font.pixelSize: 16
        wrapMode: Text.WordWrap
        Layout.maximumWidth: page.optionMaxWidth
        Layout.fillWidth: true
    }
}
