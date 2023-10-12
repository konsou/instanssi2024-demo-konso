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
OUTPUT_FILENAME=perf-measurements.log
BASELINE_FILENAME=perf-baseline.log
GIT_REPO=git@github.com:konsou/instanssi2024DemoKonso.git
LOCK_FILE="/tmp/konso-demo-benchmark.lock"


# Check for lock file to determine if another instance of this script or benchmark is running
if [ -e "${LOCK_FILE}" ]; then
    echo "Another instance of the script or benchmark is running."
    exit 0
fi

# Create a lock file
touch "${LOCK_FILE}"

# Capture CPU load
load_avg=$(uptime | awk -F'[a-z]:' '{ print $2 }')

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
baseline_frames=$(parse_frame_count $BASELINE_FILENAME)
current_frames=$(parse_frame_count $OUTPUT_FILENAME)

# Calculate the difference and append to the log
difference=$((current_frames - baseline_frames))
percentage_change=$(echo "scale=2; ($current_frames - $baseline_frames) / $baseline_frames * 100" | bc)
echo "Difference from baseline: $difference frames ($percentage_change%)" | tee -a $OUTPUT_FILENAME

# Push results
git add $OUTPUT_FILENAME
git commit -m "Add benchmark info"
git push $GIT_REPO

# Clean up Xvfb
sudo ./kill_xvfb.sh

# Remove lock file at the end
rm "${LOCK_FILE}"
