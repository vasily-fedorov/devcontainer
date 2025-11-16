#!/usr/bin/env sh
set -e

# Exit early if not run as root or with sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges" >&2
    exit 1
fi

# Update package index and install prerequisites
apt update
apt -y install --no-install-recommends --no-install-suggests \
    ca-certificates curl

# Create directory for Docker's GPG key and set proper permissions
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod 644 /etc/apt/keyrings/docker.asc

# Add Docker repository to Apt sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with new repository and install Docker
apt update
apt -y install --no-install-recommends --no-install-suggests \
    docker-ce-cli docker-compose-plugin

# Create docker group if it doesn't exist and add current user
groupadd -f docker
usermod -aG docker "$USERNAME"

echo "Docker installation completed. Please log out and log back in for group changes to take effect."
