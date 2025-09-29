#!/usr/bin/env sh

# Add Docker's official GPG key:
sudo apt update
sudo apt -y install  --no-install-recommends --no-install-suggests \
    ca-certificates curl git
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
  docker-ce-cli docker-compose-plugin
if [ -e /var/run/docker.sock ];
then sudo chmod a+rw /var/run/docker.sock;
     fi;# mount point

# sudo apt-get update
# sudo apt-get -y install apt-transport-https \
#      ca-certificates \
#      curl \
#      gnupg2 \
#      software-properties-common
# curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; sudo apt-key add /tmp/dkey
# sudo add-apt-repository \
#    "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
#    $(lsb_release -cs) \
#    stable"
# sudo apt-get update
# sudo apt-get -y install docker-ce
