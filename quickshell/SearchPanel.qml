import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Web search. Toggle with: qs ipc call websearch toggle
GlassPanel {
    id: panel

    readonly property var engines: [
        { name: "Google", url: "https://www.google.com/search?q=" },
        { name: "YouTube", url: "https://www.youtube.com/results?search_query=" },
        { name: "GitHub", url: "https://github.com/search?q=" },
        { name: "Arch Wiki", url: "https://wiki.archlinux.org/index.php?search=" },
        { name: "Wikipedia", url: "https://en.wikipedia.org/w/index.php?search=" },
        { name: "Maps", url: "https://www.google.com/maps/search/" }
    ]
    readonly property string query: input.text.trim()
    // A typed address opens directly instead of being searched.
    readonly property string address: {
        if (/^https?:\/\/\S+$/i.test(query)) return query
        if (/^localhost(:\d+)?(\/\S*)?$/i.test(query)) return "http://" + query
        if (/^([a-z0-9-]+\.)+(com|org|net|io|dev|app|fr|ai|co|me|gg|tv|info|eu|uk|be|ch|ca)(:\d+)?([\/?#]\S*)?$/i.test(query)) return "https://" + query
        return ""
    }

    cardWidth: 640
    cardHeight: 148
    focusItem: input
    onOpened: input.text = ""

    function submit() {
        if (query === "") return
        Quickshell.execDetached(["xdg-open", address !== "" ? address : engines[selected].url + encodeURIComponent(query)])
        close()
    }

    IpcHandler {
        target: "websearch"
        function toggle() { panel.toggle() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: 14
            color: panel.surface
            border.width: 1
            border.color: panel.tint(panel.walAccent, 0.6)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12
                GlassLabel { text: panel.address !== "" ? "\u{F0339}" : "\u{F0349}"; color: panel.walMuted; font.pixelSize: 18 }
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: panel.walForeground
                    selectionColor: panel.tint(panel.walAccent, 0.5)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    selectByMouse: true
                    clip: true
                    GlassLabel {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !input.text
                        text: "Search " + panel.engines[panel.selected].name + " or type an address..."
                        color: panel.walMuted
                        font.pixelSize: 16
                    }
                    Keys.onPressed: event => {
                        var n = panel.engines.length
                        event.accepted = true
                        if (event.key === Qt.Key_Escape) panel.close()
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) panel.submit()
                        else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) panel.selected = (panel.selected + 1) % n
                        else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) panel.selected = (panel.selected + n - 1) % n
                        else event.accepted = false
                    }
                }
                GlassLabel { visible: panel.query !== ""; text: panel.address !== "" ? "Open \u{F0311}" : "\u{F0311}"; color: panel.walMuted; font.pixelSize: 14 }
            }
        }

        Row {
            id: chips
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            opacity: panel.address !== "" ? 0.35 : 1
            Repeater {
                model: panel.engines
                Rectangle {
                    id: chip
                    required property var modelData
                    required property int index
                    readonly property bool active: index === panel.selected
                    width: (chips.width - 8 * (panel.engines.length - 1)) / panel.engines.length
                    height: 36
                    radius: 10
                    color: active ? panel.walAccent : chipMouse.containsMouse ? panel.tint(panel.walForeground, 0.12) : panel.surface
                    Behavior on color { ColorAnimation { duration: 120 } }
                    GlassLabel {
                        anchors.centerIn: parent
                        text: chip.modelData.name
                        font.pixelSize: 12
                        font.bold: chip.active
                        color: chip.active ? "#0b0b0f" : panel.walForeground
                    }
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { panel.selected = chip.index; input.forceActiveFocus() }
                    }
                }
            }
        }
    }
}
