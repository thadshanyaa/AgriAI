from __future__ import annotations

import csv
import json
import random
from collections import Counter
from pathlib import Path

from PIL import Image


ROOT = Path(r"D:\Projects\AgriAI_Disease_Dataset_Clean_25Crops")
MANIFEST = ROOT / "reports" / "manifest.csv"
OUTPUT = ROOT / "reports" / "validation_report.json"
SAMPLE_SIZE = 1500
SEED = 20260817


def main() -> None:
    with MANIFEST.open("r", newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))

    output_paths = [row["output_path"] for row in rows]
    normalized_hashes = [row["normalized_pixel_sha256"] for row in rows]
    missing_files = [path for path in output_paths if not (ROOT / Path(path)).is_file()]
    duplicate_paths = len(output_paths) - len(set(output_paths))
    duplicate_pixel_hashes = len(normalized_hashes) - len(set(normalized_hashes))

    disk_files = {
        path.relative_to(ROOT).as_posix()
        for split in ("train", "validation", "test")
        for path in (ROOT / split).rglob("*.jpg")
    }
    manifest_files = set(output_paths)
    unlisted_files = sorted(disk_files - manifest_files)
    listed_but_missing = sorted(manifest_files - disk_files)

    rng = random.Random(SEED)
    samples = rows if len(rows) <= SAMPLE_SIZE else rng.sample(rows, SAMPLE_SIZE)
    image_errors: list[dict] = []
    for row in samples:
        path = ROOT / Path(row["output_path"])
        try:
            with Image.open(path) as image:
                if image.format != "JPEG" or image.mode != "RGB" or image.size != (320, 320):
                    image_errors.append(
                        {
                            "path": row["output_path"],
                            "format": image.format,
                            "mode": image.mode,
                            "size": list(image.size),
                        }
                    )
                image.verify()
        except Exception as exc:  # verification report should capture all image failures
            image_errors.append({"path": row["output_path"], "error": f"{type(exc).__name__}: {exc}"})

    split_counts = Counter(row["split"] for row in rows)
    crop_counts = Counter(row["crop"] for row in rows)
    class_counts = Counter(row["class_id"] for row in rows)
    classes_by_split: dict[str, int] = {}
    for split in ("train", "validation", "test"):
        classes_by_split[split] = len({row["class_id"] for row in rows if row["split"] == split})

    passed = not any(
        [
            missing_files,
            duplicate_paths,
            duplicate_pixel_hashes,
            unlisted_files,
            listed_but_missing,
            image_errors,
            len(crop_counts) != 25,
            len(class_counts) != 122,
            any(value != 122 for value in classes_by_split.values()),
        ]
    )
    report = {
        "passed": passed,
        "manifest_rows": len(rows),
        "disk_image_files": len(disk_files),
        "crop_count": len(crop_counts),
        "class_count": len(class_counts),
        "split_counts": dict(split_counts),
        "classes_by_split": classes_by_split,
        "duplicate_manifest_paths": duplicate_paths,
        "duplicate_normalized_pixel_hashes": duplicate_pixel_hashes,
        "missing_manifest_files": len(missing_files),
        "unlisted_disk_files": len(unlisted_files),
        "listed_but_missing": len(listed_but_missing),
        "sampled_images_verified": len(samples),
        "sample_image_errors": image_errors,
    }
    OUTPUT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
