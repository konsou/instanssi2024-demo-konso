#!/usr/bin/env bash

# Configurable variables
GIT_REPO_DIR="/home/erkki/instanssi2024DemoKonso"
BENCHMARK_AUTHOR="stress-erkki"
BENCHMARK_LOG="${GIT_REPO_DIR}/perf-measurements.log"
WATCHER_LOG="${GIT_REPO_DIR}/benchmark-watcher.log"
LOCK_FILE="/tmp/konso-demo-benchmark.lock"

# log_with_timestamp [COMMIT_HASH]
# Logs a message to WATCHER_LOG with a timestamp prepended.
# If a COMMIT_HASH is provided, it will be included after the timestamp.
# Messages are read from standard input (piped into the function).
# Usage:
#     echo "This is my log message" | log_with_timestamp
#     echo "This is a message with a commit hash" | log_with_timestamp "abcd1234"
log_with_timestamp() {
    local commit_hash="${1:-}" # If provided, use the commit hash, otherwise default to an empty string
    while read -r line; do
        if [ -n "$commit_hash" ]; then
            echo "$(date +'%Y-%m-%d %H:%M') | $commit_hash | $line" | tee -a $WATCHER_LOG
        else
            echo "$(date +'%Y-%m-%d %H:%M') | $line" | tee -a $WATCHER_LOG
        fi
    done
}

# Check for lock file to determine if another instance of this script or benchmark is running
if [ -e "${LOCK_FILE}" ]; then
    echo "Another instance of the script or benchmark is running" | log_with_timestamp
    exit 1
fi

# Create a lock file
touch "${LOCK_FILE}"

# Pull the newest changes from git
cd "${GIT_REPO_DIR}" || { echo "Can't change to GIT_REPO_DIR ${GIT_REPO_DIR}" | log_with_timestamp; exit 1; }
git pull | log_with_timestamp

# Check author of the latest commit
LATEST_COMMIT_AUTHOR=$(git log -1 --pretty=format:"%an")

# Check commit hash of the latest commit
LATEST_COMMIT_HASH=$(git rev-parse HEAD)

# Check if the benchmark was run for this commit
if grep -q "${LATEST_COMMIT_HASH}" "${BENCHMARK_LOG}"; then
    echo "Benchmark already run for the latest commit" | log_with_timestamp "${LATEST_COMMIT_HASH}"
    rm "${LOCK_FILE}"
    exit 0
fi

# If the commit author is not BENCHMARK_AUTHOR, then run the benchmark
if [ "${LATEST_COMMIT_AUTHOR}" != "${BENCHMARK_AUTHOR}" ]; then
    echo "Starting benchmark" | log_with_timestamp "${LATEST_COMMIT_HASH}"
    if ! ./benchmark.sh; then
        echo "Benchmark script failed" | log_with_timestamp "${LATEST_COMMIT_HASH}"
        exit 1
    fi
    echo "Benchmark complete" | log_with_timestamp "${LATEST_COMMIT_HASH}"
fi

# Remove lock file at the end
rm "${LOCK_FILE}"
