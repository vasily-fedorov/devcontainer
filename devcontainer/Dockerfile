#!/usr/bin/env -S docker build . --tag=devcontainer --network=host --file
ARG IMAGE=ubuntu:24.04
FROM $IMAGE AS base
ARG PYTHON_VERSION=3.12
ARG USER_ID=${UID}
ARG USER_NAME=${COMPOSE_PROJECT_NAME}
ARG BUILD_SH=""
ARG PORT=5678
ENV USER_NAME=${USER_NAME}
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive
# https://docs.python.org/3/library/asyncio-dev.html#debug-mode
ENV PYTHONASYNCIODEBUG=1
# for .bashrc
ENV PROMPT_COMMAND='history -a'

RUN rm -f /etc/apt/apt.conf.d/docker-clean ; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt -y install --no-install-recommends --no-install-suggests \
    adduser sudo curl bash less ca-certificates ssh-client

RUN adduser --disabled-password --uid $USER_ID $USER_NAME && adduser $USER_NAME sudo
RUN echo "$USER_NAME ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/$USER_NAME
USER $USER_NAME

COPY .devcontainer/features /home/$USER_NAME/devcontainer/features
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache,sharing=locked \
    --mount=type=cache,target=/home/$USER_NAME/.cache,sharing=locked \
    sh /home/$USER_NAME/devcontainer/features/features.sh

WORKDIR /workspace
CMD sleep infinity
