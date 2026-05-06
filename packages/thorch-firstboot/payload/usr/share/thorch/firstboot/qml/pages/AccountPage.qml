import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

SetupPage {
    id: page

    required property var flow
    required property int optionMaxWidth

    title: qsTr("Create Your Account")
    description: qsTr("Use this password for your account and for recovery/admin prompts.")
    bodySpacing: 20

    TextField {
        placeholderText: qsTr("Username")
        text: page.flow.username
        font.pixelSize: 20
        Layout.maximumWidth: page.optionMaxWidth
        Layout.fillWidth: true
        onTextChanged: page.flow.username = text
    }

    TextField {
        placeholderText: qsTr("Password")
        echoMode: TextInput.Password
        text: page.flow.password
        font.pixelSize: 20
        Layout.maximumWidth: page.optionMaxWidth
        Layout.fillWidth: true
        onTextChanged: page.flow.password = text
    }

    TextField {
        placeholderText: qsTr("Confirm password")
        echoMode: TextInput.Password
        text: page.flow.confirmPassword
        font.pixelSize: 20
        Layout.maximumWidth: page.optionMaxWidth
        Layout.fillWidth: true
        onTextChanged: page.flow.confirmPassword = text
    }

    Label {
        visible: !page.flow.validUsername()
        text: qsTr("Use lowercase letters, numbers, hyphen, or underscore.")
        color: "#ffb84d"
        font.pixelSize: 15
    }

    Label {
        visible: page.flow.password.length > 0 && page.flow.confirmPassword.length > 0 && page.flow.password !== page.flow.confirmPassword
        text: qsTr("The passwords do not match yet.")
        color: "#ffb84d"
        font.pixelSize: 15
    }
}
