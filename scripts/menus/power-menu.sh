#!/bin/bash

# Define the options
items="  Sleep\n  Shutdown\n󰜉  Reboot\n󰍃  Logout"

# Get the choice using Walker in dmenu mode
output=$(echo -e "$items" | fuzzel --dmenu)

# Strip the emoji and keep only the label (everything after first space)
choice="${output#* }"

case "$choice" in
    "Sleep")
        systemctl suspend
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Logout")
        loginctl kill-session $XDG_SESSION_ID
        ;;
    *)
        ;;
esac

