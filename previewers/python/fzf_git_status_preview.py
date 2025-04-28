#!/usr/bin/env python3
"""
Python port of fzf_git_status_preview script for fzf.pwsh
"""

import os
import sys
import subprocess
import shutil


def main():
    if len(sys.argv) < 2:
        print("Usage: fzf_git_status_preview.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]

    # Get the git status of the file
    git_status = subprocess.run(
        ["git", "status", "-s", "--", file_path], capture_output=True, text=True
    ).stdout

    # If file is untracked, show its contents
    if git_status.startswith("?? "):
        if shutil.which("bat"):
            subprocess.run(["bat", "--style=numbers", "--color=always", file_path])
        else:
            try:
                with open(file_path, "r", errors="replace") as f:
                    print(f.read())
            except Exception as e:
                print(f"Error reading file: {e}")
    else:
        # Show the diff
        diff_cmd = os.environ.get("FZF_DIFF_PREVIEW_CMD")
        git_diff = subprocess.run(
            ["git", "diff", "--color=always", "--", file_path],
            capture_output=True,
            text=True,
        ).stdout

        if diff_cmd:
            # Use the custom diff viewer command
            try:
                process = subprocess.Popen(
                    diff_cmd, shell=True, stdin=subprocess.PIPE, text=True
                )
                process.communicate(input=git_diff)
            except Exception:
                # Fallback to just printing the diff
                print(git_diff)
        else:
            print(git_diff)


if __name__ == "__main__":
    main()
