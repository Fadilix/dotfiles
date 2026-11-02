# Monitor profiles

Add profiles to this directory as Lua files containing one or more `hl.monitor({...})` calls. The Rofi picker lists these files, copies the chosen profile to `../active_monitor_profile.lua`, and reloads Hyprland.

The former `.conf` profiles were converted from `~/.config/hypr/Monitor_Profiles/`. Their original files are preserved in the pre-Lua backup at `~/.local/share/hypr-config-backups/pre-lua-20261102/Monitor_Profiles/`.
