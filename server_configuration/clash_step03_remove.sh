#!/bin/bash

# Function to log messages
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log "-----------------------"
log "Start 'clash' removal."

# Stop and disable the systemd service
sudo systemctl stop clash_running.service
sudo systemctl disable clash_running.service

# Remove the systemd service file
sudo rm /lib/systemd/system/clash_running.service
sudo rm /etc/systemd/system/clash_running.service

# Remove the startup script
sudo rm /etc/clash_running

# Remove Clash files from the user's home directory
sudo rm -rf ~/.config/clash/

# Remove Clash executable and associated files from installation directory
sudo rm -rf /opt/clash/clash
sudo rmdir /opt/clash # If it's empty after removing the executable

# Revert permissions of directories if needed (unlikely)
if [ -d "/opt/clash" ]; then
    sudo chmod 755 /opt/clash
fi

if [ -d "~/.config/clash" ]; then
    sudo chmod 700 ~/.config/clash
fi

log "'clash' has been successfully removed."
log "-----------------------"
