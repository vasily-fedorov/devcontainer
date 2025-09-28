#!/usr/bin/env -S docker build . --tag=devcontainer --network=host --file
ARG IMAGE=ubuntu:latest
FROM $IMAGE AS base
ARG PYTHON_VERSION=3.12
ARG USER_ID=${UID}
ARG USER_NAME=${COMPOSE_PROJECT_NAME}
ARG BUILD_SH=""
ARG PORT=5678
ENV USER_NAME=${USER_NAME}
ENV DEBIAN_FRONTEND=noninteractive
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
COPY --chown=$USER_ID .devcontainer /workspace/.devcontainer
#COPY --chown=$USER_ID .devcontainer/features.sh /home/$USER_NAME/devcontainer/features.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache,sharing=locked \
    --mount=type=cache,target=/home/$USER_NAME/.cache,sharing=locked \
    if [ -e /workspace/.devcontainer/features/features.sh ]; then sh /workspace/.devcontainer/features/features.sh; fi

WORKDIR /workspace
CMD sh /workspace/.devcontainer/cmd.sh & sleep infinity
