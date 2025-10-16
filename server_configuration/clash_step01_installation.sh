#!/bin/bash

# Function to log messages
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log "-----------------------"
log "Start 'clash' install."

# Check if the system is Ubuntu
# Now, this script only runs on Ubuntu
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        log "This script is intended for Ubuntu systems."
        log "Exiting..."
        exit 1
    fi
else
    log "Unable to determine the distribution."
    log "Exiting..."
    exit 1
fi

# Define variables
clash_dir="/opt/clash"

# Check if the 'clash' directory exists and create it if it doesn't
if [ ! -d "$clash_dir" ]; then
    log "Creating 'clash' directory."
    sudo mkdir "$clash_dir"
fi

# Change permissions of the 'clash' directory
sudo chmod 777 "$clash_dir"

# Check if the 'clash' archive file exists
if [ -f softwares/clash/clash-linux-amd64-v1.17.0.gz ]; then
    log "'clash' had existed."
    cp softwares/clash/clash-linux-amd64-v1.17.0.gz clash-linux-amd64-v1.17.0.gz
else
    log "'clash' never exist!!!!!!"
    # wget https://github.com/Dreamacro/clash/releases/download/v1.17.0/clash-linux-amd64-v1.17.0.gz
fi

# Extract 'clash' archive and move it to the 'clash' directory
gunzip clash-linux-amd64-v1.17.0.gz
sudo mv clash-linux-amd64-v1.17.0 "$clash_dir/clash"

# Change permissions of the 'clash' executable
sudo chmod 777 "$clash_dir/clash"

# Start 'clash' and wait for a few seconds
"$clash_dir/clash" &
log "Starting 'clash'."
sleep 3

# Terminate 'clash'
log "Terminating 'clash'."
killall clash

log "'clash' install completed."
log "-----------------------"
