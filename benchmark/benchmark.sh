#!/usr/bin/env bash
# This script runs a benchmark for the provided project.
# To ensure only one instance of this script runs at a time, it utilizes a lock mechanism.
# However, there may be scenarios where this lock should be overridden (e.g., when called by a watcher).
# To skip the lock check, pass "skip-lock" as a command-line argument.
# Example:
#     ./benchmark.sh skip-lock
# When run without arguments, the script will check for the lock:
#     ./benchmark.sh

RUNTIME_SECONDS=60
FPS_CAP=999
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DOTENV_FILE="${SCRIPT_DIR}/.env"
RESULT_DIR="${SCRIPT_DIR}/results"
PROJECT_ROOT="${SCRIPT_DIR%/*}"
BENCHMARK_RESULTS="${RESULT_DIR}/benchmark.log"
BASELINE_FILENAME="${RESULT_DIR}/benchmark-baseline.log"
DETAILED_LOG_DIR="${PROJECT_ROOT}/log"
DETAILED_LOG="${DETAILED_LOG_DIR}/benchmark-full.log"
LOCK_FILE="/tmp/konso-demo-benchmark.lock"

source "${SCRIPT_DIR}/dotenv.sh"
source "${SCRIPT_DIR}/discord.sh"

mkdir -p "${DETAILED_LOG_DIR}" || { echo "Failed to create log dir ${DETAILED_LOG_DIR}" >&2; exit 1; }

{ load_venv "${DOTENV_FILE}" ; } >> "${DETAILED_LOG}" 2>&1 || exit 1

if [ -z "${XVFB_DISPLAY_NUM}" ]; then
    echo "Error: XVFB_DISPLAY_NUM is not set in ${DOTENV_FILE}." | tee >(cat >&2) >> "${BENCHMARK_RESULTS}"
    exit 1
fi

if [ -z "${DISCORD_WEBHOOK}" ]; then
    echo "Error: DISCORD_WEBHOOK is not set in ${DOTENV_FILE}." | tee >(cat >&2) >> "${BENCHMARK_RESULTS}"
    exit 1
fi

# Xvfb display for headless operation
export DISPLAY="${XVFB_DISPLAY_NUM}"

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

parse_frame_count() {
  local log_filename=$1
  # Get the last occurrence of "Frame count (draw):" from the file
  grep "Frame count (draw):" "$log_filename" | tail -n 1 | awk '{print $4}'
}

parse_average_fps() {
  local log_filename=$1
  # Get the last occurrence of "Average FPS (draw):" from the file
  grep "Average FPS (draw):" "$log_filename" | tail -n 1 | awk '{print $4}'
}

remove_lockfile() {
  # Only remove lockfile if not skipping lock checks
  if [ "${SKIP_LOCK}" != "skip-lock" ]; then
    rm -f "${LOCK_FILE}"
  fi
}

# Run the benchmark
echo "--------------------------" >> "${BENCHMARK_RESULTS}"
echo "Benchmark started at $(date +'%Y-%m-%d %H:%M')" >> "${BENCHMARK_RESULTS}"
git log -1 >> "${BENCHMARK_RESULTS}"

# Compile
echo "Building"
(cd "${PROJECT_ROOT}" && mvn install:install-file "-Dfile=lib\core.jar" -DgroupId="processing.core" -DartifactId=core -Dversion="1.0" -Dpackaging=jar) || echo "Error adding core.jar to maven" | tee -a "${BENCHMARK_RESULTS}"
(cd "${PROJECT_ROOT}" && mvn compile) || echo "Error compiling" | tee -a "${BENCHMARK_RESULTS}"
# Check the exit status of the java command, not the tee
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "Build failed" | tee -a "${BENCHMARK_RESULTS}"
    remove_lockfile
    exit 1
fi

echo "Load averages before benchmark: $load_avg" | tee -a "${BENCHMARK_RESULTS}"
(cd "${PROJECT_ROOT}" && mvn exec:java -Dexec.args="--benchmark --runtime $RUNTIME_SECONDS --fps-cap $FPS_CAP") 2>&1 | tee -a "${BENCHMARK_RESULTS}"
# Check the exit status of the java command, not the tee
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "Running benchmark failed" | tee -a "${BENCHMARK_RESULTS}"
    remove_lockfile
    exit 1
fi

# Parse the frame counts and fps
baseline_frames=$(parse_frame_count "${BASELINE_FILENAME}")
current_frames=$(parse_frame_count "${BENCHMARK_RESULTS}")
average_fps=$(parse_average_fps "${BENCHMARK_RESULTS}")

# Calculate the difference and append to the log
difference=$((current_frames - baseline_frames))
percentage_change=$(echo "scale=2; ($current_frames - $baseline_frames) / $baseline_frames * 100" | bc)
echo "Difference from baseline: $difference frames ($percentage_change%)" | tee -a "${BENCHMARK_RESULTS}"

# Send results to discord
commit_message=$(git log -1 | tail -n1 | awk '{$1=$1};1')  # awk command trims whitespace
result_msg="\`Benchmark for commit (${commit_message}): ${current_frames} frames, ${average_fps} average FPS, difference from baseline: ${difference} frames (${percentage_change}%)\`"
send_discord_message "${DISCORD_WEBHOOK}" "${result_msg}"

# Push results
git add "${BENCHMARK_RESULTS}"
git commit -m "Add benchmark info"
git push

remove_lockfile