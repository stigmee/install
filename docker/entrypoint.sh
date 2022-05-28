#!/bin/bash

# Set Stigmee workspace path
export WORKSPACE_STIGMEE=$(pwd)

# ???
export LIBGL_ALWAYS_INDIRECT=1

Xvfb :99 -ac -screen 0 "1920x1080x24" -nolisten tcp -nolisten unix &
XVFB_PROC=$!
sleep 1
export DISPLAY=:99

# Run as a non root user matching the permission of the actual folder.
OWNER=$(stat -c '%u' .)
OWNERGRP=$(stat -c '%g' .)
if [ "$OWNER" -ne "$(id -u)" ] && [ $(id -u) -eq 0 ]; then
  [ "$OWNER" -ne "$(id -u $USERNAME)" ] && usermod -u $OWNER $USERNAME
  [ "$OWNERGRP" -ne "$(id -g $USERNAME)" ] && groupmod -g $OWNERGRP $USERNAME

  # Exec the arguments passed to this script or if none have been passed,
  # then call the sudo shell (-s)
  exec sudo -EH -u $USERNAME "${@:--s}"
fi

# Exec the arguments passed to this script or if none have been passed
# then call bash
export USER=$(id -nu)
exec "${@:-bash}"
