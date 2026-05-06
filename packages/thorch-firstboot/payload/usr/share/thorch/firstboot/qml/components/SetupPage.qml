import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    required property int pageWidth
    property int padX: 42
    property int padTop: 34
    property int padBottom: 26
    property int bodySpacing: 20
    property string title: ""
    property string description: ""
    default property alias content: body.data

    clip: true
    leftPadding: padX
    rightPadding: padX
    topPadding: padTop
    bottomPadding: padBottom
    contentWidth: availableWidth
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
        id: body

        width: root.pageWidth
        spacing: root.bodySpacing

        Label {
            text: root.title
            color: "#f6fafc"
            font.pixelSize: 30
            font.bold: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Label {
            visible: root.description.length > 0
            text: root.description
            color: "#b8c7ce"
            font.pixelSize: 18
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
