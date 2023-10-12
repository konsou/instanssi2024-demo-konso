#!/usr/bin/env bash
# requires: java 17 jdk
# Xvfb should be installed for pseudo-display
#
# Hacky fixes: run "sudo visudo" and add these lines:
# erkki ALL=NOPASSWD: /usr/bin/Xvfb
# erkki ALL=NOPASSWD: /bin/rm /tmp/.X99-lock
# erkki ALL=NOPASSWD: pkill -f "Xvfb :99"
# This prevents weird errors where rest of the script tries
# to proceed while the sudo password prompt is in the
# background somewhere

RUNTIME_SECONDS=60
FPS_CAP=999
OUTPUT_FILENAME=perf-baseline.log
GIT_REPO=git@github.com:konsou/instanssi2024DemoKonso.git

# Capture CPU load
load_avg=$(uptime | awk -F'[a-z]:' '{ print $2 }')

echo "Updating benchmark baseline"
echo "Remove old baseline"
rm $OUTPUT_FILENAME

# Compile
echo "Compiling"
javac -classpath lib/core.jar -d out/ src/Instanssi2024DemoKonso.java

# Check if the lock file exists before trying to remove it
if [ -e /tmp/.X99-lock ]; then
  echo "Cleaning up Xvfb display 99"
  sudo rm /tmp/.X99-lock
fi

sudo Xvfb :99 & # Start Xvfb on display 99
export DISPLAY=:99.0

parse_frame_count() {
  local log_filename=$1
  # Get the last occurrence of "Frame count (draw):" from the file
  grep "Frame count (draw):" "$log_filename" | tail -n 1 | awk '{print $3}'
}

# Run the benchmark
echo "--------------------------" >> $OUTPUT_FILENAME
git log -1 >> $OUTPUT_FILENAME
echo "Load Average before benchmark: $load_avg" | tee -a $OUTPUT_FILENAME
java -classpath out/:lib/core.jar Instanssi2024DemoKonso auto-benchmark $RUNTIME_SECONDS $FPS_CAP | tee -a $OUTPUT_FILENAME

# Parse the frame counts
current_frames=$(parse_frame_count $OUTPUT_FILENAME)

# Push results
git add $OUTPUT_FILENAME
git commit -m "Add new benchmark baseline"
git push $GIT_REPO

# Clean up Xvfb
sudo ./kill_xvfb.sh
