#!/usr/bin/env python3

import json
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "caelestia" / "cliphist"
CACHE.mkdir(parents=True, exist_ok=True)

IMAGE_RE = re.compile(r"binary data\s+(.+?)\s+(gif|jpe?g|png|bmp|webp|tiff?)(?:\s+(\d+)x(\d+))?", re.I)


def decode(clip_id: int) -> bytes:
    return subprocess.check_output(["cliphist", "decode"], input=f"{clip_id}\t\n".encode())


def details(text: str) -> dict:
    value = text.strip()
    if re.fullmatch(r"#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?", value):
        return {"kind": "colour", "colour": value.lower()}
    if re.fullmatch(r"https?://\S+", value, re.I):
        return {"kind": "link", "colour": ""}
    code = re.search(r"(?:^|\s)(?:const |let |var |function |class |def |import |from \w+ import |SELECT |INSERT INTO |async |export |return |#!/|</?[A-Za-z][^>]*>)", value)
    if code or (value.startswith(("{", "[")) and any(c in value for c in (":", "\""))):
        return {"kind": "code", "colour": ""}
    return {"kind": "text", "colour": ""}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", nargs="?", choices=("list", "copy", "delete", "inspect"), default="list")
    parser.add_argument("clip_id", nargs="?", type=int)
    args = parser.parse_args()
    if args.action != "list":
        if args.clip_id is None or args.clip_id < 0:
            parser.error("a non-negative clipboard ID is required")
        if args.action == "inspect":
            text = decode(args.clip_id).decode("utf-8", errors="replace")
            print(json.dumps({"text": text[:32000], "truncated": len(text) > 32000, **details(text)}))
        elif args.action == "copy":
            # Decode first: a failed lookup must never overwrite the clipboard.
            data = decode(args.clip_id)
            subprocess.run(["wl-copy"], input=data, check=True)
        else:
            subprocess.run(["cliphist", "delete"], input=f"{args.clip_id}\t\n".encode(), check=True)
            for cached in CACHE.glob(f"{args.clip_id}.*"):
                if cached.is_file():
                    cached.unlink()
        return

    raw = subprocess.check_output(["cliphist", "-preview-width", "1000", "list"], text=True, errors="replace")
    items = []

    for line in raw.splitlines():
        if "\t" not in line:
            continue

        id_s, preview = line.split("\t", 1)
        try:
            clip_id = int(id_s)
        except ValueError:
            continue

        match = IMAGE_RE.search(preview)
        item = {
            "id": clip_id,
            "preview": preview,
            "image": False,
            "path": "",
            "title": "",
            "subtitle": "",
            "kind": "text",
            "colour": "",
        }

        if match:
            size, ext, width, height = match.groups()
            ext = "jpg" if ext.lower() == "jpeg" else ext.lower()
            path = CACHE / f"{clip_id}.{ext}"
            if not path.exists():
                try:
                    path.write_bytes(decode(clip_id))
                except subprocess.CalledProcessError:
                    continue

            dims = f"{width}×{height}" if width and height else ext.upper()
            item.update(
                image=True,
                kind="image",
                path=str(path),
                title="Image",
                subtitle=f"{size} · {ext.upper()} · {dims}",
            )
        else:
            text = " ".join(preview.split())
            item["title"] = text[:80] or "Clipboard item"
            item["subtitle"] = "Text" if len(text) <= 80 else text[80:160]
            item.update(details(preview))

        items.append(item)

    print(json.dumps(items))


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError):
        print("Clipboard operation failed. Check that cliphist and wl-clipboard are available.", file=sys.stderr)
        sys.exit(1)
