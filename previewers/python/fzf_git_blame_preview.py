#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil
import mimetypes


def run_git_blame(file_path: str, extension: str) -> None:
    """Run git blame on the specified file.

    Args:
        file_path: Path to the file to blame
        extension: File extension for syntax highlighting
    """
    fzf_diff_preview_cmd = os.environ.get("FZF_DIFF_PREVIEW_CMD")

    if fzf_diff_preview_cmd:
        try:
            blame_output = subprocess.check_output(
                ["git", "blame", file_path], text=True
            )
            subprocess.run(
                f"{fzf_diff_preview_cmd} --default-language {extension}",
                input=blame_output,
                shell=True,
                text=True,
            )
        except subprocess.SubprocessError:
            print(f"Error running git blame on {file_path}")
    else:
        subprocess.run(["git", "blame", "--abbrev=8", file_path])


def is_binary_or_image(file_path: str) -> bool:
    """Check if the file is binary or an image.

    Args:
        file_path: Path to the file to check

    Returns:
        True if the file is binary or an image, False otherwise
    """
    # Check if the file command is available
    file_cmd = shutil.which("file")
    if file_cmd:
        mime_check = subprocess.run(
            ["file", "--mime-type", file_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        mime_output = mime_check.stdout
        return "application/octet-stream" in mime_output or "image/" in mime_output
    else:
        # If file command is not available, try to use Python's mimetypes
        mime_type, _ = mimetypes.guess_type(file_path)
        if mime_type:
            return mime_type.startswith(
                "application/octet-stream"
            ) or mime_type.startswith("image/")
        return False


def main() -> None:
    """Main function that processes the input file."""
    if len(sys.argv) < 2:
        print("Error: File path not provided")
        sys.exit(1)

    file_path = sys.argv[1]
    extension = os.path.splitext(file_path)[1][1:]  # Get extension without the dot

    if is_binary_or_image(file_path):
        fzf_preview_cmd = os.environ.get("FZF_PREVIEW_CMD")
        if fzf_preview_cmd:
            subprocess.run([fzf_preview_cmd, file_path])
    else:
        run_git_blame(file_path, extension)


if __name__ == "__main__":
    main()
