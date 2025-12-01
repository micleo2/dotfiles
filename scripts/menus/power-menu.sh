#!/bin/bash

# Define the options
items=" Shutdown\n󰜉 Reboot\n Sleep"

# Get the choice using Walker in dmenu mode
output=$(echo -e "$items" | walker -t ~/.config/walker/ --dmenu -H)

# Strip the emoji and keep only the label (everything after first space)
choice="${output#* }"

case "$choice" in
    "Shutdown")
        echo "gooing to poweroff"
        systemctl poweroff
        ;;
    "Reboot")
        echo "going to reboot"
        systemctl reboot
        ;;
    "Sleep")
        echo "going to sleep"
        systemctl suspend
        ;;
    *)
        ;;
esac

