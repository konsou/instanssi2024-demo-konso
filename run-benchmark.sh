#!/usr/bin/env bash
# processing-java should be in PATH
# Xvfb should be installed for pseudo-display
RUNTIME_SECONDS=60
FPS_CAP=999
OUTPUT_FILENAME=perf-measurements.log

# Check if the lock file exists before trying to remove it
if [ -e /tmp/.X99-lock ]; then
  echo "Cleaning up Xvfb display 99"
  sudo rm /tmp/.X99-lock
fi

sudo Xvfb :99 & # Start Xvfb on display 99
export DISPLAY=:99.0

echo "--------------------------" >> $OUTPUT_FILENAME
git log -1 >> $OUTPUT_FILENAME
processing-java --sketch=$(pwd) --run auto-benchmark $RUNTIME_SECONDS $FPS_CAP | tee -a $OUTPUT_FILENAME

git add $OUTPUT_FILENAME
git commit -m "Add benchmark info"
git push

# Clean up Xvfb
sudo pkill -f "Xvfb :99"
