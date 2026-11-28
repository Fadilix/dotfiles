import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Keyboard-first app launcher. Toggle with: qs ipc call launcher toggle
// Prefixes: ">" runs a command, "=" calculates, "?" searches the web.
GlassPanel {
    id: panel

    cardWidth: 680
    cardHeight: 540
    focusItem: input

    readonly property string home: Quickshell.env("HOME")
    property var usage: ({})          // desktop entry id -> { count, last }
    property string calcResult: ""

    readonly property string raw: input.text
    readonly property string mode: raw.startsWith(">") ? "run"
                                  : raw.startsWith("=") ? "calc"
                                  : raw.startsWith("?") ? "web" : "apps"
    readonly property string query: (mode === "apps" ? raw : raw.slice(1)).trim()
    readonly property bool looksLikeMath: mode === "apps" && /^[\d\s.,+\-*\/^%()x]+$/.test(query) && /\d\s*[+\-*\/^%x]\s*[\d(]/.test(query)

    // Search text is built once per catalog change, not per keystroke.
    readonly property var catalog: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .map(e => {
            var kw = []
            try { kw = Array.from(e.keywords || []) } catch (err) {}
            var name = e.name || e.id
            return {
                id: e.id, name: name, generic: e.genericName || "",
                icon: e.icon, entry: e,
                nameL: name.toLowerCase(),
                words: name.toLowerCase().split(/[\s\-_.:]+/).filter(w => w.length),
                extra: [e.genericName || "", kw.join(" "), e.id].join(" ").toLowerCase()
            }
        })

    function fuzzy(q, s, words) {
        if (s === q) return 1000
        if (s.startsWith(q)) return 900 - s.length
        if (words) {
            for (var i = 0; i < words.length; i++)
                if (words[i].startsWith(q)) return 760 - i * 10 - s.length
            var acr = words.map(w => w[0]).join("")
            if (acr.startsWith(q)) return 700
        }
        var at = s.indexOf(q)
        if (at >= 0) return 500 - at
        var si = 0, run = 0, score = 0
        for (var j = 0; j < q.length; j++) {
            if (q[j] === " ") continue
            var f = s.indexOf(q[j], si)
            if (f < 0) return -1
            run = f === si ? run + 1 : 0
            score += 10 + run * 8 - Math.min(f - si, 8)
            si = f + 1
        }
        return Math.min(score, 320)
    }

    function frecency(id, now) {
        var u = usage[id]
        if (!u) return 0
        var days = (now - (u.last || 0)) / 86400000
        var w = days < 1 ? 4 : days < 7 ? 2 : days < 30 ? 1 : 0.5
        return Math.log(1 + u.count) * 18 * w
    }

    readonly property var results: {
        var q = query.toLowerCase()
        if (mode === "run")
            return q === "" ? [] : [{ kind: "run", title: query, sub: "shift enter opens it in kitty", icon: "utilities-terminal" }]
        if (mode === "web")
            return [{ kind: "web", title: query === "" ? "Type a search" : query, sub: "Google", icon: "internet-web-browser" }]
        if (mode === "calc")
            return [{ kind: "calc", title: calcResult || (query === "" ? "Type an expression" : "..."), sub: query, icon: "accessories-calculator" }]

        var now = Date.now(), out = []
        for (var i = 0; i < catalog.length; i++) {
            var a = catalog[i]
            var score = 0
            if (q !== "") {
                var s1 = fuzzy(q, a.nameL, a.words)
                var s2 = fuzzy(q, a.extra, null)
                score = Math.max(s1, s2 >= 0 ? s2 * 0.6 : -1)
                if (score < 0) continue
            }
            out.push({ kind: "app", app: a, title: a.name, sub: a.generic, icon: a.icon, score: score + frecency(a.id, now) })
        }
        out.sort((x, y) => y.score - x.score || x.title.localeCompare(y.title))
        if (looksLikeMath && calcResult !== "")
            out.unshift({ kind: "calc", title: calcResult, sub: query, icon: "accessories-calculator" })
        if (q !== "")
            out.push({ kind: "web", title: query, sub: "Search the web", icon: "internet-web-browser" })
        return out
    }

    onResultsChanged: if (selected >= results.length) selected = 0
    onOpened: { input.text = ""; calcResult = "" }

    function activate(r, alt) {
        if (!r) return
        if (r.kind === "app") {
            r.app.entry.execute()
            var next = Object.assign({}, usage)
            var prev = next[r.app.id] || { count: 0 }
            next[r.app.id] = { count: prev.count + 1, last: Date.now() }
            usage = next
            store.setText(JSON.stringify(usage))
        } else if (r.kind === "run") {
            if (alt) Quickshell.execDetached(["kitty", "--hold", "zsh", "-ic", query])
            else Quickshell.execDetached(["zsh", "-ic", query])
        } else if (r.kind === "web") {
            if (query === "") return
            Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(query)])
        } else if (r.kind === "calc") {
            if (calcResult === "") return
            Quickshell.execDetached(["wl-copy", calcResult])
        }
        close()
    }

    function move(d) {
        var n = results.length
        if (n === 0) return
        selected = (selected + d + n) % n
        list.positionViewAtIndex(selected, ListView.Contain)
    }

    // Usage history. Seeded once from the old name-keyed app_usage.json.
    FileView {
        id: store
        path: panel.home + "/.config/quickshell/app_frecency.json"
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: legacy
        path: panel.home + "/.config/quickshell/app_usage.json"
        blockLoading: true
        printErrors: false
    }
    Component.onCompleted: {
        try { usage = JSON.parse(store.text()) } catch (e) { usage = {} }
        if (Object.keys(usage).length > 0) return
        try {
            var old = JSON.parse(legacy.text()), seeded = {}, week = Date.now() - 7 * 86400000
            for (var i = 0; i < catalog.length; i++)
                if (old[catalog[i].name]) seeded[catalog[i].id] = { count: old[catalog[i].name], last: week }
            usage = seeded
            store.setText(JSON.stringify(seeded))
        } catch (e) {}
    }

    Timer {
        id: calcDebounce
        interval: 120
        onTriggered: {
            if (panel.query === "") { panel.calcResult = ""; return }
            calcProc.command = ["qalc", "-t", panel.query]
            calcProc.running = true
        }
    }
    onQueryChanged: if (mode === "calc" || looksLikeMath) calcDebounce.restart(); else calcResult = ""
    Process {
        id: calcProc
        stdout: StdioCollector { onStreamFinished: panel.calcResult = text.trim() }
    }

    IpcHandler {
        target: "launcher"
        function toggle() { panel.toggle() }
    }
    // Bound in Hyprland as hl.dsp.global("quickshell:launcher"): no process starts per keypress.
    GlobalShortcut {
        name: "launcher"
        description: "Toggle the app launcher"
        onPressed: panel.toggle()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0


        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 52
            Layout.maximumHeight: 52
            spacing: 14
            GlassLabel {
                text: panel.mode.toUpperCase()
                color: panel.walAccent
                font.pixelSize: 11
                font.letterSpacing: 1.5
                font.bold: true
                Layout.preferredWidth: 40
            }
            TextInput {
                id: input
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                color: panel.walForeground
                selectionColor: panel.tint(panel.walAccent, 0.4)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                clip: true
                GlassLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !input.text
                    text: "Open an app, or type > = ?"
                    color: panel.walMuted
                    font.pixelSize: 20
                }
                onTextChanged: panel.selected = 0
                Keys.onPressed: event => {
                    var ctrl = event.modifiers & Qt.ControlModifier
                    var alt = event.modifiers & Qt.AltModifier
                    event.accepted = true
                    if (event.key === Qt.Key_Escape) panel.close()
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        panel.activate(panel.results[panel.selected], event.modifiers & Qt.ShiftModifier)
                    else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) panel.move(1)
                    else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) panel.move(-1)
                    else if (event.key === Qt.Key_PageDown) panel.move(8)
                    else if (event.key === Qt.Key_PageUp) panel.move(-8)
                    else if (ctrl && event.key === Qt.Key_U) input.text = ""
                    else if (alt && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        var i = event.key - Qt.Key_1
                        if (i < panel.results.length) panel.activate(panel.results[i], false)
                    }
                    else event.accepted = false
                }
            }
            GlassLabel {
                text: panel.results.length
                color: panel.walMuted
                font.pixelSize: 11
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: panel.tint(panel.walForeground, 0.1) }

        GlassLabel {
            Layout.topMargin: 14
            Layout.bottomMargin: 6
            Layout.leftMargin: 4
            text: panel.mode !== "apps" ? "" : panel.query === "" ? "MOST USED" : "RESULTS"
            visible: text !== ""
            color: panel.walMuted
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: panel.mode === "apps" ? 0 : 14
            clip: true
            model: panel.results
            currentIndex: panel.selected
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            interactive: false   // SmoothScroll does the scrolling

            SmoothScroll { parent: list; flickable: list; wheelStep: 46 * 2 }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool active: index === panel.selected
                width: list.width
                height: 46

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: row.active ? panel.tint(panel.walForeground, 0.07) : "transparent"
                }
                Rectangle {
                    visible: row.active
                    width: 2; height: 20
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: panel.walAccent
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 14
                    Image {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        sourceSize: Qt.size(52, 52)
                        asynchronous: false
                        fillMode: Image.PreserveAspectFit
                        source: {
                            var icon = row.modelData.icon
                            if (!icon) return "image://icon/application-x-executable"
                            if (icon.indexOf("/") === 0) return "file://" + icon
                            return "image://icon/" + icon
                        }
                    }
                    GlassLabel {
                        text: row.modelData.title
                        color: panel.walForeground
                        font.pixelSize: 14
                        font.bold: row.active
                        elide: Text.ElideRight
                        Layout.maximumWidth: list.width * 0.55
                    }
                    GlassLabel {
                        Layout.fillWidth: true
                        text: row.modelData.sub || ""
                        color: panel.walMuted
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    GlassLabel {
                        visible: row.index < 9 && panel.mode === "apps"
                        text: "alt " + (row.index + 1)
                        color: row.active ? panel.walAccent : panel.tint(panel.walMuted, 0.6)
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: mouse => panel.hover(this, mouse, row.index)
                    onClicked: panel.activate(row.modelData, false)
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: panel.tint(panel.walForeground, 0.1) }

        GlassLabel {
            Layout.topMargin: 10
            Layout.leftMargin: 4
            text: "enter open    ctrl j/k move    alt 1-9 open nth    >  run    =  calc    ?  web    esc close"
            color: panel.walMuted
            font.pixelSize: 10
        }
    }
}
