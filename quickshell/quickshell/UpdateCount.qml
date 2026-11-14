pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Count available Fedora updates without root privileges.
Singleton {
    id: root
    property int count: 0
    function check() { proc.running = true }
    Process {
        id: proc
        command: ["sh", "-c", "dnf -q check-update 2>/dev/null | awk 'NF >= 3 && $1 !~ /^(Last|Obsoleting)/ {n++} END {print n+0}'"]
        stdout: StdioCollector { onStreamFinished: root.count = parseInt(text.trim()) || 0 }
    }
    Timer { interval: 3600000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.check() }
    Connections {
        target: BarIpc
        function onCall(target, fn, arg) { if (target === "updates" && fn === "check") root.check() }
    }
}
