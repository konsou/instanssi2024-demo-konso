#!/usr/bin/env bash
# processing-java should be in PATH
# Xvfb should be installed for pseudo-display
RUNTIME_SECONDS=60
FPS_CAP=999

# Check if the lock file exists before trying to remove it
if [ -e /tmp/.X99-lock ]; then
  echo "Cleaning up Xvfb display 99"
  sudo rm /tmp/.X99-lock
fi

sudo Xvfb :99 & # Start Xvfb on display 99
export DISPLAY=:99.0

processing-java --sketch=$(pwd) --run auto-benchmark $RUNTIME_SECONDS $FPS_CAP

# Clean up Xvfb
sudo pkill -f "Xvfb :99"