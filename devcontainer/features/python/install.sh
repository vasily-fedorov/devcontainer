#!/usr/bin/env sh

sudo apt install curl gcc bash
curl https://pyenv.run | bash
CC=gcc pyenv install $PYTHON_VERSION
pyenv global $PYTHON_VERSION
pyenv rehash
pyenv virtualenv $PYTHON_VERSION workspace
pip install setuptools
