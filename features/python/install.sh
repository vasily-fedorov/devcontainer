#!/usr/bin/env sh
export PYTHON_VERSION=3.12
export PYENV_ROOT=/home/$USER_NAME/.pyenv
export PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

sudo apt update
sudo apt -y install  --no-install-recommends --no-install-suggests \
make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl git \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
gcc ca-certificates python3-pip

export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
# https://docs.python.org/3/library/asyncio-dev.html#debug-mode
export PYTHONASYNCIODEBUG=1

curl https://pyenv.run | bash

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile
echo 'eval "$(pyenv init - bash)"' >> ~/.profile

CC=gcc pyenv install $PYTHON_VERSION
pyenv global $PYTHON_VERSION
pyenv rehash
cd /workspace
pyenv virtualenv $PYTHON_VERSION workspace
pip install setuptools
