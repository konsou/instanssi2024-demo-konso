#!/usr/bin/env python3
import sys
import json

BASELINE_FILE = 'results/benchmark-baseline.jsonl'


def get_value_from_baseline(key_path: str) -> str:
    """Retrieve the value from the baseline data given a dot-separated key path."""
    with open(BASELINE_FILE, 'r', encoding='utf-8') as file:
        # Assuming the baseline file has one JSON object per line
        # and you want the latest (last) entry:
        lines = file.readlines()
        if not lines:
            print(f"ERROR: Baseline file {BASELINE_FILE} is empty.")
            sys.exit(1)

        latest_entry = json.loads(lines[-1])

    keys = key_path.split('.')
    value = latest_entry

    for key in keys:
        if key in value:
            value = value[key]
        else:
            print(f"ERROR: Key '{key}' not found in baseline data.")
            sys.exit(1)

    return value


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: get_baseline.py <dot-separated-key-path>")
        sys.exit(1)

    key_path = sys.argv[1]
    result = get_value_from_baseline(key_path)
    print(result)
