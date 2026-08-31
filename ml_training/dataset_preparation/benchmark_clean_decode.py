from __future__ import annotations

import io
import time
import zipfile
from pathlib import Path

from PIL import Image

from clean_agriai_25_crop_dataset import resize_rgb, selected_label


path = Path(r"C:\Users\omkal\Downloads\archive (20).zip")
samples = 20
processed = 0
started = time.monotonic()
with zipfile.ZipFile(path) as archive:
    for info in archive.infolist():
        if selected_label(path.name, info.filename) is None:
            continue
        raw = archive.read(info)
        with Image.open(io.BytesIO(raw)) as image:
            normalized = resize_rgb(image)
            normalized.load()
        processed += 1
        if processed >= samples:
            break

elapsed = time.monotonic() - started
print(f"Processed {processed} selected archive-20 images in {elapsed:.2f}s ({elapsed/processed:.3f}s/image)")
