#!/bin/bash

# Define the options
items="  Sleep\n  Shutdown\n󰜉  Reboot\n󰍃  Logout"

# Get the choice using Walker in dmenu mode
choice=$(echo -e "$items" | fuzzel --dmenu --index)

case "$choice" in
    "0")
      systemctl suspend
        ;;
    "1")
      systemctl poweroff
        ;;
    "2")
      systemctl reboot
        ;;
    "3")
      loginctl kill-session $XDG_SESSION_ID
        ;;
    *)
      echo "no match!"
        ;;
esac

