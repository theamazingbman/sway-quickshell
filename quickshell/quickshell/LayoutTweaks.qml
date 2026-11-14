import QtQuick

// The layout grid and the live tweaks (gap, border, split, floating,
// smart gaps), as a column for the settings panel's Layout tab. The grid
// shows the layout around the focused window of the output the panel is
// on; a tile applies there (sway's `layout`). Gap and border persist to
// the state folder's tweaks.conf, which sway's config includes.
Column {
    id: root
    readonly property string mon: Wm.monitor
    spacing: 6

    SectionLabel { text: "Layout" }

    Grid {
        id: layoutGrid
        width: parent.width
        columns: 3
        spacing: 4

        Repeater {
            model: Wm.layouts

            Rectangle {
                id: tile
                required property var modelData
                required property int index
                readonly property bool current: Wm.of(root.mon).layoutIndex === index

                width: (layoutGrid.width - 8) / 3
                height: 52
                radius: 8
                color: current ? Theme.selbg
                     : tileMa.containsMouse ? Qt.alpha(Theme.fg, 0.12)
                     : Qt.alpha(Theme.fg, 0.04)

                Behavior on color { ColorAnimation { duration: 120 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.glyph
                        color: tile.current ? Theme.selfg : Theme.cyan
                        font.pixelSize: 18
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.name
                        color: tile.current ? Theme.selfg : Qt.alpha(Theme.fg, 0.8)
                        font.pixelSize: 10
                        font.bold: tile.current
                    }
                }

                MouseArea {
                    id: tileMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Wm.setLayout(tile.index, root.mon)
                }
            }
        }
    }

    // the focused window: split direction and floating, as in your keys
    Grid {
        id: winGrid
        width: parent.width
        columns: 3
        spacing: 4

        Repeater {
            model: [
                { icon: "󰤼", label: "Toggle split", active: false,
                  run: () => Wm.toggleSplit(root.mon) },
                { icon: "󰖲", label: "Float", active: false,
                  run: () => Wm.toggleFloating() },
                { icon: "󰆟", label: "Smart gaps", active: Wm.smartGaps,
                  run: () => Wm.setSmartGaps(!Wm.smartGaps) }
            ]
            TogglePill { width: (winGrid.width - 8) / 3 }
        }
    }

    SectionLabel { text: "Desktop" }

    TweakSlider {
        label: "window gap"
        from: 0; to: 40
        value: Wm.gaps
        suffix: " px"
        applyFn: v => Wm.setGaps(v)
        persistFn: v => Wm.persistTweaks()
    }
    TweakSlider {
        label: "border width"
        from: 0; to: 6
        value: Wm.borderpx
        suffix: " px"
        applyFn: v => Wm.setBorder(v)
        persistFn: v => Wm.persistTweaks()
    }
}
