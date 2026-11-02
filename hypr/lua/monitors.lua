-- Base monitor configuration.
hl.monitor({
    output = "",
    mode = "1920x1200",
    position = "auto",
    scale = 1.25,
    mirror = "eDP-1",
})

-- The monitor profile picker writes the selected Lua profile here.
local active_profile = (os.getenv("HOME") or "/home/fadilix") .. "/.config/hypr/lua/active_monitor_profile.lua"
local active_chunk = loadfile(active_profile)
if active_chunk then active_chunk() end
