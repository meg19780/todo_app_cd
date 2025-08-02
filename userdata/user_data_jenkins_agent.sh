#!/bin/bash

# Update and install prerequisites
apt update -y
apt install -y openjdk-21-jre-headless git curl ca-certificates gnupg lsb-release software-properties-common 

# Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add 'ubuntu' user to docker group
usermod -aG docker ubuntu

# Install Python 3.12 and venv
apt install -y python3.12-venv

# Install Google Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-linux.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
  | tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
apt update -y
apt install -y google-chrome-stable

#install ansible
apt-add-repository --yes --update ppa:ansible/ansible
apt install -y ansible

