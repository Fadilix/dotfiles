-- Active Hyprland keybinds. Dispatchers use the native Lua API.
local allfloat_by_workspace = {}

local function apply_allfloat(window, workspace)
	local target = allfloat_by_workspace[workspace.id]
	if target == nil or window.floating == target then
		return
	end
	hl.dispatch(hl.dsp.window.float({
		window = window,
		action = target and "enable" or "disable",
	}))
end

local function toggle_allfloat()
	local workspace = hl.get_active_workspace()
	if not workspace then
		return
	end
	local windows = hl.get_workspace_windows(workspace)
	local target = false
	for _, window in ipairs(windows) do
		if not window.floating then
			target = true
			break
		end
	end
	allfloat_by_workspace[workspace.id] = target
	for _, window in ipairs(windows) do
		apply_allfloat(window, workspace)
	end
end

hl.on("window.open", function(window)
	if window.workspace then
		apply_allfloat(window, window.workspace)
	end
end)

hl.on("window.move_to_workspace", function(window, workspace)
	if workspace then
		apply_allfloat(window, workspace)
	end
end)
hl.bind("CTRL + ALT + Delete", hl.dsp.exit(), { description = "Session: Exit Hyprland" })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Windows: Close window" })
hl.bind("ALT + F4", hl.dsp.window.close(), { description = "Windows: Close window" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen(), { description = "Windows: Fullscreen" })
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/KillActiveProcess.sh"), { description = "Windows: Kill the window's process" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), { description = "Windows: Toggle floating" })
hl.bind("SUPER + ALT + F", function()
	toggle_allfloat()
end, { description = "Windows: Float all windows in workspace" })
hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/LockScreen.sh"), { description = "Session: Lock screen" })
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell ipc call power toggle"), { description = "Session: Power menu" })
hl.bind("SUPER + F1", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell ipc call keybinds toggle"), { description = "Panels: Keybind cheat sheet" })
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Refresh.sh"), { description = "Appearance: Refresh bars and menus" })
hl.bind("SUPER + M", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell ipc call emoji toggle"), { description = "Panels: Emoji picker" })
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell ipc call websearch toggle"), { description = "Panels: Web search" })
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ChangeBlur.sh"), { description = "Appearance: Toggle blur strength" })
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/GameMode.sh"), { description = "Appearance: Toggle game mode" })
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh"), { description = "Layout: Switch dwindle / master layout" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell ipc call clipboard toggle"), { description = "Panels: Clipboard history" })
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperEffects.sh"), { description = "Appearance: Wallpaper effects" })
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperRandom.sh"), { description = "Appearance: Random wallpaper" })
hl.bind("SUPER + CTRL + D", hl.dsp.layout("removemaster"), { description = "Layout: Remove from master" })
hl.bind("SUPER + J", hl.dsp.layout("cyclenext"), { description = "Layout: Focus next in layout" })
hl.bind("SUPER + P", hl.dsp.window.pseudo(), { description = "Layout: Toggle pseudo-tiling" })
hl.bind("SUPER + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "Layout: Swap with master" })
-- Rearrange tiles on the current workspace: windows trade places and sizes, everything stays tiled.
hl.bind("SUPER + code:35", hl.dsp.layout("rollnext"), { description = "Layout: Rotate windows forward" })
hl.bind("SUPER + code:34", hl.dsp.layout("rollprev"), { description = "Layout: Rotate windows back" })
hl.bind("SUPER + S", hl.dsp.layout("swapwithmaster"), { description = "Layout: Move focused window to the big slot" })
hl.bind("SUPER + SPACE", hl.dsp.layout("orientationnext"), { description = "Layout: Flip arrangement (big slot left, top, right, bottom, center)" })
hl.bind("SUPER + SHIFT + SPACE", hl.dsp.layout("orientationprev"), { description = "Layout: Flip arrangement back" })
hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "Layout: Toggle window group" })
hl.bind("SUPER + SHIFT + tab", hl.dsp.group.next(), { description = "Layout: Next window in group" })
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "Windows: Cycle to next window" })
hl.bind("ALT + Tab", hl.dsp.window.alter_zorder({ mode = "top" }), { description = "Windows: Bring window to top" })
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --inc"),
	{ locked = true, repeating = true, description = "Media: Volume up" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --dec"),
	{ locked = true, repeating = true, description = "Media: Volume down" }
)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle-mic"), { locked = true, description = "Media: Mute microphone" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle"), { locked = true, description = "Media: Mute" })
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true, description = "Session: Suspend" })
hl.bind("XF86RFKill", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/AirplaneMode.sh"), { locked = true, description = "System: Airplane mode" })
-- XKB has separate Play and Pause keysyms; there is no AudioPlayPause keysym.
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --pause"), { locked = true, description = "Media: Play / pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --pause"), { locked = true, description = "Media: Play / pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --nxt"), { locked = true, description = "Media: Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --prv"), { locked = true, description = "Media: Previous track" })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --stop"), { locked = true, description = "Media: Stop" })
hl.bind("SUPER + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --now"), { description = "Screenshots: Full screen" })
hl.bind("SUPER + R", hl.dsp.global("moodcq:mcq-screenshot"), { description = "Screenshots: Capture and ask" })
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --area"), { description = "Screenshots: Select area" })
hl.bind("SUPER + CTRL + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in5"), { description = "Screenshots: In 5 seconds" })
hl.bind("SUPER + CTRL + SHIFT + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in10"), { description = "Screenshots: In 10 seconds" })
hl.bind("ALT + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --active"), { description = "Screenshots: Active window" })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --swappy"), { description = "Screenshots: Select area and edit" })
hl.bind("SUPER + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true, description = "Windows: Shrink width" })
hl.bind("SUPER + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true, description = "Windows: Grow width" })
hl.bind("SUPER + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true, description = "Windows: Shrink height" })
hl.bind("SUPER + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true, description = "Windows: Grow height" })
hl.bind("SUPER + CTRL + left", hl.dsp.window.move({ direction = "l" }), { description = "Windows: Move window left" })
hl.bind("SUPER + CTRL + right", hl.dsp.window.move({ direction = "r" }), { description = "Windows: Move window right" })
hl.bind("SUPER + CTRL + up", hl.dsp.window.move({ direction = "u" }), { description = "Windows: Move window up" })
hl.bind("SUPER + CTRL + down", hl.dsp.window.move({ direction = "d" }), { description = "Windows: Move window down" })
hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }), { description = "Windows: Focus left" })
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }), { description = "Windows: Focus right" })
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }), { description = "Windows: Focus up" })
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }), { description = "Windows: Focus down" })
hl.bind("SUPER + tab", hl.dsp.focus({ workspace = "m+1" }), { description = "Workspaces: Next workspace on monitor" })
hl.bind("SUPER + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }), { description = "Workspaces: Previous workspace on monitor" })
hl.bind("SUPER + SHIFT + U", hl.dsp.window.move({ workspace = "special", follow = true }), { description = "Workspaces: Move window to special workspace" })
hl.bind("SUPER + U", hl.dsp.workspace.toggle_special(""), { description = "Workspaces: Toggle special workspace" })
hl.bind("SUPER + code:10", hl.dsp.focus({ workspace = "1" }), { description = "Workspaces: Go to workspace 1" })
hl.bind("SUPER + code:11", hl.dsp.focus({ workspace = "2" }), { description = "Workspaces: Go to workspace 2" })
hl.bind("SUPER + code:12", hl.dsp.focus({ workspace = "3" }), { description = "Workspaces: Go to workspace 3" })
hl.bind("SUPER + code:13", hl.dsp.focus({ workspace = "4" }), { description = "Workspaces: Go to workspace 4" })
hl.bind("SUPER + code:14", hl.dsp.focus({ workspace = "5" }), { description = "Workspaces: Go to workspace 5" })
hl.bind("SUPER + code:15", hl.dsp.focus({ workspace = "6" }), { description = "Workspaces: Go to workspace 6" })
hl.bind("SUPER + code:16", hl.dsp.focus({ workspace = "7" }), { description = "Workspaces: Go to workspace 7" })
hl.bind("SUPER + code:17", hl.dsp.focus({ workspace = "8" }), { description = "Workspaces: Go to workspace 8" })
hl.bind("SUPER + code:18", hl.dsp.focus({ workspace = "9" }), { description = "Workspaces: Go to workspace 9" })
hl.bind("SUPER + code:19", hl.dsp.focus({ workspace = "10" }), { description = "Workspaces: Go to workspace 10" })
hl.bind("SUPER + SHIFT + code:10", hl.dsp.window.move({ workspace = "1", follow = true }), { description = "Workspaces: Move window to workspace 1" })
hl.bind("SUPER + SHIFT + code:11", hl.dsp.window.move({ workspace = "2", follow = true }), { description = "Workspaces: Move window to workspace 2" })
hl.bind("SUPER + SHIFT + code:12", hl.dsp.window.move({ workspace = "3", follow = true }), { description = "Workspaces: Move window to workspace 3" })
hl.bind("SUPER + SHIFT + code:13", hl.dsp.window.move({ workspace = "4", follow = true }), { description = "Workspaces: Move window to workspace 4" })
hl.bind("SUPER + SHIFT + code:14", hl.dsp.window.move({ workspace = "5", follow = true }), { description = "Workspaces: Move window to workspace 5" })
hl.bind("SUPER + SHIFT + code:15", hl.dsp.window.move({ workspace = "6", follow = true }), { description = "Workspaces: Move window to workspace 6" })
hl.bind("SUPER + SHIFT + code:16", hl.dsp.window.move({ workspace = "7", follow = true }), { description = "Workspaces: Move window to workspace 7" })
hl.bind("SUPER + SHIFT + code:17", hl.dsp.window.move({ workspace = "8", follow = true }), { description = "Workspaces: Move window to workspace 8" })
hl.bind("SUPER + SHIFT + code:18", hl.dsp.window.move({ workspace = "9", follow = true }), { description = "Workspaces: Move window to workspace 9" })
hl.bind("SUPER + SHIFT + code:19", hl.dsp.window.move({ workspace = "10", follow = true }), { description = "Workspaces: Move window to workspace 10" })
hl.bind("SUPER + SHIFT + code:34", hl.dsp.window.move({ workspace = "r-1", follow = true }), { description = "Workspaces: Move window to previous workspace" })
hl.bind("SUPER + SHIFT + code:35", hl.dsp.window.move({ workspace = "r+1", follow = true }), { description = "Workspaces: Move window to next workspace" })
hl.bind("SUPER + CTRL + code:10", hl.dsp.window.move({ workspace = "1", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 1" })
hl.bind("SUPER + CTRL + code:11", hl.dsp.window.move({ workspace = "2", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 2" })
hl.bind("SUPER + CTRL + code:12", hl.dsp.window.move({ workspace = "3", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 3" })
hl.bind("SUPER + CTRL + code:13", hl.dsp.window.move({ workspace = "4", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 4" })
hl.bind("SUPER + CTRL + code:14", hl.dsp.window.move({ workspace = "5", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 5" })
hl.bind("SUPER + CTRL + code:15", hl.dsp.window.move({ workspace = "6", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 6" })
hl.bind("SUPER + CTRL + code:16", hl.dsp.window.move({ workspace = "7", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 7" })
hl.bind("SUPER + CTRL + code:17", hl.dsp.window.move({ workspace = "8", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 8" })
hl.bind("SUPER + CTRL + code:18", hl.dsp.window.move({ workspace = "9", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 9" })
hl.bind("SUPER + CTRL + code:19", hl.dsp.window.move({ workspace = "10", follow = false }), { description = "Workspaces: Send window, stay here, to workspace 10" })
hl.bind("SUPER + CTRL + code:34", hl.dsp.window.move({ workspace = "r-1", follow = false }), { description = "Workspaces: Send window to previous, stay here" })
hl.bind("SUPER + CTRL + code:35", hl.dsp.window.move({ workspace = "r+1", follow = false }), { description = "Workspaces: Send window to next, stay here" })
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspaces: Next used workspace" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspaces: Previous used workspace" })
hl.bind("SUPER + period", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspaces: Next used workspace" })
hl.bind("SUPER + comma", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspaces: Previous used workspace" })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Windows: Drag window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Windows: Resize window" })
hl.bind("SUPER + CTRL + ALT + Right", hl.dsp.window.move({ workspace = "r+1", follow = true }), { description = "Workspaces: Move window to next workspace" })
hl.bind("SUPER + CTRL + ALT + Left", hl.dsp.window.move({ workspace = "r-1", follow = true }), { description = "Workspaces: Move window to previous workspace" })
hl.bind("SUPER + CTRL + n", hl.dsp.window.move({ workspace = "r+1", follow = true }), { description = "Workspaces: Move window to next workspace" })
hl.bind("SUPER + CTRL + p", hl.dsp.window.move({ workspace = "r-1", follow = true }), { description = "Workspaces: Move window to previous workspace" })
hl.bind("SUPER + h", hl.dsp.focus({ workspace = "r-1" }), { description = "Workspaces: Previous workspace" })
hl.bind("SUPER + l", hl.dsp.focus({ workspace = "r+1" }), { description = "Workspaces: Next workspace" })
hl.bind("SUPER + D", hl.dsp.global("quickshell:launcher"), { description = "Panels: App launcher" })
hl.bind("SUPER + I", hl.dsp.exec_cmd("qs ipc call dashboard toggle"), { description = "Panels: Dashboard" })
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("qs ipc call music toggle"), { description = "Panels: Music" })
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("qs ipc call monitors toggle"), { description = "Panels: Monitor layout" })
hl.bind("SUPER + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"), { description = "Panels: Wallpaper picker" })
-- Focus or launch: an app key jumps to that app if it is open anywhere, and opens it if not.
-- Pressed again while the app is focused, it cycles through that app's other windows.
-- SUPER + CTRL + the same key always opens a new window.
local function focus_or_launch(classes, cmd)
    return function()
        local matches = {}
        for _, w in ipairs(hl.get_windows()) do
            local class, initial = string.lower(w.class or ""), string.lower(w.initial_class or "")
            for _, want in ipairs(classes) do
                if class == want or initial == want then
                    table.insert(matches, w)
                    break
                end
            end
        end
        if #matches == 0 then
            hl.dispatch(hl.dsp.exec_cmd(cmd))
            return
        end
        -- focus_history_id 0 is the most recently focused window
        table.sort(matches, function(a, b) return a.focus_history_id < b.focus_history_id end)
        local target = matches[1]
        if target.active and #matches > 1 then target = matches[#matches] end
        hl.dispatch(hl.dsp.focus({ window = target }))
    end
end

hl.bind("SUPER + O", focus_or_launch({ "obsidian", "md.obsidian.obsidian" }, "obsidian"), { description = "Apps: Obsidian (focus or open)" })
hl.bind("SUPER + CTRL + O", hl.dsp.exec_cmd("obsidian"), { description = "Apps: New Obsidian window" })
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"), { description = "Apps: Terminal" })
hl.bind("SUPER + K", focus_or_launch({ "kitty-super-k" }, "kitty --class kitty-super-k --start-as=normal -o remember_window_size=no"), { description = "Apps: Tiled terminal (focus or open)" })
hl.bind("SUPER + CTRL + K", hl.dsp.exec_cmd("kitty --class kitty-super-k --start-as=normal -o remember_window_size=no"), { description = "Apps: New tiled terminal" })
hl.bind("SUPER + T", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/launch_kitty_tmux_nvim.sh"), { description = "Apps: Neovim in tmux" })
hl.bind("SUPER + E", focus_or_launch({ "thunar" }, "thunar"), { description = "Apps: File manager (focus or open)" })
hl.bind("SUPER + CTRL + E", hl.dsp.exec_cmd("thunar"), { description = "Apps: New file manager window" })
hl.bind("XF86Calculator", hl.dsp.exec_cmd("qalculate-gtk"), { description = "Apps: Calculator" })
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("pypr toggle term"), { description = "Apps: Dropdown terminal" })
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("$HOME/.config/hypr/UserScripts/ZshChangeTheme.sh"), { description = "Apps: Change zsh theme" })
hl.bind("SUPER + B", focus_or_launch({ "zen" }, "zen-browser"), { description = "Apps: Browser (focus or open)" })
hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd("zen-browser"), { description = "Apps: New Browser window" })
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a / –autocopy"), { description = "Apps: Color picker" })
hl.bind("SUPER + C", focus_or_launch({ "code", "code-oss", "com.microsoft.vscode" }, "code"), { description = "Apps: VS Code (focus or open)" })
hl.bind("SUPER + CTRL + C", hl.dsp.exec_cmd("code"), { description = "Apps: New VS Code window" })
hl.bind("ALT + R", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ToggleBlueLight.sh"), { description = "System: Toggle blue light filter" })
hl.bind("SUPER + Y", hl.dsp.exec_cmd("$HOME/.config/hypr/UserScripts/toggle_pointers.sh"), { description = "System: Toggle pointer" })
hl.bind(
	"XF86KbdBrightnessDown",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/BrightnessKbd.sh --dec"),
	{ repeating = true, description = "System: Keyboard brightness down" }
)
hl.bind(
	"XF86KbdBrightnessUp",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/BrightnessKbd.sh --inc"),
	{ repeating = true, description = "System: Keyboard brightness up" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --dec"),
	{ repeating = true, description = "System: Screen brightness down" }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --inc"), { repeating = true, description = "System: Screen brightness up" })
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/TouchPad.sh"), { description = "System: Toggle touchpad" })
hl.bind("SUPER + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --now"), { description = "Screenshots: Full screen" })
hl.bind("SUPER + SHIFT + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --area"), { description = "Screenshots: Select area" })
hl.bind("SUPER + CTRL + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in5"), { description = "Screenshots: In 5 seconds" })
hl.bind("SUPER + ALT + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in10"), { description = "Screenshots: In 10 seconds" })
hl.bind("ALT + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --active"), { description = "Screenshots: Active window" })
hl.bind("SUPER + A", hl.dsp.exec_cmd("/usr/bin/pypr-client toggle term"), { description = "Apps: Dropdown terminal" })
hl.bind("SUPER + N", hl.dsp.exec_cmd("pypr toggle_special minimized"), { description = "Windows: Minimize / restore window" })
hl.bind("SUPER + SHIFT + N", hl.dsp.workspace.toggle_special("minimized"), { description = "Windows: Show minimized windows" })
hl.bind("SUPER + SHIFT + Z", hl.dsp.exec_cmd("pypr zoom ++0.5"), { description = "System: Zoom in" })
hl.bind("SUPER + Z", hl.dsp.exec_cmd("pypr zoom"), { description = "System: Toggle zoom" })
hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd("/home/fadilix/.local/bin/latto dnd"), { description = "System: Do not disturb" })
