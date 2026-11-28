-- Hyprland environment variables.
local variables = {
    { "CLUTTER_BACKEND", "wayland" },
    { "QT_AUTO_SCREEN_SCALE_FACTOR", "1" },
    { "QT_QPA_PLATFORM", "wayland;xcb" },
    { "QT_QPA_PLATFORMTHEME", "qt5ct" },
    { "QT_QPA_PLATFORMTHEME", "qt6ct" },
    { "QT_SCALE_FACTOR", "1" },
    { "QT_WAYLAND_DISABLE_WINDOWDECORATION", "1" },
    { "XDG_CURRENT_DESKTOP", "Hyprland" },
    { "XDG_SESSION_DESKTOP", "Hyprland" },
    { "XDG_SESSION_TYPE", "wayland" },
    { "AQ_MGPU_NO_EXPLICIT", "1" },
    { "GDK_BACKEND", "wayland,x11" },
    { "XCURSOR_SIZE", "19" },
    { "XCURSOR_THEME", "Bibata-Modern-Ice" },
    { "HYPRCURSOR_SIZE", "19" },
    { "HYPRCURSOR_THEME", "Bibata-Modern-Ice" },
    { "ELECTRON_USE_OZONE", "1" },
    { "OZONE_PLATFORM", "wayland" },
    { "MOZ_ENABLE_WAYLAND", "1" },
    { "ELECTRON_OZONE_PLATFORM_HINT", "auto" },
    { "WLR_NO_HARDWARE_CURSORS", "1" },
    { "WLR_RENDERER_ALLOW_SOFTWARE", "1" },
    { "MOZ_DISABLE_RDD_SANDBOX", "1" },
    { "NVD_BACKEND", "direct" },
    { "EGL_PLATFORM", "wayland" },
}

for _, entry in ipairs(variables) do
    hl.env(entry[1], entry[2])
end
