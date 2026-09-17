#!/usr/bin/env python3
"""Cache still previews for the wallpaper picker, including video first frames."""

import argparse
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.parse import quote

from PIL import Image, ImageOps, PngImagePlugin

SIZES = {"normal": 128, "large": 256, "x-large": 512, "xx-large": 1024}
IMAGES = {".jpg", ".jpeg", ".png", ".webp", ".avif", ".bmp", ".svg", ".gif", ".tif", ".tiff"}
VIDEOS = {".mp4", ".webm", ".mkv", ".avi", ".mov"}


def thumbnail(path, cache, size):
    # Match ThumbnailImage.qml's encodeURIComponent URI without resolving symlinks.
    uri = "file://" + quote(str(path.absolute()), safe="/!'()*")
    mtime = str(int(path.stat().st_mtime))
    target = cache / (hashlib.md5(uri.encode()).hexdigest() + ".png")
    if target.is_file():
        try:
            with Image.open(target) as existing:
                if existing.info.get("Thumb::URI") == uri and existing.info.get("Thumb::MTime") == mtime:
                    return
        except (OSError, ValueError):
            pass

    descriptor, name = tempfile.mkstemp(prefix=".wallpaper-", suffix=".png", dir=cache)
    os.close(descriptor)
    temporary = Path(name)
    try:
        if path.suffix.lower() in VIDEOS:
            subprocess.run([
                "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                "-i", str(path), "-frames:v", "1", "-vf",
                f"scale={size}:{size}:force_original_aspect_ratio=decrease",
                "-threads", "1", str(temporary),
            ], check=True, capture_output=True, timeout=25)
            source = temporary
        else:
            source = path

        try:
            with Image.open(source) as original:
                preview = ImageOps.exif_transpose(original).convert("RGBA")
        except (OSError, ValueError):
            if path.suffix.lower() in VIDEOS:
                raise
            subprocess.run([
                "magick", str(path) + "[0]", "-auto-orient", "-thumbnail",
                f"{size}x{size}>", str(temporary),
            ], check=True, capture_output=True, timeout=25)
            with Image.open(temporary) as original:
                preview = original.convert("RGBA")

        preview.thumbnail((size, size), Image.Resampling.LANCZOS)
        metadata = PngImagePlugin.PngInfo()
        metadata.add_text("Thumb::URI", uri)
        metadata.add_text("Thumb::MTime", mtime)
        metadata.add_text("Software", "Quickshell wallpaper picker")
        preview.save(temporary, pnginfo=metadata)
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("--size", choices=SIZES, default="x-large")
    args = parser.parse_args()
    if not args.directory.is_dir():
        parser.error("Wallpaper directory does not exist")
    cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "thumbnails" / args.size
    cache.mkdir(parents=True, exist_ok=True)
    files = sorted(path.absolute() for path in args.directory.iterdir()
                   if path.is_file() and path.suffix.lower() in IMAGES | VIDEOS)
    for index, path in enumerate(files, 1):
        try:
            thumbnail(path, cache, SIZES[args.size])
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"Could not preview {path.name}: {error}", file=sys.stderr)
        print(f"PROGRESS {index}/{len(files)} FILE {path}", flush=True)


if __name__ == "__main__":
    main()
