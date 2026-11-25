import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

ShellRoot {
    id: root

    property string mcqMessage: ""
    property bool mcqBusy: false

    function captureMcq() {
        if (mcqBusy)
            return;
        mcqBusy = true;
        mcqMessage = "";
        mcqHideTimer.stop();
        mcqCaptureProcess.exec(["sh", decodeURIComponent(new URL(Qt.resolvedUrl("capture-and-ask.sh")).pathname)]);
    }

    function showMcqResult(text) {
        mcqBusy = false;
        mcqMessage = text.trim() || "No answer returned";
        mcqHideTimer.restart();
    }

    function handleMcqOutput(line) {
        const output = line.trim();
        if (output === "__MOODCQ_CAPTURED__")
            return;
        showMcqResult(output);
    }

    GlobalShortcut {
        appid: "moodcq"
        name: "mcq-screenshot"
        description: "Capture the screen and read a multiple-choice question"
        onPressed: root.captureMcq()
    }

    Process {
        id: mcqCaptureProcess
        stdout: SplitParser {
            onRead: data => root.handleMcqOutput(data)
        }
        onExited: {
            if (root.mcqBusy)
                root.showMcqResult("No answer returned")
        }
    }

    Timer {
        id: mcqHideTimer
        interval: 5000
        onTriggered: root.mcqMessage = ""
    }

    MonitorPanel {
        walBackground: root.walBackground
        walForeground: root.walForeground
        walAccent: root.walColor5
        walGreen: root.walColor2
        walRed: root.walColor1
    }

    ClipboardPanel {
        walForeground: root.walForeground
        walAccent: root.walColor5
        walMuted: root.walColor8
        walRed: "#f38ba8"
    }

    EmojiPanel {
        walForeground: root.walForeground
        walAccent: root.walColor5
        walMuted: root.walColor8
    }

    PowerPanel {
        walForeground: root.walForeground
        walAccent: root.walColor5
        walMuted: root.walColor8
    }

    SearchPanel {
        walForeground: root.walForeground
        walAccent: root.walColor5
        walMuted: root.walColor8
    }

    KeybindsPanel {
        walForeground: root.walForeground
        walAccent: root.walColor5
        walMuted: root.walColor8
    }

    property bool dashboardVisible: false
    property bool musicVisible: false
    property bool launcherVisible: false
    property bool wifiVisible: false
    property bool btVisible: false
    property var pfpFiles: []
    property string searchTerm: ""
    // The native catalog watches XDG application directories, including Flatpak.
    readonly property var appList: DesktopEntries.applications.values.map(entry => ({
        name: entry.name,
        exec: entry.execString,
        icon: entry.icon,
        desktopEntry: entry
    }))
    property var appUsage: ({})
    property var filteredApps: {
        var source = appList
        var usage = appUsage
        if (searchTerm !== "") {
            var result = []
            for (var i = 0; i < source.length; i++) {
                var entry = source[i]
                if (entry.name.toLowerCase().includes(searchTerm) || entry.exec.toLowerCase().includes(searchTerm)) {
                    result.push(entry)
                }
            }
            source = result
        }
        var sorted = source.slice().sort(function(a, b) {
            var countA = usage[a.name] || 0
            var countB = usage[b.name] || 0
            if (countB !== countA) return countB - countA
            return a.name.localeCompare(b.name)
        })
        return sorted
    }
    property int selectedIndex: 0
    property int activeTab: 0
    property string wallSearchTerm: ""
    property var wallpaperList: []
    property var filteredWallpapers: {
        if (wallSearchTerm === "") return wallpaperList
        var result = []
        for (var i = 0; i < wallpaperList.length; i++) {
            if (wallpaperList[i].name.toLowerCase().includes(wallSearchTerm)) {
                result.push(wallpaperList[i])
            }
        }
        return result
    }
    property int wallSelectedIndex: 0
    property string currentWallpaper: ""
    property bool wallsLoaded: false
    property bool thumbsReady: false
    property bool walApplying: false

    property bool wifiEnabled: true
    property string wifiCurrentSSID: ""
    property int wifiSignal: 0
    property var wifiNetworks: []
    property bool wifiScanning: false
    property string wifiPasswordSSID: ""
    property bool wifiConnecting: false

    property bool btEnabled: true
    property var btPairedDevices: []
    property var btAvailableDevices: []
    property bool btScanning: false
    property string btConnectingMAC: ""

    property color walBackground: "#1e1e2e"
    property color walForeground: "#cdd6f4"
    property color walColor1: "#f38ba8"
    property color walColor2: "#a6e3a1"
    property color walColor4: "#f9e2af"
    property color walColor5: "#89b4fa"
    property color walColor8: "#6c7086"
    property color walColor13: "#f5c2e7"

    property int monitorWidth: 1920
    property int monitorHeight: 1080

    function warpTo(x, y) {
        warpCursorProc.command = ["hyprctl", "dispatch",
            "hl.dsp.cursor.move({ x = " + Math.round(x) + ", y = " + Math.round(y) + " })"]
        warpCursorProc.running = true
    }

    function toggleLauncher() {
        launcherVisible = !launcherVisible
        if (launcherVisible) {
            // Screen geometry is in logical coordinates, including scale and offset.
            warpTo(launcherPanel.screen.x + 6 + launcherPanel.width / 2,
                   launcherPanel.screen.y + launcherPanel.margins.top + launcherPanel.height / 2)
        }
    }

    function toggleDashboard() {
        dashboardVisible = !dashboardVisible
        if (dashboardVisible) { wifiVisible = false; btVisible = false; warpTo(monitorWidth - 210, monitorHeight / 2) }
    }
    function toggleMusic() {
        musicVisible = !musicVisible
        if (musicVisible) warpTo(monitorWidth / 2, 136)
    }

    function toggleWifi() {
        wifiVisible = !wifiVisible
        if (wifiVisible) { btVisible = false; dashboardVisible = false; refreshWifi(); warpTo(monitorWidth - 160, 250) }
    }

    function toggleBluetooth() {
        btVisible = !btVisible
        if (btVisible) { wifiVisible = false; dashboardVisible = false; refreshBluetooth(); warpTo(monitorWidth - 160, 270) }
    }

    function refreshBluetooth() {
        root.btPairedDevices = []
        root.btAvailableDevices = []
        root.btScanning = false
        root.btConnectingMAC = ""
        btStatusProc.running = true
    }

    function connectBt(mac) {
        root.btConnectingMAC = mac
        btActionProc.command = ["bash", "-c", "(echo 'trust " + mac + "'; echo 'connect " + mac + "'; sleep 2; echo 'quit') | bluetoothctl 2>/dev/null"]
        btActionProc.running = true
    }

    function disconnectBt(mac) {
        btActionProc.command = ["bash", "-c", "echo -e 'disconnect " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
        btActionProc.running = true
    }

    function pairBt(mac) {
        root.btConnectingMAC = mac
        btActionProc.command = ["bash", "-c", "echo -e 'pair " + mac + "\\nquit' | bluetoothctl 2>/dev/null; sleep 2; echo -e 'trust " + mac + "\\nquit' | bluetoothctl 2>/dev/null; sleep 1; echo -e 'connect " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
        btActionProc.running = true
    }

    function forgetBt(mac) {
        btActionProc.command = ["bash", "-c", "echo -e 'remove " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
        btActionProc.running = true
    }

    function refreshWifi() {
        root.wifiNetworks = []
        root.wifiScanning = true
        wifiStatusProc.running = true
        wifiCurrentProc.running = true
        wifiScanProc.running = true
    }

    Component.onCompleted: {
        walColorsProc.running = true
        loadUsageProc.running = true
        currentWallProc.running = true
        thumbDirProc.running = true
        monitorInfoProc.running = true
    }

    Process {
        id: monitorInfoProc
        command: ["bash", "-c", "hyprctl monitors -j"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var monitors = JSON.parse(data)
                    if (monitors.length > 0) {
                        root.monitorWidth = monitors[0].width
                        root.monitorHeight = monitors[0].height
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: warpCursorProc
        command: ["bash", "-c", "true"]
    }

    function launchApp(app) {
        app.desktopEntry.execute()
        var usage = appUsage
        var updated = {}
        for (var key in usage) updated[key] = usage[key]
        updated[app.name] = (updated[app.name] || 0) + 1
        appUsage = updated
        saveUsageProc.command = ["bash", "-c", "echo '" + JSON.stringify(updated) + "' > /home/fadilix/.config/quickshell/app_usage.json"]
        saveUsageProc.running = true
        root.launcherVisible = false
        searchInput.text = ""
    }

    function applyWallpaper(wallpaper) {
        root.currentWallpaper = wallpaper.path
        root.walApplying = true
        applyWallProc.command = ["bash", "-c",
            "ln -sf '" + wallpaper.path + "' ~/Pictures/wallpapers/Downloaded/walls/current && " +
            "(awww query >/dev/null 2>&1 || awww-daemon --format xrgb >/dev/null 2>&1 &) && " +
            "awww img '" + wallpaper.path + "' --transition-type any --transition-duration 2 && " +
            "python3 -c \"import pywal; img=pywal.image.get('" + wallpaper.path + "'); c=pywal.colors.get(img); pywal.export.every(c)\" && " +
            "sleep 0.3"
        ]
        applyWallProc.running = true
    }

    function loadWallpapers() {
        root.wallpaperList = []
        root.wallsLoaded = false
        root.thumbsReady = false
        wallpaperListProc.running = true
    }

    Process {
        id: thumbDirProc
        command: ["bash", "-c", "mkdir -p ~/.cache/wallpaper-thumbs"]
        onExited: root.loadWallpapers()
    }

    Process {
        id: wallpaperListProc
        command: ["bash", "-c", "find ~/Pictures/wallpapers/Downloaded/walls -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' | sort"]
        stdout: SplitParser {
            onRead: data => {
                var path = data.trim()
                if (path.length === 0) return
                var parts = path.split("/")
                var name = parts[parts.length - 1]
                var current = root.wallpaperList.slice()
                current.push({ name: name, path: path })
                root.wallpaperList = current
            }
        }
        onExited: {
            root.wallsLoaded = true
            thumbGenProc.running = true
        }
    }

    Process {
        id: thumbGenProc
        command: ["bash", "-c",
            "cd ~/.cache/wallpaper-thumbs && " +
            "if command -v vipsthumbnail >/dev/null 2>&1; then " +
            "  find ~/Pictures/wallpapers/Downloaded/walls -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' | " +
            "  while IFS= read -r f; do " +
            "    hash=$(echo -n \"$f\" | md5sum | cut -d' ' -f1); " +
            "    thumb=\"$HOME/.cache/wallpaper-thumbs/${hash}.jpg\"; " +
            "    if [ ! -f \"$thumb\" ] || [ \"$f\" -nt \"$thumb\" ]; then " +
            "      case \"$f\" in " +
            "        *.gif) convert \"${f}[0]\" -define jpeg:size=400x300 -thumbnail 180x120^ -gravity center -extent 180x120 -strip -interlace none -quality 85 \"$thumb\" 2>/dev/null & ;; " +
            "        *) vipsthumbnail \"$f\" -s 180x120 -c \"jpegsave $thumb[Q=85,strip]\" 2>/dev/null || " +
            "           convert \"$f\" -define jpeg:size=400x300 -thumbnail 180x120^ -gravity center -extent 180x120 -strip -interlace none -quality 85 \"$thumb\" 2>/dev/null & ;; " +
            "      esac; " +
            "    fi; " +
            "  done; " +
            "else " +
            "  find ~/Pictures/wallpapers/Downloaded/walls -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' | " +
            "  while IFS= read -r f; do " +
            "    hash=$(echo -n \"$f\" | md5sum | cut -d' ' -f1); " +
            "    thumb=\"$HOME/.cache/wallpaper-thumbs/${hash}.jpg\"; " +
            "    if [ ! -f \"$thumb\" ] || [ \"$f\" -nt \"$thumb\" ]; then " +
            "      case \"$f\" in " +
            "        *.gif) convert \"${f}[0]\" -define jpeg:size=400x300 -thumbnail 180x120^ -gravity center -extent 180x120 -strip -interlace none -quality 85 \"$thumb\" 2>/dev/null & ;; " +
            "        *) convert \"$f\" -define jpeg:size=400x300 -thumbnail 180x120^ -gravity center -extent 180x120 -strip -interlace none -quality 85 \"$thumb\" 2>/dev/null & ;; " +
            "      esac; " +
            "    fi; " +
            "  done; " +
            "fi; wait"
        ]
        onExited: root.thumbsReady = true
    }

    Process {
        id: applyWallProc
        onExited: walColorsProc.running = true
    }

    Process {
        id: walColorsProc
        command: ["bash", "-c", "cat /home/fadilix/.cache/wal/colors.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var json = JSON.parse(data)
                    if (json.special) {
                        root.walBackground = json.special.background || root.walBackground
                        root.walForeground = json.special.foreground || root.walForeground
                    }
                    if (json.colors) {
                        root.walColor1 = json.colors.color1 || root.walColor1
                        root.walColor2 = json.colors.color2 || root.walColor2
                        root.walColor4 = json.colors.color4 || root.walColor4
                        root.walColor5 = json.colors.color5 || root.walColor5
                        root.walColor8 = json.colors.color8 || root.walColor8
                        root.walColor13 = json.colors.color13 || root.walColor13
                    }
                } catch(e) {}
            }
        }
        onExited: {
            if (root.walApplying) walStepBlur.running = true
        }
    }

    // Disabled: system-wide waybar restart
    // Process {
    //     id: walStepWaybar
    //     command: ["bash", "-c", "killall waybar; waybar &"]
    //     onExited: walStepSwaync.running = true
    // }

    // Disabled: system-wide swaync CSS update
    // Process {
    //     id: walStepSwaync
    //     command: ["bash", "-c", "cp ~/.cache/wal/colors-swaync.css ~/.config/swaync/style.css && pkill -SIGUSR1 swaync"]
    //     onExited: walStepBlur.running = true
    //}

    Process {
        id: walStepBlur
        command: {
            var wp = root.currentWallpaper
            if (wp.endsWith(".gif"))
                return ["bash", "-c", "convert '" + wp + "[0]' -resize 1920x -blur 0x8 -quality 85 ~/Pictures/wallpapers/Downloaded/walls/.current-blurred.jpg"]
            else
                return ["bash", "-c", "convert '" + wp + "' -resize 1920x -blur 0x8 -quality 85 ~/Pictures/wallpapers/Downloaded/walls/.current-blurred.jpg"]
        }
        onExited: root.walApplying = false
    }

    Process {
        id: currentWallProc
        command: ["bash", "-c", "readlink -f ~/Pictures/wallpapers/Downloaded/walls/current 2>/dev/null || echo ''"]
        stdout: SplitParser { onRead: data => root.currentWallpaper = data.trim() }
    }

    Process {
        id: loadUsageProc
        command: ["bash", "-c", "cat /home/fadilix/.config/quickshell/app_usage.json 2>/dev/null || echo '{}'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try { root.appUsage = JSON.parse(data.trim()) } catch(e) { root.appUsage = {} }
            }
        }
    }

    Process { id: saveUsageProc }

    Process {
        id: wifiStatusProc
        command: ["bash", "-c", "nmcli radio wifi"]
        stdout: SplitParser { onRead: data => root.wifiEnabled = data.trim() === "enabled" }
    }

    Process {
        id: wifiCurrentProc
        command: ["bash", "-c", "nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(":")
                if (parts.length >= 3) {
                    root.wifiCurrentSSID = parts[1]
                    root.wifiSignal = parseInt(parts[2]) || 0
                } else {
                    root.wifiCurrentSSID = ""
                    root.wifiSignal = 0
                }
            }
        }
    }

    Process {
        id: wifiScanProc
        command: ["bash", "-c", "nmcli -t -f ssid,signal,security dev wifi list --rescan yes 2>/dev/null | head -20"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split(":")
                if (parts.length < 2) return
                var ssid = parts[0]
                if (ssid === "" || ssid === root.wifiCurrentSSID) return
                var signal = parseInt(parts[1]) || 0
                var security = parts.length >= 3 ? parts[2] : ""
                var current = root.wifiNetworks.slice()
                for (var i = 0; i < current.length; i++) {
                    if (current[i].ssid === ssid) return
                }
                current.push({ ssid: ssid, signal: signal, security: security })
                root.wifiNetworks = current
            }
        }
        onExited: root.wifiScanning = false
    }

    Process {
        id: wifiToggleProc
        command: ["bash", "-c", root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"]
        onExited: {
            wifiStatusProc.running = true
            if (!root.wifiEnabled) wifiScanDelayTimer.start()
        }
    }

    Timer {
        id: wifiScanDelayTimer
        interval: 2000
        repeat: false
        onTriggered: refreshWifi()
    }

    Process {
        id: wifiConnectProc
        property string ssid: ""
        property string password: ""
        command: {
            if (password !== "")
                return ["bash", "-c", "nmcli dev wifi connect '" + ssid + "' password '" + password + "' 2>&1"]
            else
                return ["bash", "-c", "nmcli dev wifi connect '" + ssid + "' 2>&1"]
        }
        onExited: {
            root.wifiConnecting = false
            root.wifiPasswordSSID = ""
            wifiCurrentProc.running = true
        }
    }

    Process {
        id: wifiDisconnectProc
        command: ["bash", "-c", "nmcli dev disconnect wlan0 2>/dev/null; nmcli dev disconnect wlp0s20f3 2>/dev/null"]
        onExited: {
            root.wifiCurrentSSID = ""
            root.wifiSignal = 0
        }
    }

    Process {
        id: btStatusProc
        command: ["bash", "-c", "echo -e 'show\\nquit' | bluetoothctl 2>/dev/null | grep -q 'Powered: yes' && echo 'true' || echo 'false'"]
        stdout: SplitParser {
            onRead: data => root.btEnabled = data.trim() === "true"
        }
        onExited: {
            if (root.btEnabled) btDevicesProc.running = true
        }
    }

    Process {
        id: btToggleOnProc
        command: ["bash", "-c", "echo -e 'power on\\nquit' | bluetoothctl 2>/dev/null"]
        onExited: {
            btToggleDelayTimer.start()
        }
    }

    Timer {
        id: btToggleDelayTimer
        interval: 1000
        repeat: false
        onTriggered: refreshBluetooth()
    }

    Process {
        id: btToggleOffProc
        command: ["bash", "-c", "echo -e 'power off\\nquit' | bluetoothctl 2>/dev/null"]
        onExited: {
            root.btEnabled = false
            root.btPairedDevices = []
            root.btAvailableDevices = []
        }
    }

    Process {
        id: btDevicesProc
        command: ["bash", "-c", "echo -e 'devices\\nquit' | bluetoothctl 2>/dev/null | grep '^Device' | while read -r line; do mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); info=$(echo -e \"info $mac\\nquit\" | bluetoothctl 2>/dev/null); paired=$(echo \"$info\" | grep -oP 'Paired: \\K\\w+'); connected=$(echo \"$info\" | grep -oP 'Connected: \\K\\w+'); if [ \"$paired\" = \"yes\" ]; then echo \"${mac}|${name}|${connected}\"; fi; done"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split("|")
                if (parts.length < 3) return
                var mac = parts[0]
                var name = parts[1]
                var connected = parts[2] === "yes"
                var current = root.btPairedDevices.slice()
                for (var i = 0; i < current.length; i++) {
                    if (current[i].mac === mac) return
                }
                current.push({ mac: mac, name: name, connected: connected })
                root.btPairedDevices = current
            }
        }
    }

    Process {
        id: btScanProc
        command: ["bash", "-c", "echo -e 'scan on\\nquit' | bluetoothctl 2>/dev/null; sleep 5; echo -e 'scan off\\nquit' | bluetoothctl 2>/dev/null; sleep 1; echo -e 'devices\\nquit' | bluetoothctl 2>/dev/null | grep '^Device' | while read -r line; do mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); info=$(echo -e \"info $mac\\nquit\" | bluetoothctl 2>/dev/null); paired=$(echo \"$info\" | grep -oP 'Paired: \\K\\w+'); if [ \"$paired\" != \"yes\" ] && [ -n \"$name\" ] && [ \"$name\" != \"$mac\" ]; then echo \"${mac}|${name}\"; fi; done"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split("|")
                if (parts.length < 2) return
                var mac = parts[0]
                var name = parts[1]
                if (mac.length !== 17) return
                var current = root.btAvailableDevices.slice()
                for (var j = 0; j < current.length; j++) {
                    if (current[j].mac === mac) return
                }
                current.push({ mac: mac, name: name })
                root.btAvailableDevices = current
            }
        }
        onExited: root.btScanning = false
    }

    Process {
        id: btActionProc
        onExited: {
            root.btConnectingMAC = ""
            btActionDelayTimer.start()
        }
    }

    Timer {
        id: btActionDelayTimer
        interval: 1500
        repeat: false
        onTriggered: refreshBluetooth()
    }

    PanelWindow {
        id: dashboard
        visible: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        focusable: true
        WlrLayershell.keyboardFocus: root.dashboardVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; right: true }
        margins { top: 40; bottom: 10; right: root.dashboardVisible ? 6 : -450 }
        implicitWidth: 420
        color: "transparent"
        Behavior on margins.right { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        property int cpuVal: 0
        property int ramVal: 0
        property int diskVal: 0
        property int batVal: 100
        property int volVal: 50
        property int brightVal: 100

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.7)
            radius: 20

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Rectangle {
                    id: profileSection
                    Layout.fillWidth: true
                    Layout.preferredHeight: pfpPickerOpen ? 280 : 100
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 15
                    clip: true
                    property bool pfpPickerOpen: false
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15
                            Item {
                                id: pfpContainer
                                width: 74
                                height: 74
                                Rectangle {
                                    id: pfpBorder
                                    anchors.fill: parent
                                    radius: 37
                                    color: "transparent"
                                    border.width: 3
                                    border.color: root.walColor5
                                }
                                Image {
                                    id: pfpImage
                                    anchors.centerIn: parent
                                    width: 68
                                    height: 68
                                    source: "file:///home/fadilix/.config/quickshell/assets/pfps/pfp.jpg"
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    cache: false
                                    sourceSize.width: 256
                                    sourceSize.height: 256
                                    visible: false
                                    property int reloadTrigger: 0
                                    function reload() {
                                        reloadTrigger++
                                        source = ""
                                        source = "file:///home/fadilix/.config/quickshell/assets/pfps/pfp.jpg?" + reloadTrigger
                                    }
                                }
                                Rectangle {
                                    id: pfpMask
                                    anchors.centerIn: parent
                                    width: 68
                                    height: 68
                                    radius: 34
                                    visible: false
                                }
                                OpacityMask {
                                    anchors.centerIn: parent
                                    width: 68
                                    height: 68
                                    source: pfpImage
                                    maskSource: pfpMask
                                }
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: root.walColor5
                                    border.width: 2
                                    border.color: root.walBackground
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰏫"
                                        color: root.walBackground
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        profileSection.pfpPickerOpen = !profileSection.pfpPickerOpen
                                        if (profileSection.pfpPickerOpen) {
                                            root.pfpFiles = []
                                            pfpListProc.running = true
                                        }
                                    }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text {
                                    text: "Fadilix"
                                    color: root.walColor5
                                    font.pixelSize: 26
                                    font.bold: true
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                Text {
                                    id: uptimeText
                                    text: "up ..."
                                    color: root.walForeground
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Qt.rgba(0, 0, 0, 0.3)
                            radius: 10
                            visible: profileSection.pfpPickerOpen
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                Text {
                                    text: "Choose Avatar"
                                    color: root.walColor5
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: "JetBrainsMono Nerd Font"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Flickable {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    contentWidth: width
                                    contentHeight: pfpGrid.height
                                    clip: true
                                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                                    GridLayout {
                                        id: pfpGrid
                                        width: parent.width
                                        columns: 6
                                        rowSpacing: 8
                                        columnSpacing: 8
                                        Repeater {
                                            model: root.pfpFiles
                                            Item {
                                                width: 48
                                                height: 48
                                                Layout.alignment: Qt.AlignHCenter
                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 24
                                                    color: "transparent"
                                                    border.width: 2
                                                    border.color: thumbMa.containsMouse ? root.walColor13 : root.walColor5
                                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                                }
                                                Image {
                                                    id: thumbImg
                                                    anchors.centerIn: parent
                                                    width: 44
                                                    height: 44
                                                    source: "file://" + modelData
                                                    fillMode: Image.PreserveAspectCrop
                                                    smooth: true
                                                    sourceSize.width: 128
                                                    sourceSize.height: 128
                                                    visible: false
                                                }
                                                Rectangle {
                                                    id: thumbMask
                                                    anchors.centerIn: parent
                                                    width: 44
                                                    height: 44
                                                    radius: 22
                                                    visible: false
                                                }
                                                OpacityMask {
                                                    anchors.centerIn: parent
                                                    width: 44
                                                    height: 44
                                                    source: thumbImg
                                                    maskSource: thumbMask
                                                }
                                                MouseArea {
                                                    id: thumbMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        setPfpProc.selFile = modelData
                                                        setPfpProc.running = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Process {
                        id: pfpListProc
                        command: ["bash", "-c", "find /home/fadilix/.config/quickshell/assets/pfps -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' \\) ! -name 'pfp.jpg' | sort"]
                        stdout: SplitParser {
                            onRead: data => {
                                var file = data.trim()
                                if (file.length > 0) {
                                    var current = root.pfpFiles.slice()
                                    current.push(file)
                                    root.pfpFiles = current
                                }
                            }
                        }
                    }
                    Process {
                        id: setPfpProc
                        property string selFile: ""
                        command: ["bash", "-c", "cp '" + selFile + "' /home/fadilix/.config/quickshell/assets/pfps/pfp.jpg"]
                        onExited: {
                            pfpImage.reload()
                            profileSection.pfpPickerOpen = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 15
                    Row {
                        anchors.centerIn: parent
                        spacing: 25
                        PowerBtn { icon: "⏻"; iconColor: root.walColor2; cmd: "systemctl poweroff" }
                        PowerBtn { icon: "󰜉"; iconColor: root.walColor13; cmd: "systemctl reboot" }
                        PowerBtn { icon: "󰌾"; iconColor: root.walColor5; cmd: "hyprlock" }
                        PowerBtn { icon: "󰒲"; iconColor: root.walColor4; cmd: "systemctl suspend" }
                        PowerBtn { icon: "󰍃"; iconColor: root.walColor1; cmd: "hyprctl dispatch exit" }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 15
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15
                        Text {
                            id: batIcon
                            text: "󰁹"
                            color: root.walColor2
                            font.pixelSize: 32
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                text: "Battery " + dashboard.batVal + "%"
                                color: root.walForeground
                                font.pixelSize: 18
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                id: batStatus
                                text: "Checking..."
                                color: root.walColor8
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 15
                    Row {
                        anchors.centerIn: parent
                        spacing: 30
                        CircularStat { label: "CPU"; icon: ""; barColor: root.walColor1; value: dashboard.cpuVal }
                        CircularStat { label: "RAM"; icon: ""; barColor: root.walColor5; value: dashboard.ramVal }
                        CircularStat { label: "DISK"; icon: ""; barColor: root.walColor4; value: dashboard.diskVal }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 15
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15
                        Row {
                            width: parent.width
                            spacing: 10
                            Text {
                                width: 25
                                text: dashboard.volVal == 0 ? "󰝟" : dashboard.volVal < 50 ? "󰖀" : "󰕾"
                                color: root.walColor4
                                font.pixelSize: 18
                                font.family: "JetBrainsMono Nerd Font"
                                verticalAlignment: Text.AlignVCenter
                                height: 24
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: volMuteProc.running = true
                                }
                                Process {
                                    id: volMuteProc
                                    command: ["bash", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]
                                    onExited: volProc.running = true
                                }
                            }
                            Rectangle {
                                id: volSlider
                                width: parent.width - 75
                                height: 8
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 4
                                color: Qt.rgba(0,0,0,0.3)
                                Rectangle {
                                    width: parent.width * dashboard.volVal / 100
                                    height: parent.height
                                    radius: 4
                                    color: root.walColor4
                                    Behavior on width { NumberAnimation { duration: 100 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        var percent = Math.round((mouse.x / parent.width) * 100)
                                        percent = Math.max(0, Math.min(100, percent))
                                        dashboard.volVal = percent
                                        volSetProc.command = ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (percent / 100).toFixed(2)]
                                        volSetProc.running = true
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var percent = Math.round((mouse.x / parent.width) * 100)
                                            percent = Math.max(0, Math.min(100, percent))
                                            dashboard.volVal = percent
                                            volSetProc.command = ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (percent / 100).toFixed(2)]
                                            volSetProc.running = true
                                        }
                                    }
                                }
                                Process { id: volSetProc }
                            }
                            Text {
                                width: 40
                                text: dashboard.volVal + "%"
                                color: root.walColor8
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                height: 24
                            }
                        }
                        Row {
                            width: parent.width
                            spacing: 10
                            Text {
                                width: 25
                                text: dashboard.brightVal < 30 ? "󰃞" : dashboard.brightVal < 70 ? "󰃟" : "󰃠"
                                color: root.walColor13
                                font.pixelSize: 18
                                font.family: "JetBrainsMono Nerd Font"
                                verticalAlignment: Text.AlignVCenter
                                height: 24
                            }
                            Rectangle {
                                id: brightSlider
                                width: parent.width - 75
                                height: 8
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 4
                                color: Qt.rgba(0,0,0,0.3)
                                Rectangle {
                                    width: parent.width * dashboard.brightVal / 100
                                    height: parent.height
                                    radius: 4
                                    color: root.walColor13
                                    Behavior on width { NumberAnimation { duration: 100 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        var percent = Math.round((mouse.x / parent.width) * 100)
                                        percent = Math.max(1, Math.min(100, percent))
                                        dashboard.brightVal = percent
                                        brightSetProc.command = ["bash", "-c", "brightnessctl set " + percent + "%"]
                                        brightSetProc.running = true
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var percent = Math.round((mouse.x / parent.width) * 100)
                                            percent = Math.max(1, Math.min(100, percent))
                                            dashboard.brightVal = percent
                                            brightSetProc.command = ["bash", "-c", "brightnessctl set " + percent + "%"]
                                            brightSetProc.running = true
                                        }
                                    }
                                }
                                Process { id: brightSetProc }
                            }
                            Text {
                                width: 40
                                text: dashboard.brightVal + "%"
                                color: root.walColor8
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                height: 24
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 15
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        Text {
                            id: timeDisplay
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "12:00:00 AM"
                            color: root.walColor5
                            font.pixelSize: 40
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Text {
                            id: dateDisplay
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "01.01.2026, Friday"
                            color: root.walForeground
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }
            }
        }

        component CircularStat: Item {
            property string label
            property string icon
            property color barColor
            property int value
            width: 90
            height: 110
            Column {
                anchors.centerIn: parent
                spacing: 8
                Item {
                    width: 70
                    height: 70
                    anchors.horizontalCenter: parent.horizontalCenter
                    Canvas {
                        anchors.fill: parent
                        property int statValue: value
                        onStatValueChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.lineWidth = 5
                            ctx.lineCap = "round"
                            ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.3)
                            ctx.beginPath()
                            ctx.arc(35, 35, 32, 0, 2 * Math.PI)
                            ctx.stroke()
                            ctx.strokeStyle = barColor
                            ctx.beginPath()
                            ctx.arc(35, 35, 32, -Math.PI / 2, -Math.PI / 2 + (statValue / 100) * 2 * Math.PI)
                            ctx.stroke()
                        }
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: icon
                            color: barColor
                            font.pixelSize: 16
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: value + "%"
                            color: root.walForeground
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: label
                    color: root.walColor8
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                }
            }
        }

        component PowerBtn: Rectangle {
            property string icon
            property color iconColor
            property string cmd
            width: 40
            height: 40
            radius: 10
            color: powerMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent
                text: icon
                color: iconColor
                font.pixelSize: 18
                font.family: "JetBrainsMono Nerd Font"
            }
            MouseArea {
                id: powerMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: cmdProc.running = true
            }
            Process {
                id: cmdProc
                command: ["bash", "-c", cmd]
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                var now = new Date()
                var hours = now.getHours()
                var minutes = now.getMinutes()
                var seconds = now.getSeconds()
                var ampm = hours >= 12 ? 'PM' : 'AM'
                hours = hours % 12
                hours = hours ? hours : 12
                var h = hours < 10 ? '0' + hours : hours
                var m = minutes < 10 ? '0' + minutes : minutes
                var s = seconds < 10 ? '0' + seconds : seconds
                timeDisplay.text = h + ':' + m + ':' + s + ' ' + ampm
                dateDisplay.text = Qt.formatDate(now, "dd.MM.yyyy, dddd")
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                cpuProc.running = true
                ramProc.running = true
                diskProc.running = true
                batProc.running = true
                batStatusProc.running = true
                volProc.running = true
                brightProc.running = true
                uptimeProc.running = true
            }
        }

        Process {
            id: cpuProc
            command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2 + $4)}'"]
            stdout: SplitParser { onRead: data => dashboard.cpuVal = parseInt(data) || 0 }
        }
        Process {
            id: ramProc
            command: ["bash", "-c", "free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}'"]
            stdout: SplitParser { onRead: data => dashboard.ramVal = parseInt(data) || 0 }
        }
        Process {
            id: diskProc
            command: ["bash", "-c", "df / | awk 'NR==2 {gsub(/%/,\"\"); print $5}'"]
            stdout: SplitParser { onRead: data => dashboard.diskVal = parseInt(data) || 0 }
        }
        Process {
            id: batProc
            command: ["bash", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100"]
            stdout: SplitParser {
                onRead: data => {
                    dashboard.batVal = parseInt(data) || 100
                    var cap = dashboard.batVal
                    if (cap >= 90) batIcon.text = "󰁹"
                    else if (cap >= 80) batIcon.text = "󰂂"
                    else if (cap >= 70) batIcon.text = "󰂁"
                    else if (cap >= 60) batIcon.text = "󰂀"
                    else if (cap >= 50) batIcon.text = "󰁿"
                    else if (cap >= 40) batIcon.text = "󰁾"
                    else if (cap >= 30) batIcon.text = "󰁽"
                    else if (cap >= 20) batIcon.text = "󰁼"
                    else if (cap >= 10) batIcon.text = "󰁻"
                    else batIcon.text = "󰁺"
                }
            }
        }
        Process {
            id: batStatusProc
            command: ["bash", "-c", "cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo Unknown"]
            stdout: SplitParser {
                onRead: data => {
                    var status = data.trim()
                    if (status === "Charging") {
                        batStatus.text = "Charging"
                        batIcon.text = "󰂄"
                    } else if (status === "Full") {
                        batStatus.text = "Fully charged"
                    } else {
                        batStatus.text = "Discharging"
                    }
                }
            }
        }
        Process {
            id: volProc
            command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%.0f\", $2*100}'"]
            stdout: SplitParser { onRead: data => dashboard.volVal = parseInt(data) || 0 }
        }
        Process {
            id: brightProc
            command: ["bash", "-c", "brightnessctl -m | awk -F, '{gsub(/%/,\"\"); print $4}'"]
            stdout: SplitParser { onRead: data => dashboard.brightVal = parseInt(data) || 100 }
        }
        Process {
            id: uptimeProc
            command: ["bash", "-c", "uptime -p"]
            stdout: SplitParser { onRead: data => uptimeText.text = data.trim() }
        }
    }

    PanelWindow {
        id: musicPanel
        visible: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        focusable: true
        WlrLayershell.keyboardFocus: root.musicVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; left: true; right: true }
        margins { top: root.musicVisible ? 50 : -230; left: 0; right: 0 }
        implicitWidth: 400
        implicitHeight: 180
        color: "transparent"
        Behavior on margins.top { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        property string playerStatus: "Stopped"
        property string trackTitle: ""
        property string trackArtist: ""
        property real position: 0
        property real lastPosition: 0
        property real length: 0
        property bool hasTrack: playerStatus === "Playing" || playerStatus === "Paused"
        function formatTime(seconds) {
            var mins = Math.floor(seconds / 60)
            var secs = Math.floor(seconds % 60)
            return mins + ":" + (secs < 10 ? "0" : "") + secs
        }

        Rectangle {
            anchors.centerIn: parent
            width: 400
            height: 180
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.7)
            radius: 15
            opacity: 0.95
            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    Text {
                        text: musicPanel.trackTitle || "Nothing is playing"
                        color: root.walColor5
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: musicPanel.trackArtist || ""
                        color: root.walForeground
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        opacity: 0.7
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        visible: musicPanel.trackArtist !== ""
                    }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: musicPanel.hasTrack
                        Text {
                            text: musicPanel.formatTime(musicPanel.position)
                            color: root.walColor8
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: Qt.rgba(0, 0, 0, 0.3)
                            Rectangle {
                                width: musicPanel.length > 0 ? parent.width * (musicPanel.position / musicPanel.length) : 0
                                height: parent.height
                                radius: 2
                                color: root.walColor5
                                Behavior on width { NumberAnimation { duration: 200 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    if (musicPanel.length > 0) {
                                        var seekPos = (mouse.x / parent.width) * musicPanel.length
                                        seekProc.command = ["bash", "-c", "playerctl position " + seekPos]
                                        seekProc.running = true
                                    }
                                }
                            }
                        }
                        Text {
                            text: musicPanel.formatTime(musicPanel.length)
                            color: root.walColor8
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12
                        opacity: musicPanel.hasTrack ? 1.0 : 0.5
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: prevMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                color: root.walForeground
                                font.pixelSize: 16
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                id: prevMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: prevProc.running = true
                            }
                        }
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: root.walColor5
                            Text {
                                anchors.centerIn: parent
                                text: musicPanel.playerStatus === "Playing" ? "󰏤" : "󰐊"
                                color: root.walBackground
                                font.pixelSize: 18
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: playPauseProc.running = true
                            }
                        }
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: nextMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                color: root.walForeground
                                font.pixelSize: 16
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                id: nextMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: nextProc.running = true
                            }
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 160
                    Layout.alignment: Qt.AlignBottom
                    AnimatedImage {
                        id: honeypieImage
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -20
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 270
                        height: 182
                        source: "file:///home/fadilix/.config/quickshell/assets/honeypie.gif"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        playing: musicPanel.playerStatus === "Playing"
                        paused: musicPanel.playerStatus !== "Playing"
                    }
                }
            }
        }

        Timer {
            interval: 500
            running: root.musicVisible
            repeat: true
            triggeredOnStart: true
            onTriggered: musicStatusProc.running = true
        }
        Process {
            id: musicStatusProc
            command: ["bash", "-c", "playerctl status 2>/dev/null || echo 'Stopped'"]
            stdout: SplitParser {
                onRead: data => {
                    var newStatus = data.trim()
                    var wasPlaying = musicPanel.playerStatus === "Playing"
                    var isNowPlaying = newStatus === "Playing"
                    musicPanel.playerStatus = newStatus
                    musicTitleProc.running = true
                    musicArtistProc.running = true
                    musicLenProc.running = true
                    if (isNowPlaying) {
                        musicPosProc.running = true
                    } else if (wasPlaying && !isNowPlaying) {
                        musicPanel.lastPosition = musicPanel.position
                    } else if (!isNowPlaying) {
                        musicPanel.position = musicPanel.lastPosition
                    }
                }
            }
        }
        Process {
            id: musicTitleProc
            command: ["bash", "-c", "playerctl metadata title 2>/dev/null || echo ''"]
            stdout: SplitParser { onRead: data => musicPanel.trackTitle = data.trim() }
        }
        Process {
            id: musicArtistProc
            command: ["bash", "-c", "playerctl metadata artist 2>/dev/null || echo ''"]
            stdout: SplitParser { onRead: data => musicPanel.trackArtist = data.trim() }
        }
        Process {
            id: musicPosProc
            command: ["bash", "-c", "playerctl position 2>/dev/null || echo '0'"]
            stdout: SplitParser {
                onRead: data => {
                    var pos = parseFloat(data.trim()) || 0
                    musicPanel.position = pos
                    musicPanel.lastPosition = pos
                }
            }
        }
        Process {
            id: musicLenProc
            command: ["bash", "-c", "playerctl metadata mpris:length 2>/dev/null | awk '{print $1/1000000}'"]
            stdout: SplitParser { onRead: data => musicPanel.length = parseFloat(data.trim()) || 0 }
        }
        Process {
            id: playPauseProc
            command: ["bash", "-c", "playerctl play-pause"]
            onExited: musicStatusProc.running = true
        }
        Process {
            id: nextProc
            command: ["bash", "-c", "playerctl next"]
            onExited: musicStatusProc.running = true
        }
        Process {
            id: prevProc
            command: ["bash", "-c", "playerctl previous"]
            onExited: musicStatusProc.running = true
        }
        Process { id: seekProc }
    }

    PanelWindow {
        id: wifiPanel
        visible: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        focusable: true
        WlrLayershell.keyboardFocus: root.wifiVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; right: true }
        margins { top: 40; right: root.wifiVisible ? 6 : -350 }
        height: 420
        implicitWidth: 320
        color: "transparent"
        Behavior on margins.right { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.7)
            radius: 20

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "󰤨"
                        color: root.walColor5
                        font.pixelSize: 22
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: "Wi-Fi"
                        color: root.walColor5
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: root.wifiEnabled ? root.walColor5 : Qt.rgba(0.3, 0.3, 0.3, 0.5)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            y: 2
                            x: root.wifiEnabled ? 22 : 2
                            color: root.walBackground
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wifiToggleProc.running = true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.3)
                    visible: root.wifiCurrentSSID !== ""
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10
                        Text {
                            text: root.wifiSignal > 66 ? "󰤨" : root.wifiSignal > 33 ? "󰤥" : "󰤟"
                            color: root.walColor2
                            font.pixelSize: 18
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: root.wifiCurrentSSID
                                color: root.walColor2
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "Connected · " + root.wifiSignal + "%"
                                color: root.walColor8
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 8
                            color: wifiDiscMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: root.walColor1
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                id: wifiDiscMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: wifiDisconnectProc.running = true
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.3)
                    visible: root.wifiPasswordSSID !== ""
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8
                        Text {
                            text: "󰌾"
                            color: root.walColor8
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        TextInput {
                            id: wifiPassInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: root.walForeground
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            clip: true
                            Text {
                                text: "Password for " + root.wifiPasswordSSID
                                color: root.walColor8
                                visible: !parent.text
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                font: parent.font
                            }
                            Keys.onReturnPressed: {
                                if (wifiPassInput.text.length > 0) {
                                    root.wifiConnecting = true
                                    wifiConnectProc.ssid = root.wifiPasswordSSID
                                    wifiConnectProc.password = wifiPassInput.text
                                    wifiConnectProc.running = true
                                    wifiPassInput.text = ""
                                }
                            }
                            Keys.onEscapePressed: {
                                root.wifiPasswordSSID = ""
                                wifiPassInput.text = ""
                            }
                        }
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 6
                            color: root.walColor5
                            Text {
                                anchors.centerIn: parent
                                text: "→"
                                color: root.walBackground
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (wifiPassInput.text.length > 0) {
                                        root.wifiConnecting = true
                                        wifiConnectProc.ssid = root.wifiPasswordSSID
                                        wifiConnectProc.password = wifiPassInput.text
                                        wifiConnectProc.running = true
                                        wifiPassInput.text = ""
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.wifiEnabled
                    Text {
                        text: "Available Networks"
                        color: root.walColor8
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 6
                        color: wifiRefreshMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: root.wifiScanning ? "󰑓" : "󰑐"
                            color: root.walColor8
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        MouseArea {
                            id: wifiRefreshMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.wifiScanning) refreshWifi()
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 12
                    clip: true
                    ListView {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.wifiNetworks
                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 44
                            radius: 10
                            color: wifiNetMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10
                                Text {
                                    text: modelData.signal > 66 ? "󰤨" : modelData.signal > 33 ? "󰤥" : "󰤟"
                                    color: root.walColor5
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: modelData.ssid
                                        color: root.walForeground
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: (modelData.security !== "" && modelData.security !== "--" ? "󰌾 " + modelData.security : "Open") + " · " + modelData.signal + "%"
                                        color: root.walColor8
                                        font.pixelSize: 9
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }
                            }
                            MouseArea {
                                id: wifiNetMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.security !== "" && modelData.security !== "--") {
                                        root.wifiPasswordSSID = modelData.ssid
                                        wifiPassInput.forceActiveFocus()
                                    } else {
                                        root.wifiConnecting = true
                                        wifiConnectProc.ssid = modelData.ssid
                                        wifiConnectProc.password = ""
                                        wifiConnectProc.running = true
                                    }
                                }
                            }
                        }
                        ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.wifiNetworks.length === 0 && !root.wifiScanning
                        text: root.wifiEnabled ? "No networks found" : "Wi-Fi is off"
                        color: root.walColor8
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.wifiScanning
                        text: "Scanning..."
                        color: root.walColor8
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }
        }
    }

    PanelWindow {
        id: btPanel
        visible: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        focusable: true
        WlrLayershell.keyboardFocus: root.btVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; right: true }
        margins { top: 40; right: root.btVisible ? 6 : -350 }
        height: 460
        implicitWidth: 320
        color: "transparent"
        Behavior on margins.right { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.7)
            radius: 20

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "󰂯"
                        color: root.walColor5
                        font.pixelSize: 22
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: "Bluetooth"
                        color: root.walColor5
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: root.btEnabled ? root.walColor5 : Qt.rgba(0.3, 0.3, 0.3, 0.5)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            y: 2
                            x: root.btEnabled ? 22 : 2
                            color: root.walBackground
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.btEnabled)
                                    btToggleOffProc.running = true
                                else
                                    btToggleOnProc.running = true
                            }
                        }
                    }
                }

                Text {
                    text: "Paired Devices"
                    color: root.walColor8
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    visible: root.btEnabled
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 12
                    clip: true
                    visible: root.btEnabled
                    ListView {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.btPairedDevices
                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 48
                            radius: 10
                            color: btPairedMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10
                                Text {
                                    text: modelData.connected ? "󰂱" : "󰂲"
                                    color: modelData.connected ? root.walColor2 : root.walColor8
                                    font.pixelSize: 18
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: modelData.name
                                        color: modelData.connected ? root.walColor2 : root.walForeground
                                        font.pixelSize: 12
                                        font.bold: modelData.connected
                                        font.family: "JetBrainsMono Nerd Font"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: {
                                            if (root.btConnectingMAC === modelData.mac) return "Connecting..."
                                            if (modelData.connected) return "Connected"
                                            return "Paired"
                                        }
                                        color: root.walColor8
                                        font.pixelSize: 9
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 8
                                    color: btConnBtnMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "󰅖" : "󰐕"
                                        color: modelData.connected ? root.walColor1 : root.walColor5
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                    MouseArea {
                                        id: btConnBtnMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected)
                                                root.disconnectBt(modelData.mac)
                                            else
                                                root.connectBt(modelData.mac)
                                        }
                                    }
                                }
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 8
                                    color: btForgetMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴"
                                        color: root.walColor8
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                    MouseArea {
                                        id: btForgetMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.forgetBt(modelData.mac)
                                    }
                                }
                            }
                            MouseArea {
                                id: btPairedMa
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                                onClicked: {
                                    if (modelData.connected)
                                        root.disconnectBt(modelData.mac)
                                    else
                                        root.connectBt(modelData.mac)
                                }
                            }
                        }
                        ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.btPairedDevices.length === 0
                        text: "No paired devices"
                        color: root.walColor8
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.btEnabled
                    Text {
                        text: "Available Devices"
                        color: root.walColor8
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 60
                        height: 24
                        radius: 6
                        color: btScanBtnMa.containsMouse ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2) : Qt.rgba(0, 0, 0, 0.3)
                        Text {
                            anchors.centerIn: parent
                            text: root.btScanning ? "Scanning" : "Scan"
                            color: root.walColor5
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        MouseArea {
                            id: btScanBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.btScanning) {
                                    root.btScanning = true
                                    root.btAvailableDevices = []
                                    btScanProc.running = true
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 12
                    clip: true
                    visible: root.btEnabled
                    ListView {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.btAvailableDevices
                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 44
                            radius: 10
                            color: btAvailMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10
                                Text {
                                    text: "󰂲"
                                    color: root.walColor8
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                Text {
                                    text: modelData.name
                                    color: root.walForeground
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    visible: root.btConnectingMAC === modelData.mac
                                    text: "..."
                                    color: root.walColor8
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                            MouseArea {
                                id: btAvailMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pairBt(modelData.mac)
                            }
                        }
                        ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.btAvailableDevices.length === 0 && !root.btScanning
                        text: "Press Scan to find devices"
                        color: root.walColor8
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.btScanning
                        text: "Scanning..."
                        color: root.walColor8
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.btEnabled
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "Bluetooth is off"
                        color: root.walColor8
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }
        }
    }

    PanelWindow {
        id: launcherPanel
        visible: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        anchors { top: true; bottom: true; left: true }
        margins { top: 40; bottom: 10; left: root.launcherVisible ? 6 : -450 }
        implicitWidth: 420
        color: "transparent"
        WlrLayershell.keyboardFocus: root.launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        Behavior on margins.left { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.7)
            radius: 20

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 12
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: root.activeTab === 0 ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "󰀻"
                                    color: root.activeTab === 0 ? root.walColor5 : root.walColor8
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                Text {
                                    text: "Apps"
                                    color: root.activeTab === 0 ? root.walColor5 : root.walColor8
                                    font.pixelSize: 13
                                    font.bold: root.activeTab === 0
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeTab = 0
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: root.activeTab === 1 ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.2) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "󰸉"
                                    color: root.activeTab === 1 ? root.walColor13 : root.walColor8
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                Text {
                                    text: "Walls"
                                    color: root.activeTab === 1 ? root.walColor13 : root.walColor8
                                    font.pixelSize: 13
                                    font.bold: root.activeTab === 1
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeTab = 1
                                    if (!root.wallsLoaded) root.loadWallpapers()
                                    wallSearchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15
                        visible: root.activeTab === 0

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            color: Qt.rgba(0, 0, 0, 0.3)
                            radius: 12
                            border.width: searchInput.activeFocus ? 1 : 0
                            border.color: root.walColor5
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10
                                Text {
                                    text: ""
                                    color: root.walColor8
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: root.walForeground
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                    verticalAlignment: TextInput.AlignVCenter
                                    selectByMouse: true
                                    clip: true
                                    Text {
                                        text: "Search apps..."
                                        color: root.walColor8
                                        visible: !parent.text
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        font: parent.font
                                    }
                                    onTextChanged: {
                                        root.searchTerm = text.toLowerCase()
                                        root.selectedIndex = 0
                                    }
                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Down) {
                                            root.selectedIndex = Math.min(root.selectedIndex + 1, root.filteredApps.length - 1)
                                            appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Up) {
                                            root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                                            appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            if (root.filteredApps.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredApps.length)
                                                root.launchApp(root.filteredApps[root.selectedIndex])
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Escape) {
                                            root.launcherVisible = false
                                            searchInput.text = ""
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Tab) {
                                            root.activeTab = 1
                                            if (!root.wallsLoaded) root.loadWallpapers()
                                            wallSearchInput.forceActiveFocus()
                                            event.accepted = true
                                        }
                                    }
                                }
                                Text {
                                    visible: searchInput.text.length > 0
                                    text: "󰅖"
                                    color: root.walColor8
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: searchInput.text = ""
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Qt.rgba(0, 0, 0, 0.3)
                            radius: 15
                            clip: true
                            ListView {
                                id: appListView
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4
                                boundsBehavior: Flickable.StopAtBounds
                                currentIndex: root.selectedIndex
                                highlightFollowsCurrentItem: true
                                highlightMoveDuration: 100
                                model: root.filteredApps
                                delegate: Rectangle {
                                    width: appListView.width
                                    height: 48
                                    radius: 12
                                    color: {
                                        if (index === root.selectedIndex)
                                            return Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2)
                                        if (appItemMouse.containsMouse)
                                            return Qt.rgba(1, 1, 1, 0.05)
                                        return "transparent"
                                    }
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Rectangle {
                                        visible: index === root.selectedIndex
                                        width: 3
                                        height: 22
                                        radius: 2
                                        color: root.walColor5
                                        anchors.left: parent.left
                                        anchors.leftMargin: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 14
                                        anchors.topMargin: 6
                                        anchors.bottomMargin: 6
                                        spacing: 12
                                        Rectangle {
                                            width: 32
                                            height: 32
                                            radius: 8
                                            color: Qt.rgba(0, 0, 0, 0.2)
                                            Image {
                                                anchors.centerIn: parent
                                                width: 22
                                                height: 22
                                                source: {
                                                    var icon = modelData.icon
                                                    if (!icon || icon === "") return "image://icon/application-x-executable"
                                                    if (icon.indexOf("/") === 0) return "file://" + icon
                                                    return "image://icon/" + icon
                                                }
                                                fillMode: Image.PreserveAspectFit
                                                asynchronous: true
                                                cache: true
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                color: index === root.selectedIndex ? root.walColor5 : root.walForeground
                                                font.pixelSize: 13
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.bold: index === root.selectedIndex
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.exec
                                                color: root.walColor8
                                                font.pixelSize: 9
                                                font.family: "JetBrainsMono Nerd Font"
                                                elide: Text.ElideRight
                                                opacity: 0.7
                                            }
                                        }
                                        Text {
                                            visible: index === root.selectedIndex
                                            text: "↵"
                                            color: root.walColor5
                                            font.pixelSize: 14
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.bold: true
                                        }
                                    }
                                    MouseArea {
                                        id: appItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.launchApp(modelData)
                                        onContainsMouseChanged: {
                                            if (containsMouse) root.selectedIndex = index
                                        }
                                    }
                                }
                                ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: root.filteredApps.length === 0
                                text: "No apps found"
                                color: root.walColor8
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            color: Qt.rgba(0, 0, 0, 0.3)
                            radius: 10
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                Text { text: "↑↓ nav"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                                Item { Layout.fillWidth: true }
                                Text { text: "↵ launch"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                                Item { Layout.fillWidth: true }
                                Text { text: "tab walls"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                                Item { Layout.fillWidth: true }
                                Text { text: "esc close"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15
                        visible: root.activeTab === 1

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            color: Qt.rgba(0, 0, 0, 0.3)
                            radius: 12
                            border.width: wallSearchInput.activeFocus ? 1 : 0
                            border.color: root.walColor13
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10
                                Text {
                                    text: ""
                                    color: root.walColor8
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                TextInput {
                                    id: wallSearchInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: root.walForeground
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                    verticalAlignment: TextInput.AlignVCenter
                                    selectByMouse: true
                                    clip: true
                                    Text {
                                        text: "Search wallpapers..."
                                        color: root.walColor8
                                        visible: !parent.text
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        font: parent.font
                                    }
                                    onTextChanged: {
                                        root.wallSearchTerm = text.toLowerCase()
                                        root.wallSelectedIndex = 0
                                    }
                                    Keys.onPressed: function(event) {
                                        var cols = 3
                                        var total = root.filteredWallpapers.length
                                        if (event.key === Qt.Key_Right) {
                                            root.wallSelectedIndex = Math.min(root.wallSelectedIndex + 1, total - 1)
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Left) {
                                            root.wallSelectedIndex = Math.max(root.wallSelectedIndex - 1, 0)
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Down) {
                                            root.wallSelectedIndex = Math.min(root.wallSelectedIndex + cols, total - 1)
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Up) {
                                            root.wallSelectedIndex = Math.max(root.wallSelectedIndex - cols, 0)
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            if (total > 0 && root.wallSelectedIndex >= 0 && root.wallSelectedIndex < total)
                                                root.applyWallpaper(root.filteredWallpapers[root.wallSelectedIndex])
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Escape) {
                                            root.launcherVisible = false
                                            wallSearchInput.text = ""
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Tab) {
                                            root.activeTab = 0
                                            searchInput.forceActiveFocus()
                                            event.accepted = true
                                        }
                                    }
                                }
                                Text {
                                    visible: wallSearchInput.text.length > 0
                                    text: "󰅖"
                                    color: root.walColor8
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: wallSearchInput.text = ""
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Qt.rgba(0, 0, 0, 0.3)
                            radius: 15
                            clip: true
                            GridView {
                                id: wallGridView
                                anchors.fill: parent
                                anchors.margins: 10
                                cellWidth: Math.floor(width / 3)
                                cellHeight: cellWidth * 0.65 + 30
                                boundsBehavior: Flickable.StopAtBounds
                                clip: true
                                cacheBuffer: 400
                                model: root.filteredWallpapers
                                delegate: Item {
                                    width: wallGridView.cellWidth
                                    height: wallGridView.cellHeight
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        radius: 10
                                        color: {
                                            if (index === root.wallSelectedIndex)
                                                return Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.25)
                                            if (wallItemMouse.containsMouse)
                                                return Qt.rgba(1, 1, 1, 0.08)
                                            return Qt.rgba(0, 0, 0, 0.2)
                                        }
                                        border.width: {
                                            if (modelData.path === root.currentWallpaper) return 2
                                            if (index === root.wallSelectedIndex) return 1
                                            return 0
                                        }
                                        border.color: modelData.path === root.currentWallpaper ? root.walColor2 : root.walColor13
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            spacing: 2
                                            Item {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 7
                                                    color: Qt.rgba(0.3, 0.3, 0.3, 0.3)
                                                    visible: wallThumbImage.status !== Image.Ready
                                                }
                                                Image {
                                                    id: wallThumbImage
                                                    anchors.fill: parent
                                                    source: root.thumbsReady ? "file:///home/fadilix/.cache/wallpaper-thumbs/" + wallThumbImage.thumbHash + ".jpg" : ""
                                                    fillMode: Image.PreserveAspectCrop
                                                    smooth: false
                                                    asynchronous: true
                                                    cache: true
                                                    sourceSize.width: 180
                                                    sourceSize.height: 120
                                                    visible: false
                                                    property string thumbHash: ""
                                                    Component.onCompleted: {
                                                        hashProc.wallPath = modelData.path
                                                        hashProc.imageTarget = wallThumbImage
                                                        hashProc.running = true
                                                    }
                                                    onStatusChanged: {
                                                        if (status === Image.Error && modelData.path)
                                                            source = "file://" + modelData.path
                                                    }
                                                }
                                                Process {
                                                    id: hashProc
                                                    property string wallPath: ""
                                                    property var imageTarget: null
                                                    command: ["bash", "-c", "echo -n '" + wallPath + "' | md5sum | cut -d' ' -f1"]
                                                    stdout: SplitParser {
                                                        onRead: data => {
                                                            var hash = data.trim()
                                                            if (hash.length > 0 && hashProc.imageTarget)
                                                                hashProc.imageTarget.thumbHash = hash
                                                        }
                                                    }
                                                }
                                                Rectangle {
                                                    id: wallThumbMaskRect
                                                    anchors.fill: parent
                                                    radius: 7
                                                    visible: false
                                                }
                                                OpacityMask {
                                                    anchors.fill: parent
                                                    source: wallThumbImage
                                                    maskSource: wallThumbMaskRect
                                                }
                                                Rectangle {
                                                    visible: modelData.path === root.currentWallpaper
                                                    anchors.top: parent.top
                                                    anchors.right: parent.right
                                                    anchors.margins: 3
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: root.walColor2
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰄬"
                                                        color: root.walBackground
                                                        font.pixelSize: 10
                                                        font.family: "JetBrainsMono Nerd Font"
                                                    }
                                                }
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 22
                                                text: modelData.name
                                                color: {
                                                    if (modelData.path === root.currentWallpaper) return root.walColor2
                                                    if (index === root.wallSelectedIndex) return root.walColor13
                                                    return root.walForeground
                                                }
                                                font.pixelSize: 8
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.bold: index === root.wallSelectedIndex || modelData.path === root.currentWallpaper
                                                elide: Text.ElideMiddle
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }
                                        MouseArea {
                                            id: wallItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.applyWallpaper(modelData)
                                            onContainsMouseChanged: {
                                                if (containsMouse) root.wallSelectedIndex = index
                                            }
                                        }
                                    }
                                }
                                ScrollBar.vertical: ScrollBar { active: true; width: 4 }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: root.wallsLoaded && root.filteredWallpapers.length === 0
                                text: "No wallpapers found"
                                color: root.walColor8
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !root.wallsLoaded && root.wallpaperList.length === 0
                                text: "Loading..."
                                color: root.walColor8
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            color: Qt.rgba(0, 0, 0, 0.3)
                            radius: 10
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                Text { text: "←→↑↓ nav"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                                Item { Layout.fillWidth: true }
                                Text { text: "↵ apply"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                                Item { Layout.fillWidth: true }
                                Text { text: "tab apps"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                                Item { Layout.fillWidth: true }
                                Text { text: "esc close"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                            }
                        }
                    }
                }
            }
        }

        Connections {
            target: root
            function onLauncherVisibleChanged() {
                if (root.launcherVisible) {
                    searchInput.text = ""
                    wallSearchInput.text = ""
                    root.selectedIndex = 0
                    root.wallSelectedIndex = 0
                    loadUsageProc.running = true
                    currentWallProc.running = true
                    focusDelayTimer.restart()
                } else {
                    focusDelayTimer.stop()
                    searchInput.text = ""
                    wallSearchInput.text = ""
                    searchInput.focus = false
                    wallSearchInput.focus = false
                }
            }
            function onWallSelectedIndexChanged() {
                if (root.activeTab === 1)
                    wallGridView.positionViewAtIndex(root.wallSelectedIndex, GridView.Contain)
            }
        }

        Timer {
            id: focusDelayTimer
            interval: 0
            repeat: false
            onTriggered: {
                if (!root.launcherVisible) return
                if (root.activeTab === 0)
                    searchInput.forceActiveFocus()
                else {
                    if (!root.wallsLoaded) root.loadWallpapers()
                    wallSearchInput.forceActiveFocus()
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle() {
            root.activeTab = 0
            root.toggleLauncher()
        }
    }
    IpcHandler {
        target: "dashboard"
        function toggle() { root.toggleDashboard() }
    }
    IpcHandler {
        target: "music"
        function toggle() { root.toggleMusic() }
    }
    IpcHandler {
        target: "wallpaper"
        function toggle() {
            if (!root.launcherVisible) {
                root.activeTab = 1
                root.toggleLauncher()
            } else if (root.activeTab === 1) {
                root.toggleLauncher()
            } else {
                root.activeTab = 1
                if (!root.wallsLoaded) root.loadWallpapers()
                wallSearchInput.forceActiveFocus()
            }
        }
    }
    IpcHandler {
        target: "wifi"
        function toggle() { root.toggleWifi() }
    }
    IpcHandler {
        target: "bluetooth"
        function toggle() { root.toggleBluetooth() }
    }

    PanelWindow {
        id: mcqAnswerOverlay
        visible: root.mcqMessage.length > 0
        focusable: false
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        anchors { left: true; bottom: true }
        margins { left: 24; bottom: 24 }
        implicitWidth: Math.min(900, Math.max(120, mcqAnswerText.implicitWidth + 8))
        implicitHeight: Math.max(48, mcqAnswerText.implicitHeight + 8)
        color: "transparent"

        Text {
            id: mcqAnswerText
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            text: root.mcqMessage
            color: root.walForeground
            font.pixelSize: 18
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
        }
    }

}
