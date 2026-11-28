import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// macOS Spotlight look for the launcher (test variant of AppLauncher.qml, same search logic).
// Switch back by replacing SpotlightLauncher with AppLauncher in shell.qml.
GlassPanel {
    id: panel

    readonly property string sans: "Adwaita Sans"
    readonly property color blue: "#0a84ff"
    readonly property bool expanded: raw.length > 0
    readonly property int barHeight: 58

    cardWidth: 760
    cardHeight: expanded ? 440 : barHeight
    cardY: height * 0.22
    dimOpacity: 0
    cardRadius: expanded ? 14 : 18
    cardColor: Qt.rgba(0.16, 0.16, 0.17, 0.78)
    cardBorder: Qt.rgba(1, 1, 1, 0.14)
    contentMargin: 0
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
        list.positionViewAtIndex(rowOf[selected] || 0, ListView.Contain)
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
    onQueryChanged: { if (mode === "calc" || looksLikeMath) calcDebounce.restart(); else calcResult = "" }
    Process {
        id: calcProc
        stdout: StdioCollector { onStreamFinished: panel.calcResult = text.trim() }
    }

    IpcHandler {
        target: "launcher"
        function toggle() { panel.toggle() }
        // Opens the launcher with a query already typed, e.g. qs ipc call launcher search vsc
        function search(text: string): void { if (!panel.open) panel.show(); input.text = text }
    }
    // Bound in Hyprland as hl.dsp.global("quickshell:launcher"): no process starts per keypress.
    GlobalShortcut {
        name: "launcher"
        description: "Toggle the app launcher"
        onPressed: panel.toggle()
    }


    // Rows shown on the left: section headers plus results (Top Hit, Applications, then the rest).
    readonly property var rows: {
        var out = [], shown = 0
        var apps = [], other = []
        for (var i = 0; i < results.length; i++)
            (results[i].kind === "app" ? apps : other).push(i)
        var top = results.length ? 0 : -1
        if (top >= 0) { out.push({ header: "Top Hit" }); out.push({ ri: top }) }
        var restApps = apps.filter(i => i !== top).slice(0, 12)
        if (restApps.length) { out.push({ header: "Applications" }); restApps.forEach(i => out.push({ ri: i })) }
        var restOther = other.filter(i => i !== top)
        if (restOther.length) { out.push({ header: "Other" }); restOther.forEach(i => out.push({ ri: i })) }
        return out
    }
    readonly property var visibleIdx: rows.filter(r => r.header === undefined).map(r => r.ri)
    readonly property var rowOf: {
        var m = {}
        for (var i = 0; i < rows.length; i++) if (rows[i].ri !== undefined) m[rows[i].ri] = i
        return m
    }
    // Keep selection on results that are actually listed.
    function step(d) {
        var v = visibleIdx
        if (!v.length) return
        var p = v.indexOf(selected)
        selected = v[((p < 0 ? 0 : p + d) + v.length) % v.length]
        list.positionViewAtIndex(rowOf[selected] || 0, ListView.Contain)
    }
    readonly property var current: results[selected] || null

    function iconSource(icon) {
        if (!icon) return "image://icon/application-x-executable"
        if (icon.indexOf("/") === 0) return "file://" + icon
        return "image://icon/" + icon
    }

    // Search bar
    Item {
        id: bar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: panel.barHeight

        Text {
            id: glass
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: Qt.rgba(1, 1, 1, 0.55)
        }
        TextInput {
            id: input
            anchors.left: glass.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            color: "#ffffff"
            selectionColor: panel.tint(panel.blue, 0.6)
            font.family: panel.sans
            font.pixelSize: 24
            font.weight: Font.Light
            clip: true
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !input.text
                text: "Spotlight Search"
                color: Qt.rgba(1, 1, 1, 0.38)
                font: input.font
            }
            onTextChanged: panel.selected = 0
            Keys.onPressed: event => {
                var ctrl = event.modifiers & Qt.ControlModifier
                var alt = event.modifiers & Qt.AltModifier
                event.accepted = true
                if (event.key === Qt.Key_Escape) { if (input.text) input.text = ""; else panel.close() }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    panel.activate(panel.current, event.modifiers & Qt.ShiftModifier)
                else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) panel.step(1)
                else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) panel.step(-1)
                else if (ctrl && event.key === Qt.Key_U) input.text = ""
                else if (alt && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                    var v = panel.visibleIdx, i = event.key - Qt.Key_1
                    if (i < v.length) panel.activate(panel.results[v[i]], false)
                }
                else event.accepted = false
            }
        }
    }

    Rectangle {
        visible: panel.expanded
        anchors.top: bar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.1)
    }

    // Results (left) and preview (right)
    Item {
        visible: panel.expanded
        anchors.top: bar.bottom
        anchors.topMargin: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        ListView {
            id: list
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 8
            width: parent.width * 0.44
            clip: true
            model: panel.rows
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool isHeader: modelData.header !== undefined
                readonly property var res: isHeader ? null : panel.results[modelData.ri]
                readonly property bool active: !isHeader && modelData.ri === panel.selected
                width: list.width
                height: isHeader ? 26 : 30

                Text {
                    visible: row.isHeader
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    text: row.isHeader ? row.modelData.header : ""
                    font.family: panel.sans
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Qt.rgba(1, 1, 1, 0.45)
                }
                Rectangle {
                    visible: !row.isHeader
                    anchors.fill: parent
                    radius: 6
                    color: row.active ? panel.blue : "transparent"
                }
                Row {
                    visible: !row.isHeader
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9
                    Image {
                        width: 20; height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        sourceSize: Qt.size(40, 40)
                        fillMode: Image.PreserveAspectFit
                        source: row.res ? panel.iconSource(row.res.icon) : ""
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        text: row.res ? row.res.title : ""
                        font.family: panel.sans
                        font.pixelSize: 13
                        color: "#ffffff"
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    enabled: !row.isHeader
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: mouse => panel.hover(this, mouse, row.modelData.ri)
                    onClicked: panel.activate(row.res, false)
                }
            }
        }

        Rectangle {
            id: divider
            anchors.left: list.right
            anchors.leftMargin: 8
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Qt.rgba(1, 1, 1, 0.1)
        }

        // Preview pane
        Item {
            anchors.left: divider.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Column {
                visible: panel.current !== null
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 44
                width: parent.width - 48
                spacing: 10

                Image {
                    visible: panel.current && panel.current.kind !== "calc"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 112; height: 112
                    sourceSize: Qt.size(224, 224)
                    fillMode: Image.PreserveAspectFit
                    source: panel.current ? panel.iconSource(panel.current.icon) : ""
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: !panel.current ? "" : panel.current.kind === "calc" ? panel.current.title
                          : panel.current.kind === "web" ? "Search the Web" : panel.current.title
                    font.family: panel.sans
                    font.pixelSize: panel.current && panel.current.kind === "calc" ? 40 : 20
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: !panel.current ? "" : panel.current.kind === "app" ? (panel.current.sub || "Application")
                          : panel.current.kind === "calc" ? panel.current.sub
                          : panel.current.kind === "web" ? "“" + panel.query + "”"
                          : "Run in shell"
                    font.family: panel.sans
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.55)
                    elide: Text.ElideRight
                }
                Item { width: 1; height: 14 }
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.1) }
                Item { width: 1; height: 4 }
                Repeater {
                    model: {
                        var c = panel.current
                        if (!c) return []
                        if (c.kind === "app") {
                            var u = panel.usage[c.app.id]
                            return [["Kind", "Application"],
                                    ["Opened", u ? u.count + (u.count === 1 ? " time" : " times") : "Never"],
                                    ["Last used", u && u.last ? new Date(u.last).toLocaleDateString() : "Unknown"]]
                        }
                        if (c.kind === "calc") return [["Kind", "Calculator"], ["Return", "Copy result"]]
                        if (c.kind === "web") return [["Kind", "Web search"], ["Engine", "Google"]]
                        return [["Kind", "Shell command"], ["Shift return", "Open in kitty"]]
                    }
                    Row {
                        required property var modelData
                        width: parent.width
                        Text {
                            width: parent.width * 0.42
                            horizontalAlignment: Text.AlignRight
                            text: modelData[0]
                            font.family: panel.sans
                            font.pixelSize: 12
                            color: Qt.rgba(1, 1, 1, 0.45)
                        }
                        Item { width: 12; height: 1 }
                        Text {
                            width: parent.width * 0.5
                            text: modelData[1]
                            font.family: panel.sans
                            font.pixelSize: 12
                            color: Qt.rgba(1, 1, 1, 0.85)
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            Text {
                visible: panel.current === null
                anchors.centerIn: parent
                text: "No Results"
                font.family: panel.sans
                font.pixelSize: 15
                color: Qt.rgba(1, 1, 1, 0.4)
            }
        }
    }
}
