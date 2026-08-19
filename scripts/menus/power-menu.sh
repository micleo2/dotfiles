#!/bin/bash

# Define the options
items="  Sleep\n  Shutdown\n󰜉  Reboot\n󰍃  Logout"

# Get the choice using rofi
choice=$(echo -e "$items" | rofi -dmenu -p "Power")

case "$choice" in
    *Sleep*)
      systemctl suspend
        ;;
    *Shutdown*)
      systemctl poweroff
        ;;
    *Reboot*)
      systemctl reboot
        ;;
    *Logout*)
      loginctl kill-session $XDG_SESSION_ID
        ;;
    *)
      echo "no match!"
        ;;
esac

