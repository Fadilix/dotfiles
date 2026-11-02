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
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/KillActiveProcess.sh"))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + ALT + F", function()
	toggle_allfloat()
end)
hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/LockScreen.sh"))
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Wlogout.sh"))
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Refresh.sh"))
hl.bind("SUPER + M", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/RofiEmoji.sh"))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/RofiSearch.sh"))
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ChangeBlur.sh"))
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/GameMode.sh"))
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ClipManager.sh"))
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperEffects.sh"))
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperRandom.sh"))
hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/WaybarStyles.sh"))
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/WaybarLayout.sh"))
hl.bind("SUPER + CTRL + D", hl.dsp.layout("removemaster"))
hl.bind("SUPER + J", hl.dsp.layout("cyclenext"))
hl.bind("SUPER + P", hl.dsp.window.pseudo())
hl.bind("SUPER + CTRL + Return", hl.dsp.layout("swapwithmaster"))
hl.bind("SUPER + G", hl.dsp.group.toggle())
hl.bind("SUPER + SHIFT + tab", hl.dsp.group.next())
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + Tab", hl.dsp.window.alter_zorder({ mode = "top" }))
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --inc"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --dec"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle-mic"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle"), { locked = true })
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("XF86RFKill", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/AirplaneMode.sh"), { locked = true })
-- XKB has separate Play and Pause keysyms; there is no AudioPlayPause keysym.
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --nxt"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --prv"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --stop"), { locked = true })
hl.bind("SUPER + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --now"))
hl.bind("SUPER + R", hl.dsp.global("moodcq:mcq-screenshot"))
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --area"))
hl.bind("SUPER + CTRL + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in5"))
hl.bind("SUPER + CTRL + SHIFT + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in10"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --active"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --swappy"))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + CTRL + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + CTRL + down", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + tab", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("SUPER + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + SHIFT + U", hl.dsp.window.move({ workspace = "special", follow = true }))
hl.bind("SUPER + U", hl.dsp.workspace.toggle_special(""))
hl.bind("SUPER + code:10", hl.dsp.focus({ workspace = "1" }))
hl.bind("SUPER + code:11", hl.dsp.focus({ workspace = "2" }))
hl.bind("SUPER + code:12", hl.dsp.focus({ workspace = "3" }))
hl.bind("SUPER + code:13", hl.dsp.focus({ workspace = "4" }))
hl.bind("SUPER + code:14", hl.dsp.focus({ workspace = "5" }))
hl.bind("SUPER + code:15", hl.dsp.focus({ workspace = "6" }))
hl.bind("SUPER + code:16", hl.dsp.focus({ workspace = "7" }))
hl.bind("SUPER + code:17", hl.dsp.focus({ workspace = "8" }))
hl.bind("SUPER + code:18", hl.dsp.focus({ workspace = "9" }))
hl.bind("SUPER + code:19", hl.dsp.focus({ workspace = "10" }))
hl.bind("SUPER + SHIFT + code:10", hl.dsp.window.move({ workspace = "1", follow = true }))
hl.bind("SUPER + SHIFT + code:11", hl.dsp.window.move({ workspace = "2", follow = true }))
hl.bind("SUPER + SHIFT + code:12", hl.dsp.window.move({ workspace = "3", follow = true }))
hl.bind("SUPER + SHIFT + code:13", hl.dsp.window.move({ workspace = "4", follow = true }))
hl.bind("SUPER + SHIFT + code:14", hl.dsp.window.move({ workspace = "5", follow = true }))
hl.bind("SUPER + SHIFT + code:15", hl.dsp.window.move({ workspace = "6", follow = true }))
hl.bind("SUPER + SHIFT + code:16", hl.dsp.window.move({ workspace = "7", follow = true }))
hl.bind("SUPER + SHIFT + code:17", hl.dsp.window.move({ workspace = "8", follow = true }))
hl.bind("SUPER + SHIFT + code:18", hl.dsp.window.move({ workspace = "9", follow = true }))
hl.bind("SUPER + SHIFT + code:19", hl.dsp.window.move({ workspace = "10", follow = true }))
hl.bind("SUPER + SHIFT + bracketleft", hl.dsp.window.move({ workspace = "r-1", follow = true }))
hl.bind("SUPER + SHIFT + bracketright", hl.dsp.window.move({ workspace = "r+1", follow = true }))
hl.bind("SUPER + CTRL + code:10", hl.dsp.window.move({ workspace = "1", follow = false }))
hl.bind("SUPER + CTRL + code:11", hl.dsp.window.move({ workspace = "2", follow = false }))
hl.bind("SUPER + CTRL + code:12", hl.dsp.window.move({ workspace = "3", follow = false }))
hl.bind("SUPER + CTRL + code:13", hl.dsp.window.move({ workspace = "4", follow = false }))
hl.bind("SUPER + CTRL + code:14", hl.dsp.window.move({ workspace = "5", follow = false }))
hl.bind("SUPER + CTRL + code:15", hl.dsp.window.move({ workspace = "6", follow = false }))
hl.bind("SUPER + CTRL + code:16", hl.dsp.window.move({ workspace = "7", follow = false }))
hl.bind("SUPER + CTRL + code:17", hl.dsp.window.move({ workspace = "8", follow = false }))
hl.bind("SUPER + CTRL + code:18", hl.dsp.window.move({ workspace = "9", follow = false }))
hl.bind("SUPER + CTRL + code:19", hl.dsp.window.move({ workspace = "10", follow = false }))
hl.bind("SUPER + CTRL + bracketleft", hl.dsp.window.move({ workspace = "r-1", follow = false }))
hl.bind("SUPER + CTRL + bracketright", hl.dsp.window.move({ workspace = "r+1", follow = false }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + period", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + comma", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + CTRL + ALT + Right", hl.dsp.window.move({ workspace = "r+1", follow = true }))
hl.bind("SUPER + CTRL + ALT + Left", hl.dsp.window.move({ workspace = "r-1", follow = true }))
hl.bind("SUPER + CTRL + n", hl.dsp.window.move({ workspace = "r+1", follow = true }))
hl.bind("SUPER + CTRL + p", hl.dsp.window.move({ workspace = "r-1", follow = true }))
hl.bind("SUPER + h", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + l", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + D", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("qs ipc call dashboard toggle"))
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("qs ipc call music toggle"))
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("qs ipc call monitors toggle"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))
hl.bind("SUPER + O", hl.dsp.exec_cmd("obsidian"))
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + K", hl.dsp.exec_cmd("kitty --class kitty-super-k --start-as=normal -o remember_window_size=no"))
hl.bind("SUPER + T", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/launch_kitty_tmux_nvim.sh"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd("qalculate-gtk"))
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("$HOME/.config/hypr/UserScripts/ZshChangeTheme.sh"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("zen-browser"))
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a / –autocopy"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("code"))
hl.bind("ALT + R", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ToggleBlueLight.sh"))
hl.bind("SUPER + Y", hl.dsp.exec_cmd("$HOME/.config/hypr/UserScripts/toggle_pointers.sh"))
hl.bind(
	"XF86KbdBrightnessDown",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/BrightnessKbd.sh --dec"),
	{ repeating = true }
)
hl.bind(
	"XF86KbdBrightnessUp",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/BrightnessKbd.sh --inc"),
	{ repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --dec"),
	{ repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --inc"), { repeating = true })
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/TouchPad.sh"))
hl.bind("SUPER + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --now"))
hl.bind("SUPER + SHIFT + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --area"))
hl.bind("SUPER + CTRL + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in5"))
hl.bind("SUPER + ALT + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in10"))
hl.bind("ALT + F6", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --active"))
hl.bind("SUPER + A", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("pypr toggle_special minimized"))
hl.bind("SUPER + SHIFT + N", hl.dsp.workspace.toggle_special("minimized"))
hl.bind("SUPER + SHIFT + Z", hl.dsp.exec_cmd("pypr zoom ++0.5"))
hl.bind("SUPER + Z", hl.dsp.exec_cmd("pypr zoom"))
hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd("/home/fadilix/.local/bin/latto dnd"))
