#!/usr/bin/env bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DOTENV_FILE="${SCRIPT_DIR}/.env"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

source "${SCRIPT_DIR}/dotenv.sh"

load_venv "${DOTENV_FILE}" || exit 1

if [ -z "${XVFB_DISPLAY_NUM}" ]; then
    echo "Error: XVFB_DISPLAY_NUM is not set in ${DOTENV_FILE}." >&2
    exit 1
fi

/usr/bin/Xvfb "${XVFB_DISPLAY_NUM}"
