###############################################################################
## Stigmee: The art to sanctuarize knowledge exchanges.
## Copyright 2021-2022 Quentin Quadrat <lecrapouille@gmail.com>
##
## This file is part of Stigmee.
##
## Stigmee is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
#
# Dockerfile for compiling Stigmee. Can be called manually:
#   docker build -t stigmee .
# If you want to push on https://hub.docker.com/ replace lecrapouille by your
# login:
#   docker login
#   docker tag stigmee:latest lecrapouille/stigmee:latest
#   docker push lecrapouille/stigmee:latest
# How to use this docker:
#   mkdir <WORKSPACE_STIGMEE>
#   cd <WORKSPACE_STIGMEE>
#   docker run --rm -it -v $(pwd):$(pwd) -w $(pwd) stigmee:latest
#
###############################################################################

# Debian 11
FROM debian:bullseye-slim

# Install general system packages
RUN apt-get update && apt upgrade -y
RUN apt-get install -y bash wget curl lsb-release flex git-core gperf pkg-config zip bzip2 p7zip patch xz-utils sudo

# Install packages needed for compiling Godot and Stigmee
RUN apt-get install -y build-essential scons build-essential yasm scons pkg-config libx11-dev libxcursor-dev
RUN apt-get install -y libxinerama-dev libgl1-mesa-dev libglu-dev libasound2-dev libpulse-dev libudev-dev libxi-dev
RUN apt-get install -y libxrandr-dev ninja-build libcurl4 libcurl4-openssl-dev libssl-dev sshpass
RUN apt-get install -y libnss3 libpango1.0-dev libcairo2-dev libatk1.0-dev libatk-bridge2.0-dev libatspi2.0-dev libcups2-dev
RUN apt-get install -y libxkbcommon-dev libxcomposite-dev

# Create alias to bash (just in case of)
RUN if [ ! -e "/usr/bin/bash" ]; then ln -ns /bin/bash /usr/bin/bash; fi

# Install fresh CMake version
ARG CMAKE_VERSION=3.23.1
ARG CMAKE_URL=https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz
RUN wget -qO- $CMAKE_URL | tar xvz
RUN cd cmake-$CMAKE_VERSION && ./bootstrap && gmake -j$(nproc) && make install

# Install python packages
#ENV LANGUAGE "en_US"
#ENV LANG "en_US.UTF-8"
RUN apt-get install -y python3 python3-pip
RUN python3 -m pip install packaging python3_wget scons tsrc pysftp

# Configure git settings (/etc/gitconfig). Need to be root.
RUN git config --system push.default simple
RUN git config --system user.name "Stigmeer From Docker"
RUN git config --system user.email "stigmeer.docker@noemail.com"

# Do not git clone from SSH but HTTPS: the Stigmee repo manifest is configured
# to use SSH but from docker we do not constrain the user to share its ssh config.
RUN git config --system url."https://github.com/".insteadOf git@github.com:

# Clean and supress repo lists needed for apt-get install.
# No more installation will be able after this command.
# Need to be root.
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create Stigmee user and activate it.
ENV USER "stigmeer"
ENV USERNAME "stigmeer"
RUN adduser --quiet --disabled-password --gecos '' $USERNAME
USER $USERNAME

# Install Rust. Do not call it as root.
# FIXME: install needed packages
ENV CARGO_HOME "/home/$USERNAME/.cargo"
ENV PATH="${CARGO_HOME}/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y

# Install Godot templates. Call it as non root use.
ENV GODOT_VERSION=3.4.3
ENV GODOT_TEMPLATE_URL="https://downloads.tuxfamily.org/godotengine/$GODOT_VERSION/Godot_v""$GODOT_VERSION""-stable_export_templates.tpz"
ENV TEMPLATES_PATH=/home/$USERNAME/.local/share/godot/templates
RUN mkdir -p $TEMPLATES_PATH
RUN cd $TEMPLATES_PATH && \
    wget -O "3.4.3.stable.zip" $GODOT_TEMPLATE_URL && \
    unzip "3.4.3.stable.zip" && \
    mv templates "3.4.3.stable" && \
    rm "3.4.3.stable.zip"

# Setup entry point script
ADD entrypoint.sh /usr/bin
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]
