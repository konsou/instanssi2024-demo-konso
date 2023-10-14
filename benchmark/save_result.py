#!/usr/bin/env python3
import sys
import json
import threading
from typing import Dict, List

BASELINE_FILE = 'results/benchmark-baseline.jsonl'


def append_result_to_file(filename, data):
    """Append the data as a new line to the JSONL file."""
    with open(filename, 'a', encoding='utf-8') as file:
        file.write(json.dumps(data) + '\n')


def structure_data(flat_data_dict: Dict) -> Dict:
    structured_data = {
        "status": flat_data_dict.get("benchmark_status", ""),
        "timestamp": flat_data_dict.get("timestamp", ""),
        "commit": {
            "hash": flat_data_dict.get("commit_hash", ""),
            "timestamp": flat_data_dict.get("commit_timestamp", ""),
            "message": flat_data_dict.get("commit_message", ""),
            "author": {
                "name": flat_data_dict.get("author_name", ""),
                "email": flat_data_dict.get("author_email", "")
            },
        },
        "environment": {
            "hostname": flat_data_dict.get("hostname", ""),
            "cpu": {
                "name": flat_data_dict.get("cpu_name", ""),
                "cores": int(flat_data_dict.get("cpu_cores", 0))
            },
            "gpu": {
                "name": flat_data_dict.get("gpu_name", ""),
                "vram": flat_data_dict.get("gpu_vram", "")
            },
            "cpu_load_averages": flat_data_dict.get("cpu_load_averages", "")
        },
        "settings": {
            "runtime_seconds": int(flat_data_dict.get("runtime_seconds", 60)),
            "fps_limit": int(flat_data_dict.get("fps_limit", 999))
        },
        "results": {
            "total": {
                "runtime_ms": int(flat_data_dict.get("total_runtime_ms", 0))
            },
            "setup": {
                "runtime_ms": int(flat_data_dict.get("setup_runtime_ms", 0))
            },
            "draw": {
                "runtime_ms": int(flat_data_dict.get("draw_runtime_ms", 0)),
                "frame_count": int(flat_data_dict.get("draw_frame_count", 0)),
                "average_fps": float(flat_data_dict.get("draw_average_fps", 0.0))
            }
        },
        "difference_from_baseline": {
            "frames": int(flat_data_dict.get("difference_frames", 0)),
            "percentage": float(flat_data_dict.get("difference_percentage", 0.0))
        },
    }
    return structured_data


def read_baseline_data(filename) -> Dict:
    """Read and return the latest baseline data from the given JSONL file."""
    try:
        with open(filename, 'r', encoding='utf-8') as file:
            lines = file.readlines()
            if lines:
                return json.loads(lines[-1].strip())
            else:
                print(f"Warning: No baseline data found in {filename}. Baseline info not available.")
                return {}
    except (FileNotFoundError, json.JSONDecodeError):
        print(f"Warning: couldn't read baseline data from {filename}. Baseline info not available.")
        return {}


def read_from_stdin(timeout=2) -> List:  # 2 seconds timeout by default
    """Attempt to read from stdin, returning an empty list if the timeout is exceeded."""
    result = []

    def target():
        while True:
            line = sys.stdin.readline()
            if not line:
                break
            result.append(line)

    thread = threading.Thread(target=target)
    thread.daemon = True
    thread.start()
    thread.join(timeout)

    if thread.is_alive():
        # Timeout reached
        return []

    return result


def main():
    if len(sys.argv) < 2:
        print(f"ERROR: no output filename specified.")
        sys.exit(1)

    raw_data = read_from_stdin(timeout=2)
    if not raw_data:
        print("ERROR: no input in stdin. Exiting.")
        sys.exit(1)

    data_dict = {}
    for line in raw_data:
        key, value = line.strip().split('=')
        data_dict[key] = value

    baseline_data = read_baseline_data(BASELINE_FILE)
    structured_data = structure_data(data_dict)

    structured_data['baseline'] = baseline_data

    # Save the entry to the specified file
    append_result_to_file(sys.argv[1], structured_data)


if __name__ == "__main__":
    main()
