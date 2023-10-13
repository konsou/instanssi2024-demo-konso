#!/usr/bin/env python3
import sys
import json
from os.path import isfile
from typing import Dict

BASELINE_FILE = 'results/benchmark-baseline.jsonl'


def append_result_to_file(filename, data):
    """Append the data as a new line to the JSONL file."""
    with open(filename, 'a', encoding='utf-8') as file:
        file.write(json.dumps(data) + '\n')


def structure_data(flat_data_dict: Dict) -> Dict:
    structured_data = {
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
                print(f"WARNING: No baseline data found in {filename}. Baseline info not available.")
                return {}
    except (FileNotFoundError, json.JSONDecodeError):
        print(f"WARNING: couldn't read baseline data from {filename}. Baseline info not available.")
        return {}


def main():
    # Read key-value pairs from stdin
    raw_data = sys.stdin.readlines()
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
