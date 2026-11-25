import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Monitor layout picker. Toggle with: qs ipc call monitors toggle
PanelWindow {
    id: monitorPanel

    property color walBackground: "#1e1e2e"
    property color walForeground: "#cdd6f4"
    property color walAccent: "#89b4fa"
    property color walGreen: "#a6e3a1"
    property color walRed: "#f38ba8"

    property bool open: false
    property string currentMode: "unknown"
    property string lastError: ""
    property var monitors: []
    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/UserScripts/MonitorMode.sh"

    readonly property var modes: [
        { id: "extend", label: "Extend", desc: "Laptop and external side by side" },
        { id: "duplicate", label: "Duplicate", desc: "External mirrors the laptop" },
        { id: "external", label: "External only", desc: "Turn the laptop panel off" },
        { id: "laptop", label: "Laptop only", desc: "Turn external monitors off" }
    ]

    function toggle() {
        open = !open
        if (open) {
            lastError = ""
            refresh()
            contentRoot.forceActiveFocus()
        }
    }

    function refresh() {
        stateProc.running = true
    }

    function parseState(json) {
        var mons
        try {
            mons = JSON.parse(json)
        } catch (e) {
            return
        }
        monitors = mons

        var internal = mons.find(m => m.name.startsWith("eDP"))
        var externals = mons.filter(m => !m.name.startsWith("eDP") && !m.disabled)

        if (!internal || internal.disabled)
            currentMode = "external"
        else if (externals.length === 0)
            currentMode = "laptop"
        else if (externals.some(m => m.mirrorOf !== "none"))
            currentMode = "duplicate"
        else
            currentMode = "extend"
    }

    function apply(mode) {
        lastError = ""
        applyProc.command = ["bash", scriptPath, mode]
        applyProc.running = true
    }

    Process {
        id: stateProc
        command: ["bash", "-c", "hyprctl monitors all -j | jq -c ."]
        stdout: SplitParser { onRead: data => monitorPanel.parseState(data) }
    }

    Process {
        id: applyProc
        stderr: SplitParser { onRead: data => monitorPanel.lastError = data.trim() }
        onRunningChanged: if (!running) monitorPanel.refresh()
    }

    IpcHandler {
        target: "monitors"
        function toggle() { monitorPanel.toggle() }
    }

    visible: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    focusable: true
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; right: true }
    margins { top: 40; right: open ? 6 : -400 }
    implicitWidth: 340
    implicitHeight: contentRoot.implicitHeight
    color: "transparent"
    Behavior on margins.right { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Rectangle {
        id: contentRoot
        anchors.fill: parent
        implicitHeight: column.implicitHeight + 36
        color: Qt.rgba(monitorPanel.walBackground.r, monitorPanel.walBackground.g, monitorPanel.walBackground.b, 0.7)
        radius: 20
        focus: monitorPanel.open

        Keys.onEscapePressed: monitorPanel.open = false

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Text {
                text: "Monitors"
                color: monitorPanel.walAccent
                font.pixelSize: 16
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
            }

            Repeater {
                model: monitorPanel.monitors

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        Layout.alignment: Qt.AlignVCenter
                        color: modelData.disabled ? monitorPanel.walRed : monitorPanel.walGreen
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name + "  " + (modelData.disabled ? "off" : modelData.width + "x" + modelData.height + " @" + Math.round(modelData.scale * 100) + "%")
                        color: monitorPanel.walForeground
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideRight
                    }
                }
            }

            Repeater {
                model: monitorPanel.modes

                Rectangle {
                    required property var modelData
                    readonly property bool active: monitorPanel.currentMode === modelData.id
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 12
                    color: active ? monitorPanel.walAccent : Qt.rgba(0, 0, 0, 0.3)
                    Behavior on color { ColorAnimation { duration: 200 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        Text {
                            text: modelData.label
                            color: parent.parent.active ? monitorPanel.walBackground : monitorPanel.walForeground
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Text {
                            text: modelData.desc
                            color: parent.parent.active ? monitorPanel.walBackground : monitorPanel.walForeground
                            opacity: 0.7
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monitorPanel.apply(modelData.id)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: monitorPanel.lastError !== "" ? monitorPanel.lastError : "Current: " + monitorPanel.currentMode
                color: monitorPanel.lastError !== "" ? monitorPanel.walRed : monitorPanel.walForeground
                opacity: 0.8
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                wrapMode: Text.WordWrap
            }
        }
    }
}
