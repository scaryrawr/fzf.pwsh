#!/usr/bin/env python3
import os
import sys
import json
import subprocess


def main():
    """Main function to display package information from cache file."""
    if len(sys.argv) < 3:
        print("Usage: fzf_package_preview.py <package_name> <cache_file>")
        sys.exit(1)

    target_name = sys.argv[1]
    cache_file = sys.argv[2]

    try:
        with open(cache_file, "r") as f:
            data = json.load(f)
    except (json.JSONDecodeError, FileNotFoundError) as e:
        print(f"Error loading cache file: {e}")
        sys.exit(1)

    # Find all matching package paths
    locations = [item["path"] for item in data if item.get("name") == target_name]

    if len(locations) > 1:
        print(f"\033[33mWarning: More than one location found for {target_name}\033[0m")

    # If no locations found, show an error
    if not locations:
        print(f"No package information found for {target_name}")
        sys.exit(0)

    for location in locations:
        print(location)

        # Try to use the environment variable if set
        fzf_preview_cmd = os.environ.get("FZF_PREVIEW_CMD")
        if fzf_preview_cmd:
            try:
                subprocess.run(f"{fzf_preview_cmd} '{location}'", shell=True)
            except subprocess.SubprocessError as e:
                print(f"Error previewing file: {e}")
        else:
            # Fallback preview if FZF_PREVIEW_CMD is not available
            try:
                if os.path.exists(location):
                    if location.endswith(".json"):
                        with open(location, "r") as f:
                            package_data = json.load(f)
                        print(json.dumps(package_data, indent=2))
                    else:
                        # Just display the first few lines of the file
                        with open(location, "r") as f:
                            lines = f.readlines()[:20]  # First 20 lines
                        print("".join(lines))
            except Exception as e:
                print(f"Error reading file: {e}")


if __name__ == "__main__":
    main()
