import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Emoji picker. Toggle with: qs ipc call emoji toggle
// data/emoji.json: { e: emoji, n: name, k: keywords, g: group index, t?: five skin tones }
PanelWindow {
    id: panel

    property color walForeground: "#cdd6f4"
    property color walAccent: "#89b4fa"
    property color walMuted: "#6c7086"

    readonly property string fontName: "JetBrainsMono Nerd Font"
    readonly property color surface: Qt.rgba(1, 1, 1, 0.05)
    readonly property int columns: 12
    readonly property var tabs: [
        { id: -1, icon: "🕘", label: "Recent" },
        { id: 0, icon: "😀", label: "Smileys" },
        { id: 1, icon: "👋", label: "People" },
        { id: 2, icon: "🐻", label: "Nature" },
        { id: 3, icon: "🍔", label: "Food" },
        { id: 4, icon: "🚗", label: "Travel" },
        { id: 5, icon: "⚽", label: "Activities" },
        { id: 6, icon: "💡", label: "Objects" },
        { id: 7, icon: "💯", label: "Symbols" },
        { id: 8, icon: "🏁", label: "Flags" }
    ]
    readonly property var toneColors: ["#ffcc22", "#f7dcc4", "#e3bd97", "#c19069", "#95633f", "#594539"]

    property bool open: false
    property int tab: 0
    property string query: ""
    property int selected: 0
    property var emojis: []
    property var recent: []   // base emoji, most recent first
    property int tone: 0      // 0 = default, 1-5 = light to dark

    readonly property var filtered: {
        var q = query.trim().toLowerCase()
        if (q === "") {
            if (tab >= 0) return emojis.filter(x => x.g === tab)
            var byEmoji = {}
            for (var x of emojis) byEmoji[x.e] = x
            return recent.map(e => byEmoji[e]).filter(x => x !== undefined)
        }
        var words = q.split(/\s+/)
        var scored = []
        for (var i = 0; i < emojis.length; i++) {
            var score = 0
            for (var w of words) {
                var s = rank(emojis[i], w)
                if (s === 0) { score = 0; break }
                score += s
            }
            if (score === 0) continue
            if (recent.includes(emojis[i].e)) score += 1.5
            scored.push({ item: emojis[i], score: score, order: i })
        }
        scored.sort((a, b) => b.score - a.score || a.order - b.order)
        return scored.map(s => s.item)
    }
    readonly property var current: selected >= 0 && selected < filtered.length ? filtered[selected] : null

    function rank(x, w) {
        if (x.e === w || x.n === w) return 8
        var name = " " + x.n.toLowerCase().replace(/[-:]/g, " ") + " "
        if (name.includes(" " + w + " ")) return 6
        var keys = " " + x.k.toLowerCase() + " "
        if (keys.includes(" " + w + " ")) return 5
        if (name.includes(" " + w)) return 4
        if (keys.includes(" " + w)) return 3
        if (name.includes(w)) return 2
        return keys.includes(w) ? 1 : 0
    }

    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function glyph(x) { return tone > 0 && x.t ? x.t[tone - 1] : x.e }

    // Only real pointer movement selects: not the cursor already there on open, nor content scrolling under it.
    property point lastMouse: Qt.point(-1, -1)
    function hover(area, mouse, index) {
        var p = area.mapToItem(null, mouse.x, mouse.y)
        var moved = lastMouse.x >= 0 && (Math.abs(p.x - lastMouse.x) > 2 || Math.abs(p.y - lastMouse.y) > 2)
        if (lastMouse.x < 0 || moved) lastMouse = Qt.point(p.x, p.y)
        if (moved) selected = index
    }

    function toggle() { open ? close() : show() }

    function show() {
        var focused = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        var target = Quickshell.screens.find(s => s.name === focused)
        if (target) screen = target
        lastMouse = Qt.point(-1, -1)
        search.text = ""
        setTab(recent.length > 0 ? -1 : 0)
        open = true
        focusTimer.restart()
    }

    function close() { open = false }

    function setTab(id) {
        search.text = ""
        tab = id
        selected = 0
        grid.positionViewAtBeginning()
    }

    function cycleTab(delta) {
        var i = tabs.findIndex(t => t.id === tab)
        setTab(tabs[(i + delta + tabs.length) % tabs.length].id)
    }

    function move(delta) {
        var n = filtered.length
        if (n === 0) return
        var next = selected + delta
        if (next < 0) next = delta === -1 ? 0 : selected
        // Down from the last full row lands on the last, shorter row.
        if (next >= n) next = Math.floor(selected / columns) < Math.floor((n - 1) / columns) ? n - 1 : selected
        selected = next
        grid.positionViewAtIndex(selected, GridView.Contain)
    }

    function setTone(t) { tone = t; save() }

    function pick(x) {
        if (!x) return
        Quickshell.execDetached(["wl-copy", "--", glyph(x)])
        close()
        recent = [x.e].concat(recent.filter(e => e !== x.e)).slice(0, 48)
        save()
    }

    function save() { stateFile.setText(JSON.stringify({ recent: recent, tone: tone })) }

    Timer { id: focusTimer; interval: 0; onTriggered: if (panel.open) search.forceActiveFocus() }

    FileView {
        path: Qt.resolvedUrl("data/emoji.json")
        onLoaded: panel.emojis = JSON.parse(text())
    }

    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.cache/quickshell-emoji.json"
        printErrors: false
        onLoaded: {
            try {
                var s = JSON.parse(text())
                panel.recent = Array.isArray(s.recent) ? s.recent : []
                panel.tone = s.tone >= 0 && s.tone <= 5 ? s.tone : 0
            } catch (e) {}
        }
    }

    IpcHandler {
        target: "emoji"
        function toggle() { panel.toggle() }
    }

    visible: open || card.opacity > 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-emoji"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: card.opacity * 0.3
    }
    MouseArea {
        anchors.fill: parent
        onClicked: panel.close()
    }

    component Label: Text {
        color: panel.walForeground
        font.family: panel.fontName
        font.pixelSize: 13
        textFormat: Text.PlainText
    }

    component Emoji: Text {
        font.family: "Apple Color Emoji"
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(660, panel.width - 60)
        height: Math.min(560, panel.height - 60)
        radius: 20
        color: Qt.rgba(0.035, 0.035, 0.05, 0.72)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        opacity: panel.open ? 1 : 0
        scale: panel.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // clicks on the card do not close it

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                radius: 12
                color: panel.surface
                border.width: search.activeFocus ? 1 : 0
                border.color: panel.tint(panel.walAccent, 0.6)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10
                    Label { text: "\u{F0349}"; color: panel.walMuted; font.pixelSize: 16 }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: panel.walForeground
                        selectionColor: panel.tint(panel.walAccent, 0.5)
                        font.family: panel.fontName
                        font.pixelSize: 14
                        selectByMouse: true
                        clip: true
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !search.text
                            text: "Search emoji..."
                            color: panel.walMuted
                            font.pixelSize: 14
                        }
                        onTextChanged: {
                            panel.query = text
                            panel.selected = 0
                            grid.positionViewAtBeginning()
                        }
                        Keys.onPressed: event => {
                            event.accepted = true
                            if (event.key === Qt.Key_Escape) panel.close()
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) panel.pick(panel.current)
                            else if (event.key === Qt.Key_Right) panel.move(1)
                            else if (event.key === Qt.Key_Left) panel.move(-1)
                            else if (event.key === Qt.Key_Down) panel.move(panel.columns)
                            else if (event.key === Qt.Key_Up) panel.move(-panel.columns)
                            else if (event.key === Qt.Key_Tab) panel.cycleTab(1)
                            else if (event.key === Qt.Key_Backtab) panel.cycleTab(-1)
                            else event.accepted = false
                        }
                    }
                    Label { text: panel.filtered.length; color: panel.walMuted; font.pixelSize: 11 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                radius: 12
                color: panel.surface
                Row {
                    id: tabRow
                    anchors.fill: parent
                    anchors.margins: 4
                    Repeater {
                        model: panel.tabs
                        Rectangle {
                            id: tabItem
                            required property var modelData
                            readonly property bool active: panel.query.trim() === "" && panel.tab === modelData.id
                            width: tabRow.width / panel.tabs.length
                            height: tabRow.height
                            radius: 9
                            color: active ? panel.tint(panel.walAccent, 0.28) : tabMouse.containsMouse ? panel.tint(panel.walForeground, 0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Emoji {
                                anchors.centerIn: parent
                                text: tabItem.modelData.icon
                                font.pixelSize: 17
                                opacity: tabItem.active || tabMouse.containsMouse ? 1 : 0.55
                            }
                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { panel.setTab(tabItem.modelData.id); search.forceActiveFocus() }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridView {
                    id: grid
                    anchors.fill: parent
                    clip: true
                    cellWidth: width / panel.columns
                    cellHeight: cellWidth
                    boundsBehavior: Flickable.StopAtBounds
                    model: panel.filtered

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool active: index === panel.selected
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 11
                            color: cell.active ? panel.tint(panel.walAccent, 0.24) : "transparent"
                            border.width: cell.active ? 1 : 0
                            border.color: panel.tint(panel.walAccent, 0.6)
                        }
                        Emoji {
                            anchors.fill: parent
                            anchors.margins: 6
                            text: panel.glyph(cell.modelData)
                            color: panel.walForeground
                            font.pixelSize: 27
                            fontSizeMode: Text.Fit
                            minimumPixelSize: 6
                            scale: cell.active ? 1.1 : 1
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: mouse => panel.hover(this, mouse, cell.index)
                            onClicked: panel.pick(cell.modelData)
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: panel.filtered.length === 0
                    text: panel.query.trim() === "" && panel.tab === -1 ? "Emoji you pick show up here" : "No matches"
                    color: panel.walMuted
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                radius: 14
                color: panel.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12
                    Emoji {
                        Layout.preferredWidth: 36
                        Layout.fillHeight: true
                        text: panel.current ? panel.glyph(panel.current) : ""
                        color: panel.walForeground
                        font.pixelSize: 32
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 6
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            Layout.fillWidth: true
                            text: panel.current ? panel.current.n.charAt(0).toUpperCase() + panel.current.n.slice(1) : ""
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Enter copy   Tab category"
                            color: panel.walMuted
                            font.pixelSize: 10
                        }
                    }
                    Row {
                        spacing: 6
                        Repeater {
                            model: panel.toneColors
                            Rectangle {
                                id: dot
                                required property var modelData
                                required property int index
                                width: 18
                                height: 18
                                radius: 9
                                color: modelData
                                border.width: panel.tone === index ? 2 : 0
                                border.color: "#ffffff"
                                opacity: panel.tone === index || dotMouse.containsMouse ? 1 : 0.5
                                MouseArea {
                                    id: dotMouse
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { panel.setTone(dot.index); search.forceActiveFocus() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
