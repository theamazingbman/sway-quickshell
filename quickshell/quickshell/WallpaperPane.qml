import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper picker only. Wallpaper changes never alter the fixed shell palette.
Item {
    id: root
    required property var popup
    property var wallpapers: []
    property string applyingPath: ""
    property string currentWallpaper: ""
    property bool randomPending: false
    readonly property real thumbScale: popup.s * Screen.devicePixelRatio

    function shown() { lister.running = true; grid.forceActiveFocus() }
    function hidden() {}
    function openFolder() {
        Quickshell.execDetached(["xdg-open", Theme.confDir + "/wallpaper"])
        popup.visible = false
    }
    function applyRandom() { randomPending = true; lister.running = true }
    function apply(path) {
        if (!path) return
        applyingPath = path
        currentWallpaper = path
        Quickshell.execDetached([Theme.shareDir + "/scripts/wallpaper", path])
    }
    function placeCursor() {
        const name = currentWallpaper.split("/").pop()
        const i = wallpapers.findIndex(w => w.split("/").pop() === name)
        grid.currentIndex = i >= 0 ? i : wallpapers.length > 0 ? 0 : -1
    }
    property var _found: []
    Process {
        id: lister
        command: ["sh", "-c", "mkdir -p \"" + Theme.confDir + "/wallpaper\"; find -H \"" + Theme.confDir + "/wallpaper\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort"]
        stdout: SplitParser { onRead: line => { if (line.trim()) root._found.push(line.trim()) } }
        onRunningChanged: {
            if (running) root._found = []
            else {
                root.wallpapers = root._found
                if (root.randomPending) {
                    root.randomPending = false
                    if (root.wallpapers.length) root.apply(root.wallpapers[Math.floor(Math.random() * root.wallpapers.length)])
                }
                root.placeCursor()
            }
        }
    }
    Column {
        anchors.fill: parent
        spacing: 6
        Rectangle {
            width: parent.width; height: 32; radius: 6
            color: Qt.alpha(Theme.fg, 0.06)
            Row {
                anchors.centerIn: parent; spacing: 12
                Txt { text: "Wallpaper folder"; color: Theme.fg }
                Txt { text: "Open"; color: Theme.accent }
            }
            MouseArea { anchors.fill: parent; onClicked: root.openFolder() }
        }
        GridView {
            id: grid
            width: parent.width; height: parent.height - 38
            clip: true; cellWidth: 176; cellHeight: 103
            model: root.wallpapers
            focus: true; keyNavigationWraps: true
            onModelChanged: root.placeCursor()
            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_H: moveCurrentIndexLeft(); break
                case Qt.Key_L: moveCurrentIndexRight(); break
                case Qt.Key_K: moveCurrentIndexUp(); break
                case Qt.Key_J: moveCurrentIndexDown(); break
                case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
                    if (currentIndex >= 0) root.apply(root.wallpapers[currentIndex]); break
                case Qt.Key_O: root.openFolder(); break
                case Qt.Key_Escape: popup.visible = false; break
                default: event.accepted = false; return
                }
                event.accepted = true
            }
            delegate: Item {
                required property string modelData
                width: grid.cellWidth; height: grid.cellHeight
                Rectangle {
                    anchors.fill: parent; anchors.margins: 4; radius: 6
                    color: Qt.alpha(Theme.fg, 0.06)
                    Image {
                        anchors.fill: parent; anchors.margins: 1
                        source: "file://" + modelData
                        sourceSize: Qt.size(grid.cellWidth * root.thumbScale, grid.cellHeight * root.thumbScale)
                        fillMode: Image.PreserveAspectCrop; asynchronous: true
                    }
                    Rectangle {
                        anchors.fill: parent; radius: 6; color: "transparent"
                        border.width: modelData === root.currentWallpaper || GridView.isCurrentItem ? 2 : 0
                        border.color: Theme.accent
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.apply(modelData) }
                }
            }
        }
    }
}
