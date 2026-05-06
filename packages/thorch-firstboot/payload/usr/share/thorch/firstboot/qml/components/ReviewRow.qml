import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    required property string label
    required property string value

    spacing: 24
    Layout.fillWidth: true

    Label {
        text: root.label
        color: "#89a0aa"
        font.pixelSize: 16
        Layout.preferredWidth: 110
    }

    Label {
        text: root.value
        color: "#f6fafc"
        font.pixelSize: 18
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
