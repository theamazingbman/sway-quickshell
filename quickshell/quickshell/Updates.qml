import QtQuick
import Quickshell

// Fedora update action. Middle click refreshes the update count.
BarModule {
    id: root
    visible: UpdateCount.count > 0
    icon: "󰚰"
    iconColor: Theme.accent
    label: String(UpdateCount.count)
    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) UpdateCount.check()
        else Quickshell.execDetached(["foot", "-e", "sh", "-lc", "sudo dnf upgrade --refresh; printf '\nDone. Press Enter to close.'; read _"])
    }
}
