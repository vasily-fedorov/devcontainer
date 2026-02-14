#!/usr/bin/env -S docker build . --tag=devcontainer --network=host --file
ARG IMAGE=ubuntu:latest
FROM $IMAGE AS base
ARG USER_ID=${UID}
ARG USERNAME=${COMPOSE_PROJECT_NAME}
ARG PORT=8642
ENV USERNAME=${USERNAME}
ENV DEBIAN_FRONTEND=noninteractive
# for .bashrc
ENV PROMPT_COMMAND='history -a'

RUN rm -f /etc/apt/apt.conf.d/docker-clean ; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt -y install --no-install-recommends --no-install-suggests \
    adduser sudo curl bash less ca-certificates ssh-client

# If UID is 1000, rename the existing user instead of creating a new one
RUN if [ "$USER_ID" = "1000" ]; then \
        existing_user=$(getent passwd 1000 | cut -d: -f1); \
        if [ -n "$existing_user" ] && [ "$existing_user" != "$USERNAME" ]; then \
            usermod -l $USERNAME $existing_user && \
            usermod -d /home/$USERNAME -m $USERNAME && \
            groupmod -n $USERNAME $existing_user; \
        fi; \
    else \
        adduser --disabled-password --uid $USER_ID $USERNAME && adduser $USERNAME sudo; \
    fi

RUN echo "$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/$USERNAME

USER $USERNAME
COPY --chown=$USER_ID .devcontainer /workspace/.devcontainer
USER root
# features begin: run install.sh for every feature
# features end
USER $USERNAME
WORKDIR /workspace
CMD ["sh", "-c", "sh /workspace/.devcontainer/cmd.sh && sleep infinity"]
