import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Display picker, on the shared dark glass base (GlassPanel.qml).
// Toggle with: qs ipc call monitors toggle. Keys: 1-4 pick a mode, Esc closes.
GlassPanel {
    id: panel

    cardWidth: 420
    cardHeight: body.implicitHeight + 36
    focusItem: keyCatcher

    readonly property color errorColor: "#E8757E"
    readonly property color onAccent: "#101015"
    readonly property string mono: "JetBrainsMono Nerd Font"

    onOpened: { lastError = ""; refresh() }
    property bool busy: false
    property string currentMode: "unknown"
    property string side: "right"
    property real laptopScale: 1.25
    property string lastError: ""
    property var monitors: []

    readonly property string home: Quickshell.env("HOME")
    readonly property string scriptPath: home + "/.config/hypr/UserScripts/MonitorMode.sh"
    readonly property string layoutFile: home + "/.config/hypr/lua/monitor_mode.lua"

    readonly property var modes: [
        { id: "extend", label: "Extend", desc: "Side by side" },
        { id: "duplicate", label: "Duplicate", desc: "Same picture" },
        { id: "external", label: "External", desc: "Laptop off" },
        { id: "laptop", label: "Laptop", desc: "Externals off" }
    ]
    readonly property var sides: [
        { id: "left", label: "Left" }, { id: "right", label: "Right" },
        { id: "up", label: "Above" }, { id: "down", label: "Below" }
    ]
    readonly property var scales: [1, 1.2, 1.25, 1.5]

    readonly property int externalCount: monitors.filter(m => !m.name.startsWith("eDP")).length
    readonly property int activeCount: monitors.filter(m => !m.disabled).length

    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function isVirtual(m) { return !m.make && !m.description }
    function nameOf(id) {
        var m = monitors.find(x => String(x.id) === String(id))
        return m ? m.name : String(id)
    }
    function needsExternal(modeId) { return modeId !== "laptop" }
    function available(modeId) { return !needsExternal(modeId) || externalCount > 0 }

    function detail(m) {
        if (m.disabled) return "Off"
        var parts = []
        if (isVirtual(m)) parts.push("virtual")
        parts.push(m.width + "×" + m.height)
        if (!isVirtual(m)) parts.push(Math.round(m.refreshRate) + " Hz")
        if (m.mirrorOf !== "none") parts.push("mirror")
        else parts.push(Math.round(m.scale * 100) + "%")
        return parts.join("  ")
    }

    function refresh() {
        stateProc.running = true
        headerProc.running = true
    }

    function parseState(json) {
        var mons
        try { mons = JSON.parse(json) } catch (e) { return }
        monitors = mons
        var internal = mons.find(m => m.name.startsWith("eDP"))
        var externals = mons.filter(m => !m.name.startsWith("eDP") && !m.disabled)
        if (internal && !internal.disabled) laptopScale = internal.scale
        if (!internal || internal.disabled) currentMode = "external"
        else if (externals.length === 0) currentMode = "laptop"
        else if (externals.some(m => m.mirrorOf !== "none")) currentMode = "duplicate"
        else currentMode = "extend"
    }

    function parseHeader(line) {
        var m = /side=(left|right|up|down)/.exec(line)
        if (m) side = m[1]
    }

    function apply(modeId) {
        if (busy || !available(modeId)) return
        lastError = ""
        busy = true
        applyProc.command = ["bash", scriptPath, modeId, "--side", side, "--scale", String(laptopScale)]
        applyProc.running = true
    }

    function setSide(s) {
        side = s
        if (currentMode === "extend") apply("extend")
    }

    function setScale(s) {
        laptopScale = s
        if (currentMode !== "external" && currentMode !== "unknown") apply(currentMode)
    }

    // Scaled boxes for the arrangement preview.
    function layoutBoxes(areaW, areaH) {
        var on = monitors.filter(m => !m.disabled)
        if (on.length === 0) return []
        var placed = on.filter(m => m.mirrorOf === "none")
        if (placed.length === 0) placed = on
        var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9
        placed.forEach(m => {
            var w = m.width / m.scale, h = m.height / m.scale
            minX = Math.min(minX, m.x); minY = Math.min(minY, m.y)
            maxX = Math.max(maxX, m.x + w); maxY = Math.max(maxY, m.y + h)
        })
        var k = Math.min(areaW / (maxX - minX), areaH / (maxY - minY)) * 0.9
        var offX = (areaW - (maxX - minX) * k) / 2, offY = (areaH - (maxY - minY) * k) / 2
        var boxes = []
        var mirrorStep = 0
        on.forEach(m => {
            var mirror = m.mirrorOf !== "none"
            var src = mirror ? monitors.find(x => String(x.id) === String(m.mirrorOf)) : m
            if (!src) src = m
            var w = src.width / src.scale, h = src.height / src.scale
            if (mirror) mirrorStep += 1
            boxes.push({
                name: m.name,
                mirror: mirror,
                primary: m.name.startsWith("eDP"),
                x: offX + (src.x - minX) * k + (mirror ? mirrorStep * 7 : 0),
                y: offY + (src.y - minY) * k + (mirror ? mirrorStep * 7 : 0),
                w: w * k, h: h * k
            })
        })
        // mirrors drawn first so the real screen sits on top
        return boxes.sort((a, b) => (b.mirror ? 1 : 0) - (a.mirror ? 1 : 0))
    }

    Process {
        id: stateProc
        command: ["bash", "-c", "hyprctl monitors all -j | jq -c ."]
        stdout: SplitParser { onRead: data => panel.parseState(data) }
    }

    Process {
        id: headerProc
        command: ["head", "-n1", panel.layoutFile]
        stdout: SplitParser { onRead: data => panel.parseHeader(data) }
    }

    Process {
        id: applyProc
        stderr: SplitParser { onRead: data => panel.lastError = data.trim() }
        onRunningChanged: if (!running) { panel.busy = false; panel.refresh() }
    }

    IpcHandler {
        target: "monitors"
        function toggle() { panel.toggle() }
    }

    // ---------- small building blocks ----------

    component Label: Text {
        color: panel.walForeground
        font.family: panel.mono
        font.pixelSize: 12
        textFormat: Text.PlainText
    }

    component SectionTitle: Label {
        color: panel.walMuted
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    // Tiny drawing of a mode: laptop (small) + external (large).
    component Pictogram: Item {
        id: pic
        property string kind: "extend"
        property color ink: panel.walForeground
        implicitWidth: 46
        implicitHeight: 28

        readonly property bool laptopOn: kind !== "external"
        readonly property bool externalOn: kind !== "laptop"

        Rectangle {   // external
            width: 26; height: 17; radius: 3
            x: pic.kind === "duplicate" ? 14 : 20
            y: pic.kind === "duplicate" ? 2 : 4
            color: pic.externalOn ? panel.tint(pic.ink, pic.kind === "duplicate" ? 0.35 : 0.9) : "transparent"
            border.width: 1.5
            border.color: panel.tint(pic.ink, pic.externalOn ? 0.9 : 0.35)
        }
        Rectangle {   // laptop
            width: 18; height: 12; radius: 2
            x: pic.kind === "duplicate" ? 6 : 0
            y: pic.kind === "duplicate" ? 12 : 9
            color: pic.laptopOn ? panel.tint(pic.ink, 0.9) : "transparent"
            border.width: 1.5
            border.color: panel.tint(pic.ink, pic.laptopOn ? 0.9 : 0.35)
        }
        Rectangle {   // laptop base
            width: 22; height: 2; radius: 1
            x: pic.kind === "duplicate" ? 4 : -2
            y: pic.kind === "duplicate" ? 25 : 22
            color: panel.tint(pic.ink, pic.laptopOn ? 0.9 : 0.35)
        }
    }

    // Row of pills, one selected.
    component Segmented: RowLayout {
        id: seg
        property var options: []        // [{ id, label }]
        property var current
        property bool enabledState: true
        signal picked(var id)
        spacing: 4
        Layout.fillWidth: true
        opacity: enabledState ? 1 : 0.4

        Repeater {
            model: seg.options
            Rectangle {
                required property var modelData
                readonly property bool on: String(seg.current) === String(modelData.id)
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 8
                color: on ? panel.walAccent : (pillMouse.containsMouse && seg.enabledState ? panel.tint(panel.walForeground, 0.08) : panel.surface)
                Behavior on color { ColorAnimation { duration: 140 } }
                Label {
                    anchors.centerIn: parent
                    text: modelData.label
                    font.pixelSize: 11
                    color: parent.on ? panel.onAccent : panel.walForeground
                    font.bold: parent.on
                }
                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: seg.enabledState && !panel.busy
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.picked(modelData.id)
                }
            }
        }
    }

    // ---------- card ----------

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: panel.close()
        Keys.onPressed: event => {
            var i = event.key - Qt.Key_1
            if (i >= 0 && i < panel.modes.length) { panel.apply(panel.modes[i].id); event.accepted = true }
        }

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 10

            // header
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "Displays"
                    font.pixelSize: 17
                    font.bold: true
                    Layout.fillWidth: true
                }
                Label {
                    text: panel.activeCount + " of " + panel.monitors.length + " on"
                    opacity: 0.5
                    font.pixelSize: 11
                }
            }

            // arrangement preview
            Rectangle {
                id: preview
                Layout.fillWidth: true
                Layout.preferredHeight: 118
                radius: 12
                color: panel.surface
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.06)

                Item {
                    id: stage
                    anchors.fill: parent
                    anchors.margins: 12
                    Repeater {
                        model: panel.layoutBoxes(stage.width, stage.height)
                        Rectangle {
                            required property var modelData
                            x: modelData.x; y: modelData.y
                            width: modelData.w; height: modelData.h
                            radius: 5
                            color: modelData.mirror ? "transparent"
                                 : modelData.primary ? panel.tint(panel.walAccent, 0.28)
                                 : panel.tint(panel.walForeground, 0.12)
                            border.width: 1
                            border.color: modelData.mirror ? panel.tint(panel.walForeground, 0.25)
                                        : modelData.primary ? panel.walAccent : panel.tint(panel.walForeground, 0.4)
                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Label {
                                visible: !modelData.mirror
                                anchors.centerIn: parent
                                text: modelData.name
                                font.pixelSize: 10
                                opacity: 0.85
                            }
                        }
                    }
                }
            }

            // monitor list
            Repeater {
                model: panel.monitors
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        Layout.alignment: Qt.AlignVCenter
                        color: modelData.disabled ? panel.tint(panel.walForeground, 0.25) : panel.walAccent
                    }
                    Label {
                        text: modelData.name
                        font.bold: true
                        Layout.preferredWidth: 110
                        elide: Text.ElideRight
                    }
                    Label {
                        text: panel.detail(modelData)
                        opacity: 0.6
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            // modes
            SectionTitle { text: "Mode" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8
                Repeater {
                    model: panel.modes
                    Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool active: panel.currentMode === modelData.id
                        readonly property bool usable: panel.available(modelData.id)
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        radius: 12
                        opacity: usable ? 1 : 0.35
                        color: active ? panel.tint(panel.walAccent, 0.14)
                             : tileMouse.containsMouse && usable ? panel.tint(panel.walForeground, 0.07)
                             : panel.surface
                        border.width: 1
                        border.color: active ? panel.walAccent : Qt.rgba(1, 1, 1, 0.06)
                        Behavior on color { ColorAnimation { duration: 160 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 10
                            Pictogram {
                                kind: tile.modelData.id
                                ink: tile.active ? panel.walAccent : panel.walForeground
                                Layout.alignment: Qt.AlignVCenter
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Label {
                                    text: tile.modelData.label
                                    font.bold: true
                                    color: panel.walForeground
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Label {
                                    text: tile.modelData.desc
                                    opacity: 0.55
                                    font.pixelSize: 10
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        Label {   // keyboard hint
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 7
                            text: String(tile.index + 1)
                            font.pixelSize: 9
                            opacity: 0.35
                        }
                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: tile.usable && !panel.busy
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.apply(tile.modelData.id)
                        }
                    }
                }
            }

            // placement
            SectionTitle { text: "Extended screen goes" }
            Segmented {
                options: panel.sides
                current: panel.side
                enabledState: panel.externalCount > 0
                onPicked: id => panel.setSide(id)
            }

            // laptop scale
            SectionTitle { text: "Laptop scale" }
            Segmented {
                options: panel.scales.map(s => ({ id: s, label: Math.round(s * 100) + "%" }))
                current: panel.laptopScale
                enabledState: panel.currentMode !== "external"
                onPicked: id => panel.setScale(id)
            }

            // status
            Label {
                Layout.fillWidth: true
                Layout.topMargin: 4
                wrapMode: Text.WordWrap
                font.pixelSize: 10
                text: panel.busy ? "Applying…"
                    : panel.lastError !== "" ? panel.lastError
                    : panel.externalCount === 0 ? "No external screen connected"
                    : "Press 1–4 to switch, Esc to close"
                color: panel.lastError !== "" ? panel.errorColor : panel.walForeground
                opacity: panel.lastError !== "" ? 1 : 0.4
            }
        }
    }
}
