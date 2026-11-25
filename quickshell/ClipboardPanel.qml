import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Clipboard history picker backed by cliphist. Toggle with: qs ipc call clipboard toggle
PanelWindow {
    id: panel

    property color walForeground: "#cdd6f4"
    property color walAccent: "#89b4fa"
    property color walMuted: "#6c7086"
    property color walRed: "#f38ba8"

    readonly property string fontName: "JetBrainsMono Nerd Font"
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell-clipboard"
    readonly property color surface: Qt.rgba(1, 1, 1, 0.05)
    readonly property var kinds: [
        { id: "all", label: "All" },
        { id: "text", label: "Text" },
        { id: "link", label: "Links" },
        { id: "image", label: "Images" }
    ]
    readonly property var icons: ({
        text: "\u{F09A8}", link: "\u{F0339}", image: "\u{F02E9}", color: "\u{F03D8}", binary: "\u{F0214}"
    })

    property bool open: false
    property bool confirmWipe: false
    property string filterKind: "all"
    property string query: ""
    property int selected: 0
    property var items: []          // { id, text, kind, meta }, newest first
    property var readyImages: ({})  // id -> true once its file is in cacheDir
    property string previewId: ""
    property string previewText: ""

    readonly property var filtered: {
        var words = query.toLowerCase().split(/\s+/).filter(w => w.length > 0)
        return items.filter(item => {
            if (filterKind === "text" && item.kind !== "text" && item.kind !== "color") return false
            if ((filterKind === "link" || filterKind === "image") && item.kind !== filterKind) return false
            var hay = item.text.toLowerCase()
            return words.every(w => hay.includes(w))
        })
    }
    readonly property var current: selected >= 0 && selected < filtered.length ? filtered[selected] : null

    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

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
        filterKind = "all"
        selected = 0
        confirmWipe = false
        previewId = ""
        previewText = ""
        open = true
        refresh()
        focusTimer.restart()
    }

    function close() {
        open = false
        confirmWipe = false
    }

    function refresh() { listProc.running = true }

    function parse(out) {
        var result = []
        for (var line of out.split("\n")) {
            var tab = line.indexOf("\t")
            if (tab < 1) continue
            var id = line.slice(0, tab)
            if (!/^\d+$/.test(id)) continue
            var text = line.slice(tab + 1).trim()
            var kind = "text", meta = ""
            var bin = text.match(/^\[\[ binary data (.+?) (\S+) (\d+x\d+) \]\]$/)
            if (bin) {
                kind = "image"
                meta = bin[2].toUpperCase() + "  " + bin[3].replace("x", " × ") + "  " + bin[1]
            } else if (text.startsWith("[[ binary data")) {
                kind = "binary"
            } else if (/^https?:\/\/\S+$/i.test(text)) {
                kind = "link"
            } else if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(text)) {
                kind = "color"
            }
            result.push({ id: id, text: text, kind: kind, meta: meta })
        }
        items = result
        selected = Math.max(0, Math.min(selected, filtered.length - 1))
        list.positionViewAtIndex(selected, ListView.Contain)
        loadPreview()
        cacheImages()
    }

    // Decodes images missing from the cache and drops those no longer in history.
    function cacheImages() {
        if (cacheProc.running) return
        cacheProc.command = ["sh", "-c",
            "umask 077; mkdir -p \"$0\" && cd \"$0\" || exit 1\n" +
            "for id in \"$@\"; do\n" +
            "  if [ ! -s \"$id\" ]; then cliphist decode \"$id\" > \"$id.part\" && mv \"$id.part\" \"$id\" || { rm -f \"$id.part\"; continue; }; fi\n" +
            "  echo \"$id\"\n" +
            "done\n" +
            "keep=\" $* \"\n" +
            "for f in *; do case \"$keep\" in *\" $f \"*) ;; *) rm -f -- \"$f\" ;; esac; done",
            cacheDir].concat(items.filter(i => i.kind === "image").map(i => i.id))
        cacheProc.running = true
    }

    function move(delta) {
        if (filtered.length === 0) return
        selected = Math.max(0, Math.min(filtered.length - 1, selected + delta))
        list.positionViewAtIndex(selected, ListView.Contain)
    }

    function cycleKind(delta) {
        var i = kinds.findIndex(k => k.id === filterKind)
        filterKind = kinds[(i + delta + kinds.length) % kinds.length].id
        selected = 0
    }

    function copy(item) {
        if (!item) return
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$0\" | wl-copy", item.id])
        close()
    }

    function openLink(item) {
        if (!item || item.kind !== "link") return
        Quickshell.execDetached(["xdg-open", item.text])
        close()
    }

    function remove(item) {
        if (!item || actionProc.running) return
        actionProc.command = ["sh", "-c", "printf '%s\\t\\n' \"$0\" | cliphist delete", item.id]
        actionProc.running = true
    }

    // The first call asks for confirmation, the second one wipes.
    function wipe() {
        if (!confirmWipe) {
            confirmWipe = true
            wipeTimer.restart()
            return
        }
        confirmWipe = false
        if (actionProc.running) return
        actionProc.command = ["cliphist", "wipe"]
        actionProc.running = true
    }

    function loadPreview() {
        if (!open || !current || current.kind === "image" || current.kind === "binary") return
        if (previewId === current.id) return
        previewProc.exec(["sh", "-c", "echo \"$0\"; cliphist decode \"$0\" | head -c 20000", current.id])
    }

    onCurrentChanged: previewTimer.restart()
    onFilterKindChanged: list.positionViewAtBeginning()

    Timer { id: focusTimer; interval: 0; onTriggered: if (panel.open) search.forceActiveFocus() }
    Timer { id: previewTimer; interval: 50; onTriggered: panel.loadPreview() }
    Timer { id: wipeTimer; interval: 3000; onTriggered: panel.confirmWipe = false }

    Process {
        id: listProc
        command: ["cliphist", "-preview-width", "400", "list"]
        stdout: StdioCollector { onStreamFinished: panel.parse(this.text) }
    }

    Process {
        id: cacheProc
        property var batch: ({})
        function flush() { panel.readyImages = Object.assign({}, panel.readyImages, batch); batch = {} }
        stdout: SplitParser {
            onRead: id => { cacheProc.batch[id] = true; if (!flushTimer.running) flushTimer.start() }
        }
        onExited: flush()
    }
    Timer { id: flushTimer; interval: 60; onTriggered: cacheProc.flush() }

    Process {
        id: previewProc
        stdout: StdioCollector {
            // The first line is the id, so a late result cannot land on another entry.
            onStreamFinished: {
                var nl = this.text.indexOf("\n")
                var id = this.text.slice(0, nl)
                if (!panel.current || panel.current.id !== id) return
                panel.previewId = id
                panel.previewText = this.text.slice(nl + 1)
            }
        }
    }

    Process { id: actionProc; onExited: panel.refresh() }

    IpcHandler {
        target: "clipboard"
        function toggle() { panel.toggle() }
    }

    visible: open || card.opacity > 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
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

    component Hint: RowLayout {
        property string keys
        property string label
        spacing: 6
        Rectangle {
            implicitWidth: keyLabel.implicitWidth + 12
            implicitHeight: 20
            radius: 6
            color: panel.tint(panel.walForeground, 0.1)
            Label { id: keyLabel; anchors.centerIn: parent; text: parent.parent.keys; font.pixelSize: 10 }
        }
        Label { text: parent.label; color: panel.walMuted; font.pixelSize: 11 }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(880, panel.width - 60)
        height: Math.min(580, panel.height - 60)
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
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
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
                                text: "Search clipboard..."
                                color: panel.walMuted
                                font.pixelSize: 14
                            }
                            onTextChanged: {
                                panel.query = text
                                panel.selected = 0
                                list.positionViewAtBeginning()
                            }
                            Keys.onPressed: event => {
                                var ctrl = event.modifiers & Qt.ControlModifier
                                var alt = event.modifiers & Qt.AltModifier
                                event.accepted = true
                                if (event.key === Qt.Key_Escape) panel.close()
                                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) panel.copy(panel.current)
                                else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) panel.move(1)
                                else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) panel.move(-1)
                                else if (event.key === Qt.Key_PageDown) panel.move(7)
                                else if (event.key === Qt.Key_PageUp) panel.move(-7)
                                else if (event.key === Qt.Key_Tab) panel.cycleKind(1)
                                else if (event.key === Qt.Key_Backtab) panel.cycleKind(-1)
                                else if (ctrl && event.key === Qt.Key_Delete) panel.remove(panel.current)
                                else if (alt && event.key === Qt.Key_Delete) panel.wipe()
                                else if (ctrl && event.key === Qt.Key_O) panel.openLink(panel.current)
                                else event.accepted = false
                            }
                        }
                        Label { text: panel.filtered.length; color: panel.walMuted; font.pixelSize: 11 }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 42
                    Layout.preferredWidth: tabs.implicitWidth + 8
                    radius: 12
                    color: panel.surface
                    Row {
                        id: tabs
                        anchors.centerIn: parent
                        spacing: 2
                        Repeater {
                            model: panel.kinds
                            Rectangle {
                                id: tab
                                required property var modelData
                                readonly property bool active: panel.filterKind === modelData.id
                                width: tabLabel.implicitWidth + 24
                                height: 34
                                radius: 9
                                color: active ? panel.walAccent : tabMouse.containsMouse ? panel.tint(panel.walForeground, 0.08) : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Label {
                                    id: tabLabel
                                    anchors.centerIn: parent
                                    text: tab.modelData.label
                                    font.pixelSize: 12
                                    font.bold: tab.active
                                    color: tab.active ? "#0b0b0f" : panel.walForeground
                                }
                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { panel.filterKind = tab.modelData.id; panel.selected = 0 }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                Item {
                    Layout.preferredWidth: 390
                    Layout.fillHeight: true

                    ListView {
                        id: list
                        anchors.fill: parent
                        clip: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        model: panel.filtered

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool active: index === panel.selected
                            readonly property bool isImage: modelData.kind === "image"

                            width: ListView.view.width
                            height: isImage ? 66 : 48
                            radius: 12
                            color: active ? panel.tint(panel.walAccent, 0.2) : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: row.active ? parent.height - 22 : 0
                                radius: 2
                                color: panel.walAccent
                                Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: mouse => panel.hover(this, mouse, row.index)
                                onClicked: panel.copy(row.modelData)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: row.isImage ? 78 : 30
                                    Layout.preferredHeight: row.isImage ? 50 : 30
                                    radius: 8
                                    clip: true
                                    color: row.modelData.kind === "color" ? row.modelData.text : panel.surface
                                    Label {
                                        anchors.centerIn: parent
                                        visible: row.modelData.kind !== "color" && thumb.status !== Image.Ready
                                        text: panel.icons[row.modelData.kind]
                                        color: row.active ? panel.walAccent : panel.walMuted
                                        font.pixelSize: 16
                                    }
                                    Image {
                                        id: thumb
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 200
                                        source: row.isImage && panel.readyImages[row.modelData.id] ? "file://" + panel.cacheDir + "/" + row.modelData.id : ""
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: row.isImage ? row.modelData.meta
                                        : row.modelData.kind === "link" ? row.modelData.text.replace(/^https?:\/\/(www\.)?/i, "")
                                        : row.modelData.text
                                    color: row.isImage && !row.active ? panel.tint(panel.walForeground, 0.7) : panel.walForeground
                                    font.pixelSize: row.isImage ? 12 : 13
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Label {
                                    visible: row.active
                                    text: "\u{F01B4}"
                                    font.pixelSize: 16
                                    color: trash.containsMouse ? panel.walRed : panel.walMuted
                                    MouseArea {
                                        id: trash
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: panel.remove(row.modelData)
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: panel.filtered.length === 0 && !listProc.running
                        text: panel.items.length === 0 ? "Clipboard is empty" : "No matches"
                        color: panel.walMuted
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 15
                    color: panel.surface

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12
                        visible: panel.current !== null

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Image {
                                anchors.fill: parent
                                visible: panel.current !== null && panel.current.kind === "image"
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: 1000
                                source: visible && panel.readyImages[panel.current.id] ? "file://" + panel.cacheDir + "/" + panel.current.id : ""
                            }

                            Rectangle {
                                id: swatch
                                visible: panel.current !== null && panel.current.kind === "color"
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: visible ? 120 : 0
                                radius: 10
                                color: visible ? panel.current.text : "transparent"
                            }

                            Flickable {
                                anchors.fill: parent
                                anchors.topMargin: swatch.visible ? swatch.height + 12 : 0
                                visible: panel.current !== null && panel.current.kind !== "image"
                                clip: true
                                contentHeight: body.implicitHeight
                                boundsBehavior: Flickable.StopAtBounds
                                Label {
                                    id: body
                                    width: parent.width
                                    text: !panel.current ? "" : panel.previewId === panel.current.id ? panel.previewText : panel.current.text
                                    wrapMode: Text.Wrap
                                    font.pixelSize: 12
                                    lineHeight: 1.25
                                    onTextChanged: parent.parent.contentY = 0
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            color: panel.walMuted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            text: {
                                var c = panel.current
                                if (!c) return ""
                                if (c.kind === "image") return c.meta
                                if (c.kind === "binary" || panel.previewId !== c.id) return ""
                                var n = panel.previewText.length
                                var lines = panel.previewText.split("\n").length
                                return n + (n === 1 ? " char  " : " chars  ") + lines + (lines === 1 ? " line" : " lines")
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Hint { keys: "Enter"; label: "copy" }
                Hint { keys: "Tab"; label: "filter" }
                Hint { keys: "Ctrl Del"; label: "delete" }
                Hint { keys: "Ctrl O"; label: "open link"; visible: panel.current !== null && panel.current.kind === "link" }
                Item { Layout.fillWidth: true }
                Label {
                    text: panel.confirmWipe ? "Again to clear everything" : "Clear all"
                    color: panel.confirmWipe || wipeMouse.containsMouse ? panel.walRed : panel.walMuted
                    font.pixelSize: 11
                    MouseArea {
                        id: wipeMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.wipe()
                    }
                }
            }
        }
    }
}
