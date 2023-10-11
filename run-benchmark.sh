#!/usr/bin/env bash
# processing-java should be in PATH
# Xvfb should be installed for pseudo-display
RUNTIME_SECONDS=60
FPS_CAP=999

sudo Xvfb :99 & # Start Xvfb on display 99
export DISPLAY=:99.0

processing-java --sketch=$(pwd) --run $RUNTIME_SECONDS $FPS_CAP
