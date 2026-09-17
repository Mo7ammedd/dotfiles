#!/usr/bin/env python3
"""Return cached representative image colours without changing the wallpaper."""

import hashlib
import json
import os
from pathlib import Path
import sys

from PIL import Image, ImageOps


def palette(path: Path) -> list[str]:
    stat = path.stat()
    identity = f"v1:{path.resolve()}:{stat.st_mtime_ns}:{stat.st_size}"
    cache_dir = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "caelestia" / "wallpaper-palettes"
    cache = cache_dir / (hashlib.sha256(identity.encode()).hexdigest() + ".json")
    try:
        colours = json.loads(cache.read_text())
        if isinstance(colours, list) and colours and all(isinstance(c, str) and len(c) == 7 and c.startswith("#") and all(v in "0123456789abcdef" for v in c[1:]) for c in colours):
            return colours[:5]
    except (OSError, ValueError):
        pass

    with Image.open(path) as source:
        source.draft("RGB", (128, 128))
        source.thumbnail((128, 128))
        rgb = ImageOps.exif_transpose(source).convert("RGB")
        quantized = rgb.quantize(colors=5, method=Image.Quantize.MEDIANCUT)
        table = quantized.getpalette()
        colours = [
            "#{:02x}{:02x}{:02x}".format(*table[index * 3:index * 3 + 3])
            for _, index in sorted(quantized.getcolors(), reverse=True)
        ]
        colours = list(dict.fromkeys(colours))

    try:
        cache_dir.mkdir(parents=True, exist_ok=True)
        temporary = cache.with_suffix(f".{os.getpid()}.tmp")
        temporary.write_text(json.dumps(colours))
        temporary.replace(cache)
    except OSError:
        pass  # A read-only cache must not prevent displaying the palette.
    return colours


if __name__ == "__main__":
    try:
        print(json.dumps(palette(Path(sys.argv[1]))))
    except (OSError, ValueError, IndexError, Image.DecompressionBombError):
        print("[]")
