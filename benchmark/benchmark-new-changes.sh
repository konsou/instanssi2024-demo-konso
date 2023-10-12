#!/usr/bin/env bash

# Configurable variables
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
RESULT_DIR="${SCRIPT_DIR}/results"
GIT_REPO_DIR="${SCRIPT_DIR%/*}"
BENCHMARK_AUTHOR="stress-erkki"
BENCHMARK_SCRIPT="${SCRIPT_DIR}/benchmark.sh"
BENCHMARK_LOG="${RESULT_DIR}/benchmark.log"
WATCHER_LOG_DIR="${GIT_REPO_DIR}/log"
WATCHER_LOG="${WATCHER_LOG_DIR}/benchmark-watcher.log"
LOCK_FILE="/tmp/konso-demo-benchmark.lock"

# log_with_timestamp [TAG]
# Logs a message to WATCHER_LOG with a timestamp prepended.
# If a TAG is provided, it will be included after the timestamp.
# Messages are read from standard input (piped into the function).
# Usage:
#     echo "This is my log message" | log_with_timestamp
#     echo "This is a message with a tag" | log_with_timestamp "abcd1234"
log_with_timestamp() {
    local tag="${1:-}" # If provided, use the tag, otherwise default to an empty string
    while read -r line; do
        if [ -n "$tag" ]; then
            echo "$(date +'%Y-%m-%d %H:%M') | $tag | $line" | tee -a "${WATCHER_LOG}"
        else
            echo "$(date +'%Y-%m-%d %H:%M') | | $line" | tee -a "${WATCHER_LOG}"
        fi
    done
}

mkdir -p "${WATCHER_LOG_DIR}"

# Check for lock file to determine if another instance of this script or benchmark is running
if [ -e "${LOCK_FILE}" ]; then
    echo "Another instance of the script or benchmark is running" | log_with_timestamp LOCK_FILE
    exit 1
fi

# Create a lock file
touch "${LOCK_FILE}"

# Pull the newest changes from git
cd "${GIT_REPO_DIR}" || {
  rm -r "${LOCK_FILE}"
  echo "ERROR: Can't change to GIT_REPO_DIR ${GIT_REPO_DIR}" | log_with_timestamp SYSTEM
  exit 1
}
git pull 2>&1 | log_with_timestamp GIT_PULL

LATEST_COMMIT_AUTHOR=$(git log -1 --pretty=format:"%an")
LATEST_COMMIT_HASH_FULL=$(git rev-parse HEAD)
LATEST_COMMIT_HASH=$(git rev-parse --short HEAD)

# Check if the benchmark was run for this commit
if grep -q "${LATEST_COMMIT_HASH}" "${BENCHMARK_LOG}"; then
    echo "Benchmark already run for the latest commit" | log_with_timestamp "${LATEST_COMMIT_HASH}"
    rm "${LOCK_FILE}"
    exit 0
fi

# If the commit author is not BENCHMARK_AUTHOR, then run the benchmark
if [ "${LATEST_COMMIT_AUTHOR}" != "${BENCHMARK_AUTHOR}" ]; then
    echo "Starting benchmark" | log_with_timestamp "${LATEST_COMMIT_HASH}"
    echo "Full commit hash: ${LATEST_COMMIT_HASH_FULL}" | log_with_timestamp "${LATEST_COMMIT_HASH}"
    # Without skip-lock, benchmark would fail due to locking
    if ! "${BENCHMARK_SCRIPT}" skip-lock; then
        echo "Benchmark script failed - see ${BENCHMARK_LOG} for details" | log_with_timestamp "${LATEST_COMMIT_HASH}"
        tail -n 1 "${BENCHMARK_LOG}" | log_with_timestamp "${LATEST_COMMIT_HASH}"
        rm "${LOCK_FILE}"
        exit 1
    fi
    echo "Benchmark complete" | log_with_timestamp "${LATEST_COMMIT_HASH}"
else
    echo "Latest commit is a benchmark commit, not running" | log_with_timestamp "${LATEST_COMMIT_HASH}"
fi

# Remove lock file at the end
rm "${LOCK_FILE}"
