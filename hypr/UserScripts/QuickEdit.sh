#!/bin/bash
# Rofi menu for Quick Edit / View of Settings (SUPER E)

# define your preferred text editor and terminal to use
editor=nvim
tty=kitty

luaConfig="$HOME/.config/hypr/lua"

menu(){
  printf "1. view Env-variables\n"
  printf "2. view Window-Rules\n"
  printf "3. view Startup_Apps\n"
  printf "4. view User-Keybinds\n"
  printf "5. view Monitors\n"
  printf "6. view Laptop-Keybinds\n"
  printf "7. view User-Settings\n"
  printf "8. view Workspace-Rules\n"
  printf "9. view Default-Settings\n"
  printf "10. view Default-Keybinds\n"
}

main() {
    choice=$(menu | rofi -i -dmenu -config ~/.config/rofi/config-compact.rasi | cut -d. -f1)
    case $choice in
        1)
            $tty $editor "$luaConfig/environment.lua"
            ;;
        2)
            $tty $editor "$luaConfig/rules.lua"
            ;;
        3)
            $tty $editor "$luaConfig/startup.lua"
            ;;
        4)
            $tty $editor "$luaConfig/bindings.lua"
            ;;
        5)
            $tty $editor "$luaConfig/monitors.lua"
            ;;
        6)
            $tty $editor "$luaConfig/laptops.lua"
            ;;
        7)
            $tty $editor "$luaConfig/settings.lua"
            ;;
        8)
            $tty $editor "$luaConfig/workspaces.lua"
            ;;
		9)
            $tty $editor "$luaConfig/startup.lua"
            ;;
        10)
            $tty $editor "$luaConfig/bindings.lua"
            ;;
        *)
            ;;
    esac
}

main
