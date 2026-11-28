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
    property real cardY: -1                 // -1 centers the card vertically
    property real dimOpacity: 0.3
    property real cardRadius: 20
    property color cardColor: Qt.rgba(0.035, 0.035, 0.05, 0.72)
    property color cardBorder: Qt.rgba(1, 1, 1, 0.1)
    property real contentMargin: 18
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
        opacity: card.opacity * panel.dimOpacity
    }
    MouseArea {
        anchors.fill: parent
        onClicked: panel.close()
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(panel.cardWidth, panel.width - 60)
        height: Math.min(panel.cardHeight, panel.height - 60)
        y: panel.cardY >= 0 ? panel.cardY : (parent.height - height) / 2
        radius: panel.cardRadius
        color: panel.cardColor
        border.width: 1
        border.color: panel.cardBorder
        // Appears at once on open; only the close fades, so opening never waits on an animation.
        opacity: panel.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: panel.open ? 0 : 90; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // clicks on the card do not close it

        Item {
            id: holder
            anchors.fill: parent
            anchors.margins: panel.contentMargin
        }
    }
}
