#!/usr/bin/env sh

sudo apt update
sudo apt -y install  --no-install-recommends --no-install-suggests \
    wget
wget https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-linux-amd64.deb -P ~/tmp
sudo dpkg -i ~/tmp/litestream-v0.3.13-linux-amd64.deb
