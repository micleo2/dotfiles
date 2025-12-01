#!/bin/bash

# Define the options
items=" Shutdown\n󰜉 Reboot\n Sleep"

# Get the choice using Walker in dmenu mode
output=$(echo -e "$items" | walker -t ~/.config/walker/ --dmenu -H)

# Execute the choice
case "$output" in
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

