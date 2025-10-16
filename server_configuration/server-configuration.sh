#!/bin/bash

# Warning Warning Warning: the following operations are dangerous for system
# ssh install
sudo apt update
sudo apt install openssh-server
# Set ssh automatic
sudo systemctl enable ssh
# Run ssh
sudo service ssh start
sudo service ssh restart

sudo passwd
# 创建新用户
sudo adduser mengxu

# 授权新用户权限
# sudo su -
# visudo
# Write into the last line of file as following: mengxu ALL=(ALL:ALL) NOPASSWD:ALL
echo 'mengxu ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers

# Remote control using xrdp
sudo apt install xrdp -y
# or
# wget https://www.c-nergy.be/downloads/xrdp-installer-1.4.6.zip
# unzip xrdp-installer-1.4.6.zip
# chmod +x xrdp-installer-1.4.6.sh
# ./xrdp-installer-1.4.6.sh

sudo systemctl enable xrdp
sudo systemctl restart xrdp
sudo systemctl status xrdp
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp

# git
sudo apt update
sudo apt install git

# github desktop
# https://github.com/shiftkey/desktop
# sudo apt install github-desktop
sudo wget https://github.com/shiftkey/desktop/releases/download/release-3.2.1-linux1/GitHubDesktop-linux-3.2.1-linux1.deb
sudo gdebi GitHubDesktop-linux-3.2.1-linux1.deb -y
rm GitHubDesktop-linux-3.2.1-linux1.deb

################################################################

# Warning Warning Warning: the following operations are dangerous for system
# Hard disk mounting and unmounting
cd /dev/
ls -l sda*
sudo fdisk -lu
sudo mount /dev/sdb2 /home/lilab/
# If mount fails, run
# sudo fuser -m /dev/sdb2
# sudo kill 'port'
sudo umount /dev/sdb2
