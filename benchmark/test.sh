RUNTIME_SECONDS=60
FPS_CAP=999
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
RESULT_DIR="${SCRIPT_DIR}/results"
#PROJECT_ROOT="${SCRIPT_DIR}/.."
PROJECT_ROOT="${SCRIPT_DIR%/*}"
OUTPUT_FILENAME="${RESULT_DIR}/benchmark.log"
BASELINE_FILENAME="${RESULT_DIR}/benchmark-baseline.log"
LOCK_FILE="/tmp/konso-demo-benchmark.lock"

echo $SCRIPT_DIR
echo $RESULT_DIR
echo $PROJECT_ROOT
echo $OUTPUT_FILENAME
echo $BASELINE_FILENAME
echo
echo $(dirname "${BASH_SOURCE[0]}")

