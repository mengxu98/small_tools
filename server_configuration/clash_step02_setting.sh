#!/bin/bash

# Reference: https://blog.cyida.com/2023/24ANW6D.html

# Function to log messages
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Function to check if a command is available
command_exists() {
    command -v "$1" &>/dev/null
}

if [ -z "$1" ]; then
    read -s -p "Enter the root password: " password
else
    password="$1"
fi

log "-----------------------"
log "Start 'clash' set."

log "Settings system proxy as figure 'softwares/clash/clash_setting.png'"
log "Copy necessary files to '~/.config/clash/'"
sudo cat softwares/clash/config.yaml >~/.config/clash/config.yaml
sudo chmod 777 ~/.config/clash/config.yaml
sudo cp softwares/clash/Country.mmdb ~/.config/clash/Country.mmdb
sudo chmod 777 ~/.config/clash/Country.mmdb

# Write following test into a script name 'clash_running.sh':
sudo cat <<EOF > /etc/clash_running
#!/bin/bash

# sudo iptables -F # If you want to flush all iptables rules, run it

echo "${password}" | sudo -S modprobe gs_usb
# netstat -tunllp
# sudo netstat -anp | grep "7890"
# # Check if port 7890 is in use
# if ss -tuln | grep -q ":7890 "; then
#     echo "Port 7890 is in use."
#     kill -9 7840
# else
#     echo "Port 7890 is not in use."
# fi

/opt/clash/clash

EOF


sudo chmod 777 /etc/clash_running


cat <<EOF | sudo tee /lib/systemd/system/clash_running.service
#  SPDX-License-Identifier: LGPL-2.1+
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

# This unit gets pulled automatically into multi-user.target by
# systemd-rc-local-generator if /etc/rc.local is executable.
[Unit]
Description=/etc/clash_running Compatibility
Documentation=man:systemd-clash_running-generator(8)
ConditionFileIsExecutable=/etc/clash_running
After=network.target

[Service]
Type=forking
ExecStart=/etc/clash_running start
TimeoutSec=0
RemainAfterExit=yes
GuessMainPID=no
 
[Install]
WantedBy=multi-user.target
Alias=clash_running.service

EOF

cat <<EOF | sudo tee /etc/systemd/system/clash_running.service
#  SPDX-License-Identifier: LGPL-2.1+
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
    
# This unit gets pulled automatically into multi-user.target by
# systemd-rc-local-generator if /etc/rc.local is executable.
[Unit]
Description=/etc/clash_running Compatibility
Documentation=man:systemd-clash_running-generator(8)
ConditionFileIsExecutable=/etc/clash_running
After=network.target

[Service]
Type=forking
ExecStart=/etc/clash_running start
TimeoutSec=0
RemainAfterExit=yes
GuessMainPID=no
    
[Install]
WantedBy=multi-user.target
Alias=clash_running.service

EOF


sudo systemctl stop clash_running.service
sudo systemctl enable clash_running.service
sudo systemctl start clash_running.service
sudo systemctl restart clash_running.service

log "'clash' set completed."
log "-----------------------"
