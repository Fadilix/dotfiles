import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Wallpaper picker. Toggle with: qs ipc call wallpaper toggle
GlassPanel {
    id: panel

    cardWidth: 1180
    cardHeight: 760
    focusItem: input

    property string current: ""
    signal applyRequested(string path)

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/Pictures/wallpapers/Downloaded/walls"
    readonly property string thumbDir: home + "/.cache/wallpaper-thumbs-400"
    readonly property int columns: 5
    property var walls: []
    property bool loaded: false

    readonly property string query: input.text.trim().toLowerCase()
    readonly property var filtered: query === "" ? walls : walls.filter(w => w.key.indexOf(query) >= 0)
    readonly property var selectedWall: filtered[selected] || null
    readonly property string currentName: current.split("/").pop()

    function load() { listProc.running = true }
    function select(i) {
        if (filtered.length === 0) return
        selected = Math.max(0, Math.min(filtered.length - 1, i))
        grid.positionViewAtIndex(selected, GridView.Contain)
    }
    function selectCurrent() {
        var i = filtered.findIndex(w => w.path === current)
        if (i >= 0) { selected = i; grid.positionViewAtIndex(i, GridView.Center) }
    }
    function apply(w, stay) {
        if (!w) return
        applyRequested(w.path)
        if (!stay) close()
    }

    onOpened: {
        input.text = ""
        if (!loaded) load()
        else selectCurrent()
    }
    onQueryChanged: selected = 0

    Process {
        id: listProc
        command: ["find", panel.dir, "-maxdepth", "1", "-type", "f",
                  "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png",
                  "-o", "-iname", "*.webp", "-o", "-iname", "*.gif", ")", "!", "-name", ".*"]
        stdout: StdioCollector {
            onStreamFinished: {
                panel.walls = text.split("\n").filter(p => p.length).sort().map(p => {
                    var name = p.split("/").pop()
                    return { path: p, name: name, key: name.toLowerCase(), thumb: panel.thumbDir + "/" + Qt.md5(p) + ".jpg" }
                })
                panel.loaded = true
                panel.selectCurrent()
                thumbProc.running = true
            }
        }
    }

    // Builds 400x250 thumbnails for any wallpaper that lacks a fresh one, four at a time.
    Process {
        id: thumbProc
        command: ["bash", "-c",
            'mkdir -p "$2"; find "$1" -maxdepth 1 -type f ! -name ".*" -print0 | ' +
            'xargs -0 -P4 -I{} bash -c \'f="$1"; t="$2/$(printf %s "$f" | md5sum | cut -d" " -f1).jpg"; ' +
            '[ -f "$t" ] && [ "$t" -nt "$f" ] && exit 0; ' +
            'case "$f" in *.gif|*.GIF) magick "$f[0]" -thumbnail 400x250^ -gravity center -extent 400x250 -quality 82 "$t" ;; ' +
            '*) vipsthumbnail "$f" -s 400x250 --smartcrop centre -o "$t[Q=82,strip]" ;; esac 2>/dev/null\' _ {} "$2"',
            "_", panel.dir, panel.thumbDir]
        onExited: panel.thumbsDone = true
    }
    property bool thumbsDone: false

    IpcHandler {
        target: "wallpaper"
        function toggle() { panel.toggle() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0


        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 52
            Layout.maximumHeight: 52
            spacing: 14
            GlassLabel {
                text: "WALLS"
                color: panel.walAccent
                font.pixelSize: 11
                font.letterSpacing: 1.5
                font.bold: true
            }
            TextInput {
                id: input
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                color: panel.walForeground
                selectionColor: panel.tint(panel.walAccent, 0.4)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                clip: true
                GlassLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !input.text
                    text: "Filter by file name"
                    color: panel.walMuted
                    font.pixelSize: 20
                }
                Keys.onPressed: event => {
                    var ctrl = event.modifiers & Qt.ControlModifier
                    var n = panel.columns
                    event.accepted = true
                    if (event.key === Qt.Key_Escape) panel.close()
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        panel.apply(panel.selectedWall, event.modifiers & Qt.ShiftModifier)
                    else if (event.key === Qt.Key_Right || (ctrl && event.key === Qt.Key_L) || event.key === Qt.Key_Tab) panel.select(panel.selected + 1)
                    else if (event.key === Qt.Key_Left || (ctrl && event.key === Qt.Key_H) || event.key === Qt.Key_Backtab) panel.select(panel.selected - 1)
                    else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) panel.select(panel.selected + n)
                    else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) panel.select(panel.selected - n)
                    else if (event.key === Qt.Key_PageDown) panel.select(panel.selected + n * 3)
                    else if (event.key === Qt.Key_PageUp) panel.select(panel.selected - n * 3)
                    else if (ctrl && event.key === Qt.Key_R && panel.filtered.length > 0) {
                        panel.select(Math.floor(Math.random() * panel.filtered.length))
                        panel.apply(panel.selectedWall, true)
                    }
                    else if (ctrl && event.key === Qt.Key_G) panel.selectCurrent()
                    else if (ctrl && event.key === Qt.Key_U) input.text = ""
                    else event.accepted = false
                }
            }
            GlassLabel {
                text: panel.filtered.length + " of " + panel.walls.length
                color: panel.walMuted
                font.pixelSize: 11
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: panel.tint(panel.walForeground, 0.1) }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 14
            clip: true
            model: panel.filtered
            cellWidth: width / panel.columns
            cellHeight: cellWidth * 0.625 + 26
            boundsBehavior: Flickable.StopAtBounds
            // Keep about two screens of tiles alive so scrolling never waits on image decoding.
            cacheBuffer: Math.max(0, height * 2)
            reuseItems: true
            interactive: false   // SmoothScroll does the scrolling

            SmoothScroll { parent: grid; flickable: grid; wheelStep: grid.cellHeight * 0.8 }

            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                readonly property bool active: index === panel.selected
                readonly property bool isCurrent: modelData.path === panel.current
                width: grid.cellWidth
                height: grid.cellHeight

                ClippingRectangle {
                    id: frame
                    x: 5; y: 5
                    width: parent.width - 10
                    height: width * 0.625
                    radius: 8
                    color: panel.tint(panel.walForeground, 0.05)
                    opacity: tile.active ? 1 : 0.82
                    Image {
                        anchors.fill: parent
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(400, 250)
                        source: "file://" + tile.modelData.thumb
                        onStatusChanged: if (status === Image.Error) source = "file://" + tile.modelData.path
                    }
                    Rectangle {
                        visible: tile.isCurrent
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        width: currentTag.implicitWidth + 14
                        height: 20
                        color: Qt.rgba(0, 0, 0, 0.7)
                        GlassLabel {
                            id: currentTag
                            anchors.centerIn: parent
                            text: "CURRENT"
                            color: "#ffffff"
                            font.pixelSize: 9
                            font.letterSpacing: 1.5
                        }
                    }
                }
                Rectangle {
                    anchors.fill: frame
                    anchors.margins: -3
                    radius: 10
                    color: "transparent"
                    border.width: 2
                    border.color: panel.walAccent
                    visible: tile.active
                }
                GlassLabel {
                    anchors.top: frame.bottom
                    anchors.topMargin: 6
                    anchors.left: frame.left
                    width: frame.width
                    text: tile.modelData.name
                    color: tile.active ? panel.walForeground : panel.walMuted
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: mouse => panel.hover(this, mouse, tile.index)
                    onClicked: panel.apply(tile.modelData, false)
                }
            }

            GlassLabel {
                anchors.centerIn: parent
                visible: panel.loaded && panel.filtered.length === 0
                text: "No wallpaper matches"
                color: panel.walMuted
                font.pixelSize: 14
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: panel.tint(panel.walForeground, 0.1) }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            GlassLabel {
                text: "enter apply    shift enter apply and stay    arrows or ctrl hjkl move    ctrl r random    ctrl g current    esc close"
                color: panel.walMuted
                font.pixelSize: 10
            }
            Item { Layout.fillWidth: true }
            GlassLabel {
                text: panel.currentName === "" ? "" : "now  " + panel.currentName
                color: panel.walMuted
                font.pixelSize: 10
                elide: Text.ElideMiddle
                Layout.maximumWidth: 260
            }
        }
    }
}
