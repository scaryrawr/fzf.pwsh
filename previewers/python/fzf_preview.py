#!/usr/bin/env python3
"""
Python port of fzf_preview script for fzf.pwsh
"""

import os
import sys
import subprocess
import shutil
import mimetypes
from pathlib import Path

# Initialize mimetypes database
mimetypes.init()


def get_terminal_size():
    """Get terminal size from environment or use default"""
    columns = os.environ.get("FZF_PREVIEW_COLUMNS", "80")
    lines = os.environ.get("FZF_PREVIEW_LINES", "24")
    return f"{columns}x{lines}"


def preview_file(file_path: str):
    """Preview a regular file using bat or cat"""
    if shutil.which("bat"):
        subprocess.run(["bat", "--style=numbers", "--color=always", file_path])
    else:
        with open(file_path, "r", errors="replace") as f:
            print(f.read())


def preview_image(image_path: str):
    """Preview an image using chafa or just show file info"""
    if shutil.which("chafa"):
        size = get_terminal_size()
        subprocess.run(["chafa", "--size", size, image_path])
    else:
        file_info = Path(image_path).stat()
        print(f"Name: {Path(image_path).name}")
        print(f"Size: {file_info.st_size} bytes")
        print(f"Modified: {file_info.st_mtime}")


def is_image_file(file_path: str):
    """Check if a file is an image using multiple methods

    This function uses several methods to check if a file is an image:
    1. MIME type checking using mimetypes module
    2. External 'file' command if available
    3. File extension as a last resort
    """
    mime_type, _ = mimetypes.guess_type(file_path)
    if mime_type and mime_type.startswith("image/"):
        return True

    if shutil.which("file"):
        try:
            result = subprocess.run(
                ["file", "--mime-type", file_path], capture_output=True, text=True
            )
            return "image/" in result.stdout
        except Exception:
            pass

    image_extensions = [
        ".jpg",
        ".jpeg",
        ".png",
        ".gif",
        ".bmp",
        ".ico",
        ".tiff",
        ".webp",
        ".svg",
    ]
    return Path(file_path).suffix.lower() in image_extensions


def main():
    if len(sys.argv) < 2:
        print("No path provided for preview")
        sys.exit(1)

    path = sys.argv[1]

    if not Path(path).exists():
        print(f"Path not found: {path}")
        sys.exit(1)

    if Path(path).is_dir():
        # Directory preview
        if shutil.which("eza"):
            subprocess.run(["eza", "-l", "--color=always", path])
        elif shutil.which("exa"):
            subprocess.run(["exa", "-l", "--color=always", path])
        else:
            for item in Path(path).iterdir():
                print(item)
    else:
        # File preview
        if is_image_file(path):
            preview_image(path)
        else:
            preview_file(path)


if __name__ == "__main__":
    main()
