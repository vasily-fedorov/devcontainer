#!/usr/bin/env sh

# Add Docker's official GPG key:
sudo apt update
sudo apt -y install  --no-install-recommends --no-install-suggests \
    ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt -y install  --no-install-recommends --no-install-suggests \
    docker-ce-cli
sudo chmod a+rw /var/run/docker.sock # mount point
