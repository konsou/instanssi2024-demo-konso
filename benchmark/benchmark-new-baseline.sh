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
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
RESULT_DIR="${SCRIPT_DIR}/results"
PROJECT_ROOT="${SCRIPT_DIR%/*}"
OUTPUT_FILENAME="${RESULT_DIR}/benchmark-baseline.log"
LOCK_FILE="/tmp/konso-demo-benchmark.lock"

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

echo "Updating benchmark baseline"
echo "Remove old baseline"
rm "${OUTPUT_FILENAME}"

# Compile
echo "Compiling"
javac -classpath "${PROJECT_ROOT}/lib/core.jar" -d "${PROJECT_ROOT}/out/" "${PROJECT_ROOT}/src/Instanssi2024DemoKonso.java"

# Check if the lock file exists before trying to remove it
if [ -e /tmp/.X99-lock ]; then
  echo "Cleaning up Xvfb display 99"
  sudo rm /tmp/.X99-lock
fi

sudo Xvfb :99 & # Start Xvfb on display 99
export DISPLAY=:99.0

# Run the benchmark
echo "--------------------------" >> "${OUTPUT_FILENAME}"
git log -1 >> "${OUTPUT_FILENAME}"
echo "Load Average before benchmark: $load_avg" | tee -a "${OUTPUT_FILENAME}"
java -classpath "${PROJECT_ROOT}/lib/core.jar:${PROJECT_ROOT}/out/" Instanssi2024DemoKonso auto-benchmark $RUNTIME_SECONDS $FPS_CAP | tee -a "${OUTPUT_FILENAME}"

# Push results
git add "${OUTPUT_FILENAME}"
git commit -m "Add new benchmark baseline"
git push

# Clean up Xvfb
sudo ./kill_xvfb.sh

# Only remove lockfile if not skipping lock checks
if [ "${SKIP_LOCK}" != "skip-lock" ]; then
  rm "${LOCK_FILE}"
fi
