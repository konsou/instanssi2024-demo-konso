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
BENCHMARK_RESULTS="${RESULT_DIR}/benchmark.jsonl"
BASELINE_FILENAME="${RESULT_DIR}/benchmark-baseline.jsonl"
DETAILED_LOG_DIR="${PROJECT_ROOT}/log"
DETAILED_LOG="${DETAILED_LOG_DIR}/benchmark-full.log"
LOCK_FILE="/tmp/konso-demo-benchmark.lock"

source "${SCRIPT_DIR}/dotenv.sh"
source "${SCRIPT_DIR}/discord.sh"

mkdir -p "${DETAILED_LOG_DIR}" || { echo "Failed to create log dir ${DETAILED_LOG_DIR}" >&2; exit 1; }

# Function definitions
parse_frame_count() {
  # Get the last occurrence of "Frame count (draw):" from the text
  echo "$1" | grep "Frame count (draw):" | tail -n 1 | awk '{print $4}'
}

parse_average_fps() {
  # Get the last occurrence of "Average FPS (draw):" from the text
  echo "$1" | grep "Average FPS (draw):" | tail -n 1 | awk '{print $4}'
}

remove_lockfile() {
  # Only remove lockfile if not skipping lock checks
  if [ "${SKIP_LOCK}" != "skip-lock" ]; then
    rm -f "${LOCK_FILE}"
  fi
}

log_with_timestamp() {
    # Not logging empty lines
    if [ -z "$1" ]; then return; fi
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S %z')
    echo "$1"
    echo "${timestamp} | $1" >> "${DETAILED_LOG}"
}

run_or_exit_and_log() {
    local output
    output=$("$@" 2>&1)
    local exit_code=$?

    # Log the output
    log_with_timestamp "$output"

    # If the command failed, exit the script
    if [ $exit_code -ne 0 ]; then
        log_with_timestamp "Error when running: $*"
        remove_lockfile
        exit $exit_code
    fi
}

# load_dotenv can't be run with run_or_exit_and_log since
# env variables stay inside the subshell there
load_dotenv "${DOTENV_FILE}" || log_with_timestamp "Warning: couldn't load env from ${DOTENV_FILE}"

if [ -z "${XVFB_DISPLAY_NUM}" ]; then
    log_with_timestamp "Error: XVFB_DISPLAY_NUM environment variable is not set"
    exit 1
fi

if [ -z "${DISCORD_WEBHOOK}" ]; then
    log_with_timestamp "Error: DISCORD_WEBHOOK environment variable is not set"
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

# 1. Gather available info before running the benchmark to result array
declare -A results_array

# Capture current commit details
results_array["timestamp"]=$(date +'%Y-%m-%d %H:%M:%S %z')
results_array["commit_hash"]=$(git rev-parse HEAD)
results_array["commit_timestamp"]=$(git show -s --format='%ci')
results_array["commit_message"]=$(git show -s --format='%s')
results_array["author_name"]=$(git show -s --format='%an')
results_array["author_email"]=$(git show -s --format='%ae')

results_array["hostname"]=$(hostname)
results_array["cpu_load_averages"]=$load_avg  # Assuming you've set this before

# 2. Build and compile
log_with_timestamp "Building"
output=$( (cd "${PROJECT_ROOT}" && mvn install:install-file "-Dfile=lib\core.jar" -DgroupId="processing.core" -DartifactId=core -Dversion="1.0" -Dpackaging=jar) 2>&1 )
mvn_exit_code=$?
log_with_timestamp "$output"
if [ $mvn_exit_code -ne 0 ]; then
    results_array["benchmark_status"]="ERROR"
    remove_lockfile
    exit 1
fi

output=$( (cd "${PROJECT_ROOT}" && mvn compile) 2>&1 )
mvn_exit_code=$?
log_with_timestamp "$output"
if [ $mvn_exit_code -ne 0 ]; then
    results_array["benchmark_status"]="ERROR"
    remove_lockfile
    exit 1
fi

# Capture the benchmark output
benchmark_output=$(cd "${PROJECT_ROOT}" && mvn exec:java -Dexec.args="--benchmark --runtime $RUNTIME_SECONDS --fps-cap $FPS_CAP" 2>&1)
mvn_exit_code=$?
log_with_timestamp "$benchmark_output"
if [ $mvn_exit_code -ne 0 ]; then
    results_array["benchmark_status"]="ERROR"
    remove_lockfile
    exit 1
fi

# 3. Parse the output for needed info and add to result array

# TODO: FIX COMPARISON
results_array["baseline_frames"]=$(./get_baseline.py results.draw.frame_count)
results_array["current_frames"]=$(parse_frame_count "$benchmark_output")
results_array["draw_average_fps"]=$(parse_average_fps "$benchmark_output")

difference=$((results_array["current_frames"] - results_array["baseline_frames"]))
percentage_change=$(echo "scale=2; ($difference) / ${results_array["baseline_frames"]} * 100" | bc)

results_array["difference_frames"]=$difference
results_array["difference_percentage"]=$percentage_change

# 4. Pipe the result array to our python script

# TODO: RESULTS NOT SAVING
# TODO: WILL RETRY FAILED BENCHMARKS FOREVER
for key in "${!results_array[@]}"; do
    echo "$key=${results_array[$key]}"
done | ./save_result.py "${BENCHMARK_RESULTS}"

# Send results to discord
result_msg="\`Benchmark for commit (${results_array['commit_message']}): ${results_array['current_frames']} frames, ${results_array['average_fps']} average FPS, difference from baseline: ${results_array['difference']} frames (${results_array['percentage_change']}%)\`"
send_discord_message "${DISCORD_WEBHOOK}" "${result_msg}"

# Push results
git add "${BENCHMARK_RESULTS}"
git commit -m "Add benchmark info"
git push

remove_lockfile