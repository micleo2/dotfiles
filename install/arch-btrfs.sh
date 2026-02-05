#!/bin/sh
set -euo pipefail

echo "sudo pacman -S --needed snapper snap-pac grub-btrfs inotify-tools"
sudo pacman -S --needed snapper snap-pac grub-btrfs inotify-tools
echo "paru -S btrfs-assistant"
paru -S btrfs-assistant

# setup snapshot configs
cd ~
echo "sudo snapper -c root create-config /"
sudo snapper -c root create-config /
echo "sudo snapper -c home create-config /home"
sudo snapper -c home create-config /home

# setup permissions
echo "sudo snapper -c root set-config ALLOW_USERS=\"$USER\" SYNC_ACL=yes"
sudo snapper -c root set-config ALLOW_USERS="$USER" SYNC_ACL=yes
echo "sudo snapper -c home set-config ALLOW_USERS=\"$USER\" SYNC_ACL=yes"
sudo snapper -c home set-config ALLOW_USERS="$USER" SYNC_ACL=yes

# disable automatic creation of snapshots
echo "sudo systemctl disable --now snapper-timeline.timer snapper-timeline.timer"
sudo systemctl disable --now snapper-timeline.timer snapper-timeline.timer

echo "Add 'grub-btrfs-overlayfs' to the HOOKS in /etc/mkinitcpio.conf"
echo "Then run 'sudo mkinitcpio -P'"
echo "Then run 'sudo systemctl enable --now grub-btrfsd.service'"
