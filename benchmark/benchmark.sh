#!/usr/bin/env bash
# This script runs a benchmark for the provided project.
# To ensure only one instance of this script runs at a time, it utilizes a lock mechanism.
# However, there may be scenarios where this lock should be overridden (e.g., when called by a watcher).
# To skip the lock check, pass "skip-lock" as a command-line argument.
# Example:
#     ./benchmark.sh skip-lock
# When run without arguments, the script will check for the lock:
#     ./benchmark.sh
#
# requires: java 17 jdk
# Xvfb should be installed for pseudo-display

RUNTIME_SECONDS=60
FPS_CAP=999
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
RESULT_DIR="${SCRIPT_DIR}/results"
PROJECT_ROOT="${SCRIPT_DIR%/*}"
OUTPUT_FILENAME="${RESULT_DIR}/benchmark.log"
BASELINE_FILENAME="${RESULT_DIR}/benchmark-baseline.log"
LOCK_FILE="/tmp/konso-demo-benchmark.lock"

# Xvfb display for headless operation
export DISPLAY=:99.0

SKIP_LOCK=${1:-"false"}

# Check for lock file to determine if another instance of this script or benchmark is running
if [ "${SKIP_LOCK}" != "skip-lock" ] && [ -e "${LOCK_FILE}" ]; then
    echo "Another instance of the script or benchmark is running."
    exit 1
fi

# Create a lock file
touch "${LOCK_FILE}"

# Capture CPU load
load_avg=$(uptime | awk -F'[a-z]:' '{ print $2 }')

# Compile
echo "Compiling"
javac -classpath "${PROJECT_ROOT}/lib/core.jar" -d "${PROJECT_ROOT}/out/" "${PROJECT_ROOT}/src/Instanssi2024DemoKonso.java"

parse_frame_count() {
  local log_filename=$1
  # Get the last occurrence of "Frame count (draw):" from the file
  grep "Frame count (draw):" "$log_filename" | tail -n 1 | awk '{print $4}'
}

# Run the benchmark
echo "--------------------------" >> "${OUTPUT_FILENAME}"
git log -1 >> "${OUTPUT_FILENAME}"
echo "Load Average before benchmark: $load_avg" | tee -a "${OUTPUT_FILENAME}"
java -classpath "${PROJECT_ROOT}/lib/core.jar:${PROJECT_ROOT}/out/" Instanssi2024DemoKonso auto-benchmark $RUNTIME_SECONDS $FPS_CAP | tee -a "${OUTPUT_FILENAME}"

# Parse the frame counts
baseline_frames=$(parse_frame_count "${BASELINE_FILENAME}")
current_frames=$(parse_frame_count "${OUTPUT_FILENAME}")

# Calculate the difference and append to the log
difference=$((current_frames - baseline_frames))
percentage_change=$(echo "scale=2; ($current_frames - $baseline_frames) / $baseline_frames * 100" | bc)
echo "Difference from baseline: $difference frames ($percentage_change%)" | tee -a "${OUTPUT_FILENAME}"

# Push results
git add "${OUTPUT_FILENAME}"
git commit -m "Add benchmark info"
git push

# Only remove lockfile if not skipping lock checks
if [ "${SKIP_LOCK}" != "skip-lock" ]; then
  rm "${LOCK_FILE}"
fi
