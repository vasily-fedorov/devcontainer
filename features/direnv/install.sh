#!/usr/bin/env sh

sudo apt update
sudo apt -y install --no-install-recommends --no-install-suggests \
    direnv
mkdir -p ~/.config/direnv/
cat <<EOF > ~/.config/direnv/direnv.toml
[global]
load_dotenv = true
EOF
