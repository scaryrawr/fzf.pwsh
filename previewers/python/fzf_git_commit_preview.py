#!/usr/bin/env python3
"""
Python port of fzf_git_commit_preview script for fzf.pwsh
"""

import os
import sys
import subprocess
import re


def main():
    if len(sys.argv) < 2:
        print("Usage: fzf_git_commit_preview.py <commit_hash>")
        sys.exit(1)

    commit = sys.argv[1]
    hash_match = re.search(r"^([a-f0-9]+)", commit)
    if hash_match:
        commit = hash_match.group(1)

    diff_cmd = os.environ.get("FZF_DIFF_PREVIEW_CMD")
    git_diff = subprocess.run(
        ["git", "show", "--color=always", commit], capture_output=True, text=True
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


if __name__ == "__main__":
    main()
