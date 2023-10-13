import json
import re
import argparse

baseline_data = {
        "commit": {
            "hash": "17ed0ea69e87285b2b333ce68d2dae2e902d5d76",
            "timestamp": "Thu Oct 12 12:58:25 2023 +0300",
            "message": "Don't count setup time in FPS calculations",
            "author": {
                "name": "Tomi Javanainen",
                "email": "tomi.javanainen@gmail.com"
            },
        },
        "environment": {
            "cpu_load_averages": "0.00, 0.00, 0.00"
        },
        "settings": {
            "runtime_seconds": 60,
            "fps_limit": 999
        },
        "results": {
            "total": {
                "runtime_ms": 60167
            },
            "setup": {
                "runtime_ms": 163
            },
            "draw": {
                "runtime_ms": 60004,
                "frame_count": 9211,
                "average_fps": 153.50642
            }
        }
    }

def extract_data_from_log(log):
    # Strip ANSI escape sequences
    log = re.sub(r'\x1B\[[0-?]*[ -/]*[@-~]', '', log)

    # Extract necessary information using regex
    git_hash_match = re.search(r'commit (\w+)', log)
    author_match = re.search(r'Author: (.+) <(.+)>', log)
    commit_timestamp_match = re.search(r'Date:   (.+)', log)
    commit_message_match = re.search(r'\n\n    (.+)', log)
    load_average_match = re.search(r'Load [aA]verages? before benchmark:  (.+)', log)
    frame_count_draw_match = re.search(r'Frame count \(draw\):   (\d+)', log)
    average_fps_match = re.search(r'Average FPS \(draw\):   ([\d\.]+)', log)
    difference_from_baseline_match = re.search(r'Difference from baseline: (-?\d+) frames \((-?[\d\.]+)%\)', log)

    if not (git_hash_match and frame_count_draw_match and average_fps_match):
        return None

    data = {
        "timestamp": "", # Not present in the logs, will need an external method to obtain.
        "commit": {
            "hash": git_hash_match.group(1),
            "timestamp": commit_timestamp_match.group(1) if commit_timestamp_match else "",
            "message": commit_message_match.group(1) if commit_message_match else "",
            "author": {
                "name": author_match.group(1) if author_match else "",
                "email": author_match.group(2) if author_match else ""
            },
        },
        "environment": {
            "hostname": "",  # Not present in the logs, will need an external method to obtain.
            "cpu": {
                "name": "",  # Not present in the logs, will need an external method to obtain.
                "cores": 0   # Not present in the logs, will need an external method to obtain.
            },
            "gpu": {
                "name": "",  # Not present in the logs, will need an external method to obtain.
                "vram": ""   # Not present in the logs, will need an external method to obtain.
            },
            "cpu_load_averages": load_average_match.group(1) if load_average_match else ""
        },
        "settings": {
            "runtime_seconds": 60,
            "fps_limit": 999
        },
        "results": {
            "total": {
                "runtime_ms": int(re.search(r'Runtime \(total\):      (\d+) ms', log).group(1)) if re.search(r'Runtime \(total\):      (\d+) ms', log) else 0
            },
            "setup": {
                "runtime_ms": int(re.search(r'Runtime \(setup\):      (\d+) ms', log).group(1)) if re.search(r'Runtime \(setup\):      (\d+) ms', log) else 0
            },
            "draw": {
                "runtime_ms": int(re.search(r'Runtime \(draw\):       (\d+) ms', log).group(1)) if re.search(r'Runtime \(draw\):       (\d+) ms', log) else 0,
                "frame_count": int(frame_count_draw_match.group(1)),
                "average_fps": float(average_fps_match.group(1))
            }
        },
        "baseline": baseline_data
    }

    if difference_from_baseline_match:
        data["difference_from_baseline"] = {
            "frames": int(difference_from_baseline_match.group(1)),
            "percentage": float(difference_from_baseline_match.group(2))
        }

    return data


def main(input_file, output_file):


    with open(input_file, 'r') as f:
        logs = f.read().split("--------------------------\n")

    data_list = []
    for log in logs:
        data = extract_data_from_log(log)
        if data:
            data_list.append(data)

    with open(output_file, 'w') as f:
        for data in data_list:
            f.write(json.dumps(data) + '\n')

if __name__ == '__main__':

    #parser = argparse.ArgumentParser(description='Convert benchmark log to JSONL format.')
    #parser.add_argument('input_file', type=str, help='Path to the input log file.')
    #parser.add_argument('output_file', type=str, help='Path to the output JSONL file.')

    #args = parser.parse_args()
    main('results/benchmark.log', 'results/benchmark.jsonl')
