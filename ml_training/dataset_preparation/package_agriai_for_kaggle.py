from __future__ import annotations

import time
import zipfile
from pathlib import Path


SOURCE = Path(r"D:\Projects\AgriAI_Disease_Dataset_Clean_25Crops")
OUTPUT = Path(r"D:\Projects\AgriAI_25Crop_Disease_Clean.zip")


def main() -> None:
    if OUTPUT.exists():
        OUTPUT.unlink()
    files = [path for path in SOURCE.rglob("*") if path.is_file()]
    started = time.monotonic()
    with zipfile.ZipFile(OUTPUT, "w", compression=zipfile.ZIP_STORED, allowZip64=True) as archive:
        for index, path in enumerate(files, start=1):
            archive.write(path, arcname=path.relative_to(SOURCE.parent).as_posix())
            if index % 10000 == 0:
                print(
                    f"Packed {index:,}/{len(files):,} files; "
                    f"size={OUTPUT.stat().st_size / (1024**3):.2f} GB; "
                    f"elapsed={time.monotonic() - started:.0f}s",
                    flush=True,
                )
    print(
        f"DONE: {OUTPUT} | files={len(files):,} | size={OUTPUT.stat().st_size / (1024**3):.2f} GB",
        flush=True,
    )


if __name__ == "__main__":
    main()
