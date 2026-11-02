-- Hyprland startup commands. Waybar remains disabled.
local home = os.getenv("HOME") or "/home/fadilix"
local scripts = home .. "/.config/hypr/scripts"

local commands = {
    home .. "/.config/hypr/initial-boot.sh",
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "xhost +SI:localuser:root",
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "awww-daemon --format xrgb",
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    scripts .. "/Polkit.sh",
    "quickshell",
    "nm-applet --indicator",
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",
    "hypridle",
    "/usr/local/bin/pypr --debug /tmp/pypr.log",
    "/home/fadilix/.local/bin/latto start",
}

hl.on("hyprland.start", function()
    for _, command in ipairs(commands) do
        hl.exec_cmd(command)
    end
end)
