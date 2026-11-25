import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Power menu. Toggle with: qs ipc call power toggle
GlassPanel {
    id: panel

    property bool canHibernate: false
    property string confirmId: ""
    property string uptime: ""
    readonly property string home: Quickshell.env("HOME")
    // confirm: needs a second press, since it ends running apps
    readonly property var actions: [
        { id: "lock", label: "Lock", key: "L", icon: "\u{F033E}", confirm: false, cmd: [home + "/.config/hypr/scripts/LockScreen.sh"] },
        { id: "suspend", label: "Suspend", key: "U", icon: "\u{F0904}", confirm: false, cmd: ["systemctl", "suspend"] },
        { id: "hibernate", label: "Hibernate", key: "H", icon: "\u{F0717}", confirm: false, cmd: ["systemctl", "hibernate"] },
        { id: "logout", label: "Log out", key: "E", icon: "\u{F0343}", confirm: true, cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { id: "reboot", label: "Reboot", key: "R", icon: "\u{F0709}", confirm: true, cmd: ["systemctl", "reboot"] },
        { id: "shutdown", label: "Shut down", key: "S", icon: "\u{F0425}", confirm: true, cmd: ["systemctl", "poweroff"] }
    ].filter(a => a.id !== "hibernate" || canHibernate)

    cardWidth: 36 + actions.length * 128 + (actions.length - 1) * 12
    cardHeight: 248
    focusItem: keys

    onOpened: {
        confirmId = ""
        infoProc.running = true
    }
    onSelectedChanged: if (confirmId !== "" && actions[selected].id !== confirmId) confirmId = ""

    function run(index) {
        var a = actions[index]
        selected = index
        if (a.confirm && confirmId !== a.id) {
            confirmId = a.id
            confirmTimer.restart()
            return
        }
        close()
        launchTimer.command = a.cmd
        launchTimer.restart()
    }

    // Lets the fade-out finish, so the menu is not on screen when locking or waking up.
    Timer {
        id: launchTimer
        property var command: []
        interval: 200
        onTriggered: Quickshell.execDetached(command)
    }
    Timer { id: confirmTimer; interval: 4000; onTriggered: panel.confirmId = "" }

    Process {
        id: infoProc
        command: ["sh", "-c", "uptime -p; busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n")
                panel.uptime = lines[0]
                panel.canHibernate = lines.length > 1 && lines[1].includes('"yes"')
            }
        }
    }

    IpcHandler {
        target: "power"
        function toggle() { panel.toggle() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            GlassLabel { text: "Power"; color: panel.walForeground; font.pixelSize: 15; font.bold: true }
            Item { Layout.fillWidth: true }
            GlassLabel { text: panel.uptime; color: panel.walMuted; font.pixelSize: 11 }
        }

        Item {
            id: keys
            Layout.fillWidth: true
            Layout.fillHeight: true
            Keys.onPressed: event => {
                var n = panel.actions.length
                event.accepted = true
                if (event.key === Qt.Key_Escape) panel.close()
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) panel.selected = (panel.selected + 1) % n
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) panel.selected = (panel.selected + n - 1) % n
                else if (event.isAutoRepeat) return  // a held key must not confirm itself
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) panel.run(panel.selected)
                else if (event.modifiers === Qt.NoModifier) {
                    var i = panel.actions.findIndex(a => a.key === event.text.toUpperCase())
                    if (i >= 0) panel.run(i)
                }
            }

            Row {
                anchors.fill: parent
                spacing: 12
                Repeater {
                    model: panel.actions
                    Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool active: index === panel.selected
                        readonly property bool asking: panel.confirmId === modelData.id
                        readonly property color tone: asking ? panel.walRed : active ? panel.walAccent : panel.walForeground
                        width: (keys.width - 12 * (panel.actions.length - 1)) / panel.actions.length
                        height: keys.height
                        radius: 15
                        color: asking || active ? panel.tint(tone, 0.2) : panel.surface
                        border.width: active ? 1 : 0
                        border.color: panel.tint(tone, 0.6)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            GlassLabel { anchors.horizontalCenter: parent.horizontalCenter; text: tile.modelData.icon; color: tile.tone; font.pixelSize: 36 }
                            GlassLabel { anchors.horizontalCenter: parent.horizontalCenter; text: tile.modelData.label; color: panel.walForeground }
                            GlassLabel {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.asking ? "Press again" : tile.modelData.key
                                color: tile.asking ? panel.walRed : panel.walMuted
                                font.pixelSize: 11
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: mouse => panel.hover(this, mouse, tile.index)
                            onClicked: panel.run(tile.index)
                        }
                    }
                }
            }
        }
    }
}
