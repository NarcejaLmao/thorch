import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string message
    required property string checkboxText
    property bool checked: false
    signal acceptedChanged(bool accepted)

    spacing: 12

    Label {
        text: root.message
        color: "#ffb84d"
        font.pixelSize: 16
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    CheckBox {
        text: root.checkboxText
        checked: root.checked
        font.pixelSize: 17
        palette.windowText: "#f6fafc"
        palette.text: "#f6fafc"
        palette.buttonText: "#f6fafc"
        onToggled: root.acceptedChanged(checked)
    }
}
