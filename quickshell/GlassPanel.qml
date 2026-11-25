import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Base for centered dark glass popups: dim, card, focus and open/close handling.
// Blur comes from the Hyprland layer rule for "quickshell-glass".
PanelWindow {
    id: panel

    property color walForeground: "#cdd6f4"
    property color walAccent: "#89b4fa"
    property color walMuted: "#6c7086"
    readonly property color walRed: "#f38ba8"
    readonly property color surface: Qt.rgba(1, 1, 1, 0.05)

    property bool open: false
    property int cardWidth: 600
    property int cardHeight: 400
    property Item focusItem: null
    property int selected: 0
    property point lastMouse: Qt.point(-1, -1)
    default property alias content: holder.data

    signal opened()

    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function toggle() { open ? close() : show() }
    function close() { open = false }
    function show() {
        var focused = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        var target = Quickshell.screens.find(s => s.name === focused)
        if (target) screen = target
        lastMouse = Qt.point(-1, -1)
        selected = 0
        opened()
        open = true
        focusTimer.restart()
    }

    // Only real pointer movement selects: not the cursor already there on open, nor content scrolling under it.
    function hover(area, mouse, index) {
        var p = area.mapToItem(null, mouse.x, mouse.y)
        var moved = lastMouse.x >= 0 && (Math.abs(p.x - lastMouse.x) > 2 || Math.abs(p.y - lastMouse.y) > 2)
        if (lastMouse.x < 0 || moved) lastMouse = Qt.point(p.x, p.y)
        if (moved) selected = index
    }

    Timer { id: focusTimer; interval: 0; onTriggered: if (panel.open && panel.focusItem) panel.focusItem.forceActiveFocus() }

    visible: open || card.opacity > 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-glass"
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

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(panel.cardWidth, panel.width - 60)
        height: Math.min(panel.cardHeight, panel.height - 60)
        radius: 20
        color: Qt.rgba(0.035, 0.035, 0.05, 0.72)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        opacity: panel.open ? 1 : 0
        scale: panel.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // clicks on the card do not close it

        Item {
            id: holder
            anchors.fill: parent
            anchors.margins: 18
        }
    }
}
