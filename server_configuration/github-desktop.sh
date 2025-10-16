#!/bin/bash

sudo apt update
sudo apt upgrade
sudo apt install wget apt-transport-https gnupg2 software-properties-common

# https://github.com/shiftkey/desktop
echo "Downloading GitHubDesktop."
wget https://github.com/shiftkey/desktop/releases/download/release-3.3.8-linux2/GitHubDesktop-linux-amd64-3.3.8-linux2.deb

echo "Insatlling GitHubDesktop."
sudo apt install -f ./GitHubDesktop-linux-amd64-3.3.8-linux2.deb

echo "Insatll completed."
