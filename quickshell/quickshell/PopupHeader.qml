import QtQuick

// The top of a drop-down: a tile with the popup's glyph, a title and one
// dimmer line under it, and whatever is declared inside (a button, a
// toggle) at the right edge.
Item {
    id: head
    property string glyph: ""
    property color glyphColor: Theme.cyan
    property string title: ""
    property string subtitle: ""
    property color subtitleColor: Qt.alpha(Theme.fg, 0.55)
    default property alias actions: slot.data

    width: parent.width
    height: 48

    Rectangle {
        id: tile
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 44
        radius: 8
        color: Qt.alpha(Theme.fg, 0.06)

        Txt {
            anchors.centerIn: parent
            text: head.glyph
            color: head.glyphColor
            font.pixelSize: 22
        }
    }

    Column {
        anchors.left: tile.right
        anchors.leftMargin: 12
        anchors.right: slot.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Txt {
            width: parent.width
            text: head.title
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
        }
        Txt {
            width: parent.width
            visible: text !== ""
            text: head.subtitle
            color: head.subtitleColor
            elide: Text.ElideRight
        }
    }

    Row {
        id: slot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
    }
}
