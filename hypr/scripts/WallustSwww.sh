#!/bin/bash
# /* ---- 💫 https://github.com/Fadilix 💫 ---- */  ##
# Wallust Colors for current wallpaper

# Define the path to the swww cache directory
cache_dir="$HOME/.cache/swww/"

# Initialize a flag to determine if the ln command was executed
ln_success=false

# Get current focused monitor
current_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')
echo $current_monitor
# Construct the full path to the cache file
cache_file="$cache_dir$current_monitor"
echo $cache_file
# Check if the cache file exists for the current monitor output
if [ -f "$cache_file" ]; then
    # awww can prefix cache entries with filter metadata (e.g. Lanczos3/path).
    raw_wallpaper_path=$(tr -d '\0' < "$cache_file")
    wallpaper_path=$(printf "%s" "$raw_wallpaper_path" | sed -E 's#^[^/]*(/.*)$#\1#')
    if [[ "$wallpaper_path" != /* ]]; then
        wallpaper_path="$raw_wallpaper_path"
    fi
    echo $wallpaper_path
    # symlink the wallpaper to the location Rofi can access
    if ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"; then
        ln_success=true  # Set the flag to true upon successful execution
    fi
    # copy the wallpaper for wallpaper effects
	cp -r "$wallpaper_path" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
fi

# Check the flag before executing further commands
if [ "$ln_success" = true ]; then
    # execute wallust
	echo 'about to execute wallust'
    # execute wallust skipping tty and terminal changes
    wallust run "$wallpaper_path" -s &
fi
