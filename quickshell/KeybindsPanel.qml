import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Keybind cheat sheet. Toggle with: qs ipc call keybinds toggle
// Reads the live binds; labels are the "Category: text" descriptions in hypr/lua/bindings.lua.
GlassPanel {
    id: panel

    property var binds: []      // { category, text, keys: [] }
    property string category: ""
    readonly property var categories: {
        var seen = []
        for (var b of binds) if (!seen.includes(b.category)) seen.push(b.category)
        return ["All"].concat(seen.filter(c => c !== "Other").sort(), seen.includes("Other") ? ["Other"] : [])
    }
    readonly property var filtered: {
        var words = search.text.trim().toLowerCase().split(/[\s+]+/).filter(w => w.length > 0)
        var rows = binds.filter(b => {
            // A search looks through every category.
            if (words.length === 0) return category === "All" || b.category === category
            var keys = b.keys.map(k => k.toLowerCase())
            var hay = (b.category + " " + b.text).toLowerCase()
            return words.every(w => {
                // Modifiers and single letters only mean keys, so "super shift s" stays exact.
                if (["super", "ctrl", "alt", "shift"].includes(w) || /^[a-z]$/.test(w)) return keys.includes(w)
                return hay.includes(w) || keys.some(k => k.startsWith(w))
            })
        })
        return rows.sort((a, b) => categories.indexOf(a.category) - categories.indexOf(b.category) || a.order - b.order)
    }
    readonly property var keyNames: ({
        left: "←", right: "→", up: "↑", down: "↓", return: "Enter", space: "Space", tab: "Tab", delete: "Delete", print: "Print",
        period: ".", comma: ",", bracketleft: "[", bracketright: "]", slash: "/",
        mouse_down: "Scroll down", mouse_up: "Scroll up", "mouse:272": "Left drag", "mouse:273": "Right drag"
    })

    cardWidth: 900
    cardHeight: 620
    focusItem: search
    onOpened: {
        search.text = ""
        category = "All"
        list.contentY = 0
        bindProc.running = true
    }

    function keyName(b) {
        if (b.keycode >= 10 && b.keycode <= 19) return "" + (b.keycode - 9) % 10
        // Physical keys bound by keycode, labelled as printed on the AZERTY keyboard.
        var azerty = { 34: "^", 35: "$" }
        if (azerty[b.keycode]) return azerty[b.keycode]
        if (b.keycode > 0) return "code " + b.keycode
        var named = keyNames[b.key.toLowerCase()]
        if (named) return named
        if (b.key.startsWith("XF86")) return b.key.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2").replace("Audio ", "")
        return b.key.length === 1 ? b.key.toUpperCase() : b.key
    }

    function parse(json) {
        var raw
        try { raw = JSON.parse(json) } catch (e) { return }
        var rows = [], ranges = {}
        for (var b of raw) {
            var keys = []
            if (b.modmask & 64) keys.push("Super")
            if (b.modmask & 4) keys.push("Ctrl")
            if (b.modmask & 8) keys.push("Alt")
            if (b.modmask & 1) keys.push("Shift")
            var m = b.description.match(/^([^:]+): (.+)$/)
            var row = {
                category: m ? m[1] : "Other",
                text: m ? m[2] : b.description || "No description (" + b.dispatcher.replace(/^HL\.Dispatcher\((.*)\)$/, "$1") + ")",
                keys: keys, order: rows.length
            }
            // The ten workspace digits become one row.
            if (b.keycode >= 10 && b.keycode <= 19 && / \d+$/.test(row.text)) {
                var base = row.text.replace(/ \d+$/, "")
                if (ranges[base]) continue
                ranges[base] = true
                row.text = base + " 1 to 10"
                keys.push("1 … 0")
            } else {
                keys.push(keyName(b))
            }
            rows.push(row)
        }
        binds = rows
    }

    function cycle(delta) {
        var i = categories.indexOf(category)
        category = categories[(i + delta + categories.length) % categories.length]
        search.text = ""
        list.contentY = 0
    }

    function scroll(delta) {
        list.contentY = Math.max(0, Math.min(Math.max(0, list.contentHeight - list.height), list.contentY + delta))
    }

    Process {
        id: bindProc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector { onStreamFinished: panel.parse(this.text) }
    }

    IpcHandler {
        target: "keybinds"
        function toggle() { panel.toggle() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 12
            color: panel.surface
            border.width: 1
            border.color: panel.tint(panel.walAccent, 0.6)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10
                GlassLabel { text: "\u{F030C}"; color: panel.walMuted; font.pixelSize: 17 }
                TextInput {
                    id: search
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: panel.walForeground
                    selectionColor: panel.tint(panel.walAccent, 0.5)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    selectByMouse: true
                    clip: true
                    onTextChanged: list.contentY = 0
                    GlassLabel {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !search.text
                        text: "Search by action or keys, like \"super shift s\"..."
                        color: panel.walMuted
                        font.pixelSize: 14
                    }
                    Keys.onPressed: event => {
                        event.accepted = true
                        if (event.key === Qt.Key_Escape) panel.close()
                        else if (event.key === Qt.Key_Tab) panel.cycle(1)
                        else if (event.key === Qt.Key_Backtab) panel.cycle(-1)
                        else if (event.key === Qt.Key_Down) panel.scroll(80)
                        else if (event.key === Qt.Key_Up) panel.scroll(-80)
                        else if (event.key === Qt.Key_PageDown) panel.scroll(list.height)
                        else if (event.key === Qt.Key_PageUp) panel.scroll(-list.height)
                        else event.accepted = false
                    }
                }
                GlassLabel { text: panel.filtered.length; color: panel.walMuted; font.pixelSize: 11 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            Column {
                Layout.preferredWidth: 150
                Layout.fillHeight: true
                spacing: 3
                Repeater {
                    model: panel.categories
                    Rectangle {
                        id: cat
                        required property var modelData
                        readonly property bool active: search.text.trim() === "" && panel.category === modelData
                        width: 150
                        height: 36
                        radius: 10
                        color: active ? panel.tint(panel.walAccent, 0.22) : catMouse.containsMouse ? panel.tint(panel.walForeground, 0.07) : "transparent"
                        GlassLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 12
                            text: cat.modelData
                            color: cat.active ? panel.walForeground : panel.tint(panel.walForeground, 0.7)
                            font.bold: cat.active
                        }
                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { search.text = ""; panel.category = cat.modelData; list.contentY = 0; search.forceActiveFocus() }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 15
                color: panel.surface

                ListView {
                    id: list
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    // Uniform heights keep contentHeight exact for keyboard scrolling.
                    model: panel.filtered
                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 40

                        Rectangle {
                            anchors.fill: parent
                            radius: 9
                            color: rowHover.hovered ? panel.tint(panel.walForeground, 0.06) : "transparent"
                        }
                        HoverHandler { id: rowHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12
                            GlassLabel {
                                Layout.fillWidth: true
                                text: row.modelData.text
                                color: panel.walForeground
                                elide: Text.ElideRight
                            }
                            GlassLabel {
                                visible: panel.category === "All" || search.text.trim() !== ""
                                text: row.modelData.category
                                color: panel.walMuted
                                font.pixelSize: 11
                            }
                            Row {
                                Layout.preferredWidth: 270
                                layoutDirection: Qt.RightToLeft
                                spacing: 5
                                Repeater {
                                    model: row.modelData.keys.slice().reverse()
                                    Rectangle {
                                        id: cap
                                        required property var modelData
                                        width: capText.implicitWidth + 14
                                        height: 24
                                        radius: 7
                                        color: panel.tint(panel.walForeground, 0.1)
                                        border.width: 1
                                        border.color: panel.tint(panel.walForeground, 0.12)
                                        GlassLabel { id: capText; anchors.centerIn: parent; text: cap.modelData; color: panel.walForeground; font.pixelSize: 11 }
                                    }
                                }
                            }
                        }
                    }
                }
                GlassLabel {
                    anchors.centerIn: parent
                    visible: panel.filtered.length === 0 && !bindProc.running
                    text: "No matches"
                    color: panel.walMuted
                }
            }
        }
    }
}
