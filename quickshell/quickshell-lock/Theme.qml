pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Fixed palette shared by the Quickshell network app and lock screen.
Singleton {
    id: root

    // the bar's state folder, where popup-scale lives
    readonly property string stateDir: {
        const env = String(Quickshell.env("XDG_STATE_HOME") ?? "")
        const base = env !== "" ? env : String(Quickshell.env("HOME") ?? "") + "/.local/state"
        return base + "/sway-min03"
    }

    property color bg: "#000000"
    property color fg: "#d0d7de"
    property color accent: "#7dc4e4"
    property color green: "#a6da95"
    property color alert: "#ed8796"
    property color disabled: "#6e6d6d"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // the bar's popup scale, read from the same file
    property real popupScale: 1.0

    FileView {
        path: root.stateDir + "/popup-scale"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: root.popupScale = 1.0
        onLoaded: {
            const v = parseFloat(text())
            root.popupScale = isNaN(v) ? 1.0 : Math.min(Math.max(v, 0.8), 2.0)
        }
    }

}
