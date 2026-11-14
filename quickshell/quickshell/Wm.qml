pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Workspace state + control — sway backend. `swaymsg -t subscribe`
// streams workspace, window and output events; each burst schedules one
// debounced get_tree, and the walk of that tree is the whole read side:
// which workspaces each output has, which hold windows, the focused
// window per output, the layout around it, the apps on each workspace.
// Commands go through swaymsg. scripts/sway-ipc finds sway's socket when
// the bar was started outside sway's environment.
Singleton {
    id: root

    property string monitor: ""     // focused output name (command target)
    // FileView watching a file, re-read whenever it changes
    component StateFile: FileView { watchChanges: true; onFileChanged: reload() }

    // Each output shows its own block of the twelve workspaces, the same
    // split scripts/monitor-workspaces applies (1-6 and 7-12 on two): bit
    // n of seltags/occtags/urgtags is workspace first + n + 1 there. With
    // one output, or pins of the user's own, every output shows all twelve.
    readonly property int count: 12
    // name -> {first, seltags, occtags, urgtags, tagCount, title, appid,
    // layoutIndex, ws (the visible one), tiledId/floatId (its focused
    // tiled / floating window, 0 for none)}
    property var mons: ({})
    readonly property var _none: ({ first: 0, seltags: 1, occtags: 0, urgtags: 0, tagCount: 12, title: "", appid: "", layoutIndex: 0, ws: 0, tiledId: 0, floatId: 0 })
    function of(name) { return mons[name] ?? mons[monitor] ?? _none }
    property bool identifyOutputs: false   // Displays card: name on every screen

    readonly property string ipc: Theme.shareDir + "/scripts/sway-ipc"
    // sway sends no event for some changes (a container's layout), so a
    // command of the bar's own is followed by a read of the tree
    function dispatch(cmd) {
        Quickshell.execDetached([ipc, cmd])
        afterCommand.restart()
    }

    // --- layouts: sway's four container layouts. tree is what get_tree
    // reports, id what `layout` takes. mfact/nmaster: none honors them. ---
    readonly property var layouts: [
        { name: "split h",  id: "splith",   tree: "splith",  glyph: "󰯌", mfact: false, nmaster: false },
        { name: "split v",  id: "splitv",   tree: "splitv",  glyph: "󰯋", mfact: false, nmaster: false },
        { name: "tabbed",   id: "tabbed",   tree: "tabbed",  glyph: "󰓩", mfact: false, nmaster: false },
        { name: "stacking", id: "stacking", tree: "stacked", glyph: "󰕪", mfact: false, nmaster: false }
    ]
    // `layout` acts on the focused window and refuses a floating one (the
    // Settings window, when the Layout tab is clicked), so it goes to the
    // output's tiled window by id; on a workspace with none, to the
    // workspace itself, focus handed back to a floating window after
    function setLayout(i, mon) {
        const st = of(mon), cmd = "layout " + layouts[i].id
        if (st.tiledId) dispatch("[con_id=" + st.tiledId + "] " + cmd)
        else if (st.floatId) dispatch("[con_id=" + st.floatId + "] focus; focus parent; " + cmd + "; [con_id=" + st.floatId + "] focus")
        else if (st.ws > 0) dispatch("workspace number " + st.ws + "; " + cmd)
    }
    function cycleLayout(dir, mon) {
        setLayout(((of(mon).layoutIndex + dir) % layouts.length + layouts.length) % layouts.length, mon)
    }
    function toggleSplit(mon) {
        const st = of(mon)
        if (st.tiledId) dispatch("[con_id=" + st.tiledId + "] layout toggle split")
    }
    function toggleFloating() { dispatch("floating toggle") }

    // --- desktop tweaks, kept in the state folder's tweaks.conf, which
    // defaults.conf includes: a reload keeps them with nothing to re-apply.
    // Sliders apply live and persist on release. ---
    property int gaps: 5
    property int borderpx: 2
    property bool smartGaps: false
    property bool tweaksLoaded: false
    function persistTweaks() {
        Theme.writeState("tweaks.conf", [
            "# written by the bar's Layout tab; defaults.conf includes it",
            "gaps inner " + gaps,
            "gaps outer " + Theme.edgeInset,
            "default_border pixel " + borderpx,
            "default_floating_border pixel " + borderpx,
            "smart_gaps " + (smartGaps ? "on" : "off")
        ].join("\n"))
    }
    StateFile {
        path: Theme.stateDir + "/tweaks.conf"
        onLoaded: {
            for (const line of text().split("\n")) {
                const m = line.trim().match(/^(gaps inner|default_border pixel|smart_gaps)\s+(\S+)/)
                if (!m) continue
                if (m[1] === "gaps inner") root.gaps = parseInt(m[2]) || 0
                else if (m[1] === "default_border pixel") root.borderpx = parseInt(m[2]) || 0
                else root.smartGaps = m[2] === "on"
            }
            root.tweaksLoaded = true
            root.applyOuterGaps()
        }
        // none yet: one from the values above
        onLoadFailed: { root.tweaksLoaded = true; root.persistTweaks(); root.applyOuterGaps() }
    }
    // "window gap" = inner gaps
    function applyGaps(v) { dispatch("gaps inner all set " + v) }
    function setGaps(v) { gaps = v; applyGaps(v) }
    // outer gaps = the bar's edge inset (Theme.edgeInset, scaled to the
    // screen), so windows float off the edges exactly like the bar does
    function applyOuterGaps() { dispatch("gaps outer all set " + Theme.edgeInset) }
    Connections {
        target: Theme
        function onEdgeInsetChanged() {
            root.applyOuterGaps()
            if (root.tweaksLoaded) root.persistTweaks()
        }
    }
    function setBorder(v) {
        borderpx = v
        dispatch("default_border pixel " + v + "; default_floating_border pixel " + v + "; [all] border pixel " + v)
    }
    function setSmartGaps(on) {
        smartGaps = on
        dispatch("smart_gaps " + (on ? "on" : "off"))
        persistTweaks()
    }
    // called by shell.qml's "wm" handler, as the other setups' are: nothing to
    // re-apply on sway, the included tweaks.conf survives a reload
    function applyEffects() {}

    // --- state stream ---

    Process {
        id: events
        // binding: a key that changed a layout says so only through it
        command: [root.ipc, "-r", "-t", "subscribe", "-m", "[\"workspace\",\"window\",\"output\",\"binding\"]"]
        running: true
        stdout: SplitParser {
            onRead: line => treeSettle.restart()
        }
        // sway restart / socket gone: come back on our own
        onExited: eventsRetry.restart()
        onRunningChanged: if (running) treeSettle.restart()
    }
    Timer {
        id: eventsRetry
        interval: 2000
        onTriggered: events.running = true
    }
    Timer {
        id: afterCommand
        interval: 80
        onTriggered: treeSettle.restart()
    }
    // a workspace switch is a burst of events; read the tree once after it
    Timer {
        id: treeSettle
        interval: 40
        onTriggered: { tree.running = false; tree.running = true }
    }
    Process {
        id: tree
        command: [root.ipc, "-r", "-t", "get_tree"]
        stdout: StdioCollector {
            onStreamFinished: root.parseTree(text)
        }
    }

    // pins of the user's own (`workspace N output NAME` in local.conf) turn
    // the split off, here as in scripts/monitor-workspaces
    property bool pinned: false
    StateFile {
        path: Theme.confDir + "/local.conf"
        onLoaded: root.pinned = /^[ \t]*workspace[ \t]+.*[ \t]output[ \t]/m.test(text())
        onLoadFailed: root.pinned = false
    }
    onPinnedChanged: treeSettle.restart()

    // the outputs in monitor-workspaces' order: a laptop's own panel
    // first, then left to right
    function ordered(outs) {
        const internal = o => /^(eDP|LVDS|DSI)-/.test(o.name) ? 0 : 1
        return outs.slice().sort((a, b) => internal(a) - internal(b)
            || a.rect.x - b.rect.x || a.rect.y - b.rect.y)
    }
    function windowsIn(node, out) {
        const kids = (node.nodes ?? []).concat(node.floating_nodes ?? [])
        if (kids.length === 0 && node.type !== "workspace") { out.push(node); return }
        for (const k of kids) windowsIn(k, out)
    }
    // the focused leaf under node, following each container's focus order
    // (tiled ones only, with floating false), and the layout of the
    // container that holds it
    function focusedLeaf(node, parentLayout, floating) {
        const kids = (node.nodes ?? []).concat(floating ? (node.floating_nodes ?? []) : [])
        if (kids.length === 0) return { node: node, layout: parentLayout }
        const order = node.focus ?? []
        const next = order.map(id => kids.find(k => k.id === id)).find(k => k) ?? kids[0]
        return focusedLeaf(next, node.layout ?? parentLayout, floating)
    }
    function appOf(w) { return w.app_id ?? w.window_properties?.class ?? "" }

    function parseTree(t) {
        let j
        try { j = JSON.parse(t) } catch (e) { return }
        const outs = ordered((j.nodes ?? []).filter(o => o.type === "output" && o.name !== "__i3"))
        if (outs.length === 0) return
        const split = outs.length > 1 && !pinned
        const next = {}, apps = {}
        let focusedOut = ""
        outs.forEach((o, oi) => {
            // this output's block: the workspaces monitor-workspaces gives it
            let first = 0, n = count
            if (split) {
                first = Math.ceil(oi * count / outs.length)
                n = Math.ceil((oi + 1) * count / outs.length) - first
            }
            let sel = 0, occ = 0, urg = 0
            const perTag = {}
            const wss = (o.nodes ?? []).filter(w => w.type === "workspace")
            const visibleId = (o.focus ?? [])[0]
            let title = "", appid = "", layout = "splith", ws = 0, tiledId = 0, floatId = 0
            for (const w of wss) {
                const i = (w.num ?? -1) - 1 - first
                const wins = []
                windowsIn(w, wins)
                if (w.id === visibleId) {
                    ws = w.num ?? 0
                    const leaf = focusedLeaf(w, w.layout, true)
                    if (leaf.node.type !== "workspace") {
                        title = leaf.node.name ?? ""
                        appid = appOf(leaf.node)
                        if (leaf.node.type === "floating_con") floatId = leaf.node.id
                    }
                    // the layout shown is the tiled windows', floating focus or not
                    const tiled = focusedLeaf(w, w.layout, false)
                    if (tiled.node.type !== "workspace") { tiledId = tiled.node.id; layout = tiled.layout }
                    else layout = w.layout ?? "splith"
                }
                if (w.focused || wins.some(x => x.focused)) focusedOut = o.name
                if (i < 0 || i >= n) continue
                const bit = 1 << i
                if (w.id === visibleId) sel |= bit
                if (wins.length > 0) occ |= bit
                if (w.urgent) urg |= bit
                if (Theme.tagIcons) {
                    const list = perTag[i] = []
                    for (const x of wins) {
                        const a = appOf(x)
                        const hit = list.find(e => e.appid === a)
                        if (hit) hit.count++
                        else list.push({ appid: a, icon: appIcon(a), count: 1 })
                    }
                }
            }
            const li = layouts.findIndex(l => l.tree === layout)
            next[o.name] = {
                first: first, seltags: sel, occtags: occ, urgtags: urg, tagCount: n,
                title: title, appid: appid, layoutIndex: li >= 0 ? li : 0,
                ws: ws, tiledId: tiledId, floatId: floatId
            }
            apps[o.name] = perTag
        })
        mons = next
        if (Theme.tagIcons) {
            const json = JSON.stringify(apps)
            if (json !== _tagAppsJson) { _tagAppsJson = json; tagApps = apps }
        }
        monitor = focusedOut || (outs.find(o => o.focused)?.name ?? outs[0].name)
    }

    // --- which apps sit on which workspace (the Tags strip's icons) ---
    property var tagApps: ({})   // output name -> tag index -> [{appid, icon, count}]
    property string _tagAppsJson: ""   // the last snapshot: an unchanged one is skipped
    property var _iconCache: ({})
    function appIcon(appid) {
        if (_iconCache[appid] !== undefined) return _iconCache[appid]
        const entry = DesktopEntries.heuristicLookup(appid)
        const icon = entry?.icon ? Quickshell.iconPath(entry.icon, "application-x-executable") : ""
        _iconCache[appid] = icon
        return icon
    }
    Connections {
        target: Theme
        function onTagIconsChanged() {
            if (!Theme.tagIcons) { root.tagApps = ({}); root._tagAppsJson = "" }
            treeSettle.restart()
        }
    }

    // --- actions ---

    // A bar acts on its own output: focus it first when it is not the
    // focused one, in the same command so the two stay in order.
    function elsewhere(mon) { return mon !== undefined && mon !== "" && mon !== monitor }
    function dispatchOn(mon, cmd) { dispatch(elsewhere(mon) ? "focus output " + mon + "; " + cmd : cmd) }
    function wsOf(i, mon) { return of(mon).first + i + 1 }
    function viewTag(i, mon) { dispatch("workspace number " + wsOf(i, mon)) }
    function sendToTag(i, mon) { dispatch("move container to workspace number " + wsOf(i, mon)) }
    function cycleTag(dir, mon) { dispatchOn(mon, dir > 0 ? "workspace next_on_output" : "workspace prev_on_output") }

    function logout() { dispatch("exit") }
    function reloadConfig() { Quickshell.execDetached([Theme.shareDir + "/scripts/sway-reload"]) }

    // processes this session can't lose: the metrics card won't offer to
    // end them (it adds the ones every setup shares). swaymsg is the bar's
    // own state stream, wl-paste the clipboard history watcher.
    readonly property var sessionProcs: /^(sway|Xwayland|swaymsg|swayidle|wl-paste)$/
}
