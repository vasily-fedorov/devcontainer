#!/usr/bin/env -S docker build . --tag=devcontainer --network=host --file
ARG IMAGE=ubuntu:24.04
FROM $IMAGE AS base
ARG PYTHON_VERSION=3.12
ARG USER_ID=${UID}
ARG USER_NAME=${COMPOSE_PROJECT_NAME}
ARG BUILD_SH=""
ARG PORT=5678
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive
# https://docs.python.org/3/library/asyncio-dev.html#debug-mode
ENV PYTHONASYNCIODEBUG=1
# for .bashrc
ENV PROMPT_COMMAND='history -a'

RUN rm -f /etc/apt/apt.conf.d/docker-clean ; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# pyenv setup
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt -y install --no-install-recommends --no-install-suggests \
    adduser sudo python3 bash python3-venv python3-pip gcc \
    build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl git \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

RUN adduser --disabled-password --uid $USER_ID $USER_NAME && adduser $USER_NAME sudo
RUN echo "$USER_NAME ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/$USER_NAME
USER $USER_NAME

# ENV PYENV_ROOT=/home/$USER_NAME/.pyenv
# ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
# WORKDIR /workspace
# RUN curl https://pyenv.run | bash && CC=gcc pyenv install $PYTHON_VERSION
# RUN <<EOF
#     pyenv global $PYTHON_VERSION && pyenv rehash
#     pyenv virtualenv $PYTHON_VERSION workspace
#     pip install setuptools # https://stackoverflow.com/questions/69919970/no-module-named-distutils-util-but-distutils-is-installed
# EOF
WORKDIR /home/$USER_NAME
COPY .devcontainer devcontainer
#RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
#    --mount=type=cache,target=/var/lib/apt,sharing=locked \
#    --mount=type=cache,target=/root/.cache,sharing=locked \
#    --mount=type=cache,target=/home/$USER_NAME/.cache,sharing=locked \
#    bash /home/$USER_NAME/devcontainer/features/features.sh

# project build.sh
WORKDIR /workspace
#COPY $BUILD_SH $BUILD_SH
#COPY requirements.txt requirements.txt
COPY . .
# RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
#     --mount=type=cache,target=/var/lib/apt,sharing=locked \
#     --mount=type=cache,target=/root/.cache,sharing=locked \
#     --mount=type=cache,target=/home/$USER_NAME/.cache/pip,sharing=locked \
#     sh $BUILD_SH
# Expose the port that the application listens on.
#EXPOSE $PORT
# for debugpy
EXPOSE 5678
# Run the application.
CMD sleep infinity
#CMD sh -c "./cmd.sh"
