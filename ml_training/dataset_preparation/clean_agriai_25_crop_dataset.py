from __future__ import annotations

import csv
import hashlib
import io
import json
import random
import re
import shutil
import time
import zipfile
from collections import Counter, defaultdict
from pathlib import Path, PurePosixPath

from PIL import Image, ImageOps, UnidentifiedImageError


OUTPUT_ROOT = Path(r"D:\Projects\AgriAI_Disease_Dataset_Clean_25Crops")
STAGING_ROOT = OUTPUT_ROOT / "_unique"
IMAGE_SIZE = (320, 320)
RANDOM_SEED = 42

ARCHIVES = [
    Path(r"C:\Users\omkal\Downloads\archive (12).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (17).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (18).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (19).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (20).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (21).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (22).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (23).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (24).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (25).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (26).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (27).zip"),
]

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp", ".jfif"}

MASTER_CROPS = {
    "apple": "apple",
    "bean": "bean",
    "corn": "maize_corn",
    "grape": "grapes",
    "groundnut": "groundnut",
    "guava": "guava",
    "lemon": "citrus_lemon",
    "potato": "potato",
    "pumpkin": "pumpkin",
    "sugarcane": "sugarcane",
    "tomato": "tomato",
}

EXPECTED_CROPS = [
    "rice",
    "maize_corn",
    "tomato",
    "potato",
    "cucumber",
    "pumpkin",
    "bean",
    "apple",
    "grapes",
    "guava",
    "citrus_lemon",
    "sugarcane",
    "groundnut",
    "chilli",
    "brinjal",
    "okra",
    "cabbage",
    "onion",
    "banana",
    "coconut",
    "papaya",
    "mango",
    "pineapple",
    "tea",
    "coffee",
]


def slug(value: str) -> str:
    value = value.strip().lower()
    value = value.replace("&", " and ")
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return re.sub(r"_+", "_", value).strip("_")


def class_id(crop: str, condition: str) -> str:
    return f"{slug(crop)}___{slug(condition)}"


def selected_label(archive_name: str, member_name: str) -> tuple[str, str, str] | None:
    """Return crop, condition, original class label, or None if excluded."""
    parts = tuple(part for part in member_name.replace("\\", "/").strip("/").split("/") if part)
    if not parts or Path(parts[-1]).suffix.lower() not in IMAGE_EXTENSIONS:
        return None
    parent = parts[-2] if len(parts) >= 2 else ""

    if archive_name == "archive (12).zip":
        original = parent
        lower = original.lower()
        master_crop = None
        for prefix in MASTER_CROPS:
            if lower.startswith(f"{prefix}_") or lower == f"healthy_{prefix}":
                master_crop = prefix
                break
        if master_crop is None:
            return None
        crop = MASTER_CROPS[master_crop]
        if lower == f"healthy_{master_crop}":
            condition = "healthy"
        else:
            condition = lower[len(master_crop) + 1 :]
            if master_crop == "apple" and condition == "apple_scab":
                condition = "scab"
        return crop, condition, original

    if archive_name == "archive (20).zip":
        allowed = {
            "rice": "rice",
            "cucumber": "cucumber",
            "chili": "chilli",
            "onion": "onion",
        }
        lower = parent.lower()
        for source_crop, crop in allowed.items():
            if lower.startswith(source_crop + "__"):
                condition = re.sub(r"^_+", "", parent[len(source_crop) :], flags=re.IGNORECASE)
                condition = "healthy" if "healthy" in condition.lower() else condition
                return crop, condition, parent
        return None

    if archive_name == "archive (17).zip":
        if "Brinjal" not in parts:
            return None
        condition = "healthy" if parent == "Fresh Brinjal Leaf" else "cercospora_leaf_spot"
        return "brinjal", condition, parent

    if archive_name == "archive (18).zip":
        condition = "healthy" if "fresh" in parent.lower() else "diseased_leaf_unspecified"
        return "okra", condition, parent

    if archive_name == "archive (19).zip":
        condition = "healthy" if parent.lower() == "no disease" else parent
        return "cabbage", condition, parent

    if archive_name == "archive (21).zip":
        normalized_path = "/".join(parts)
        if "/Original Images/Original Images/" not in f"/{normalized_path}":
            return None
        mapping = {
            "Banana Healthy Leaf": "healthy",
            "Banana Insect Pest Disease": "insect_pest",
            "Banana Black Sigatoka Disease": "black_sigatoka",
            "Banana Moko Disease": "moko_disease",
            "Banana Bract Mosaic Virus Disease": "bract_mosaic_virus",
            "Banana Panama Disease": "panama_disease",
            "Banana Yellow Sigatoka Disease": "yellow_sigatoka",
        }
        return "banana", mapping.get(parent, parent), parent

    if archive_name == "archive (22).zip":
        mapping = {
            "Healthy_Leaves": "healthy",
            "WCLWD_Yellowing": "wclwd_yellowing",
            "WCLWD_DryingofLeaflets": "wclwd_drying_of_leaflets",
            "WCLWD_Flaccidity": "wclwd_flaccidity",
            "CCI_Caterpillars": "cci_caterpillars",
            "CCI_Leaflets": "cci_leaflets",
        }
        return "coconut", mapping.get(parent, parent), parent

    if archive_name == "archive (23).zip":
        normalized_path = "/".join(parts)
        if "/Pineapple-orginal dataset/" not in f"/{normalized_path}":
            return None
        condition = re.sub(r"^pineapple_+", "", parent, flags=re.IGNORECASE)
        return "pineapple", condition, parent

    if archive_name == "archive (24).zip":
        condition = "healthy" if parent.lower() == "healthy" else parent
        return "tea", condition, parent

    if archive_name == "archive (25).zip":
        mapping = {"rust_xml_image": "rust", "miner_img_xml": "leaf_miner"}
        if parent not in mapping:
            return None
        return "coffee", mapping[parent], parent

    if archive_name == "archive (26).zip":
        condition = "healthy" if parent.lower() == "healthy" else parent
        return "mango", condition, parent

    if archive_name == "archive (27).zip":
        if "papaya main dataset" not in "/".join(parts).lower():
            return None
        mapping = {
            "healthy_leaf": "healthy",
            "Carica_Insect_Hole": "insect_hole",
            "Yellow_Necrotic_Spots_Holes": "yellow_necrotic_spots_holes",
            "Bacterial_Blight": "bacterial_blight",
        }
        return "papaya", mapping.get(parent, parent), parent

    return None


def resize_rgb(image: Image.Image) -> Image.Image:
    # JPEG draft decoding lets libjpeg decode near the requested size instead
    # of expanding very large source photos to their full resolution first.
    try:
        image.draft("RGB", (640, 640))
    except (AttributeError, OSError):
        pass
    image = ImageOps.exif_transpose(image).convert("RGB")
    source_width, source_height = image.size
    target_width, target_height = IMAGE_SIZE
    source_ratio = source_width / source_height
    target_ratio = target_width / target_height
    if source_ratio > target_ratio:
        crop_width = source_height * target_ratio
        left = (source_width - crop_width) / 2
        crop_box = (left, 0, left + crop_width, source_height)
    else:
        crop_height = source_width / target_ratio
        top = (source_height - crop_height) / 2
        crop_box = (0, top, source_width, top + crop_height)
    return image.resize(
        IMAGE_SIZE,
        resample=Image.Resampling.LANCZOS,
        box=crop_box,
        reducing_gap=3.0,
    )


def safe_split_counts(count: int) -> tuple[int, int, int]:
    if count < 3:
        return count, 0, 0
    validation = max(1, round(count * 0.10))
    test = max(1, round(count * 0.10))
    train = count - validation - test
    if train < 1:
        train = 1
        if validation > test:
            validation -= 1
        else:
            test -= 1
    return train, validation, test


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    start = time.monotonic()
    if OUTPUT_ROOT.exists():
        raise SystemExit(
            f"Output already exists: {OUTPUT_ROOT}. Move or rename it before rerunning to avoid overwriting data."
        )
    OUTPUT_ROOT.mkdir(parents=True)
    STAGING_ROOT.mkdir()

    raw_hash_seen: dict[str, str] = {}
    pixel_hash_seen: dict[str, str] = {}
    records: list[dict] = []
    duplicates: list[dict] = []
    corrupt: list[dict] = []
    selected_seen = 0
    source_selected = Counter()

    for archive_path in ARCHIVES:
        archive_name = archive_path.name
        print(f"Opening {archive_name} ...", flush=True)
        with zipfile.ZipFile(archive_path) as archive:
            for info in archive.infolist():
                if info.is_dir():
                    continue
                label = selected_label(archive_name, info.filename)
                if label is None:
                    continue
                selected_seen += 1
                source_selected[archive_name] += 1
                crop, condition, original_label = label
                target_class = class_id(crop, condition)

                try:
                    raw = archive.read(info)
                except (OSError, RuntimeError, zipfile.BadZipFile) as exc:
                    corrupt.append(
                        {
                            "source_archive": archive_name,
                            "original_path": info.filename,
                            "error": f"read_error: {type(exc).__name__}: {exc}",
                        }
                    )
                    continue

                raw_hash = hashlib.sha256(raw).hexdigest()
                if raw_hash in raw_hash_seen:
                    duplicates.append(
                        {
                            "reason": "exact_file_sha256",
                            "source_archive": archive_name,
                            "original_path": info.filename,
                            "class_id": target_class,
                            "duplicate_of": raw_hash_seen[raw_hash],
                        }
                    )
                    continue

                try:
                    with Image.open(io.BytesIO(raw)) as opened:
                        original_width, original_height = opened.size
                        original_format = opened.format or "unknown"
                        normalized = resize_rgb(opened)
                        normalized.load()
                except (UnidentifiedImageError, OSError, ValueError, SyntaxError) as exc:
                    corrupt.append(
                        {
                            "source_archive": archive_name,
                            "original_path": info.filename,
                            "error": f"image_error: {type(exc).__name__}: {exc}",
                        }
                    )
                    continue

                pixel_hash = hashlib.sha256(normalized.tobytes()).hexdigest()
                if pixel_hash in pixel_hash_seen:
                    duplicates.append(
                        {
                            "reason": "identical_normalized_pixels",
                            "source_archive": archive_name,
                            "original_path": info.filename,
                            "class_id": target_class,
                            "duplicate_of": pixel_hash_seen[pixel_hash],
                        }
                    )
                    raw_hash_seen[raw_hash] = pixel_hash_seen[pixel_hash]
                    continue

                class_dir = STAGING_ROOT / target_class
                class_dir.mkdir(exist_ok=True)
                output_name = f"{target_class}_{pixel_hash[:20]}.jpg"
                relative_staging = Path("_unique") / target_class / output_name
                output_path = OUTPUT_ROOT / relative_staging
                normalized.save(output_path, format="JPEG", quality=88, subsampling="4:2:0")

                record_key = f"{archive_name}:{info.filename}"
                raw_hash_seen[raw_hash] = record_key
                pixel_hash_seen[pixel_hash] = record_key
                records.append(
                    {
                        "crop": slug(crop),
                        "condition": slug(condition),
                        "class_id": target_class,
                        "split": "",
                        "output_path": relative_staging.as_posix(),
                        "source_archive": archive_name,
                        "original_path": info.filename,
                        "original_label": original_label,
                        "original_sha256": raw_hash,
                        "normalized_pixel_sha256": pixel_hash,
                        "original_width": original_width,
                        "original_height": original_height,
                        "original_format": original_format,
                    }
                )

                if selected_seen % 2000 == 0:
                    elapsed = time.monotonic() - start
                    print(
                        f"  selected={selected_seen:,} kept={len(records):,} "
                        f"duplicates={len(duplicates):,} corrupt={len(corrupt):,} elapsed={elapsed:.0f}s",
                        flush=True,
                    )

    print("Creating deterministic stratified train/val/test split ...", flush=True)
    grouped: dict[str, list[dict]] = defaultdict(list)
    for record in records:
        grouped[record["class_id"]].append(record)

    rng = random.Random(RANDOM_SEED)
    split_counts = Counter()
    for target_class in sorted(grouped):
        items = grouped[target_class]
        rng.shuffle(items)
        train_count, validation_count, test_count = safe_split_counts(len(items))
        boundaries = (
            ("train", 0, train_count),
            ("validation", train_count, train_count + validation_count),
            ("test", train_count + validation_count, train_count + validation_count + test_count),
        )
        for split, begin, end in boundaries:
            destination_dir = OUTPUT_ROOT / split / target_class
            destination_dir.mkdir(parents=True, exist_ok=True)
            for record in items[begin:end]:
                source = OUTPUT_ROOT / Path(record["output_path"])
                destination = destination_dir / source.name
                shutil.move(str(source), str(destination))
                record["split"] = split
                record["output_path"] = destination.relative_to(OUTPUT_ROOT).as_posix()
                split_counts[split] += 1

    shutil.rmtree(STAGING_ROOT)

    crop_counts = Counter(record["crop"] for record in records)
    class_counts = Counter(record["class_id"] for record in records)
    healthy_classes = [name for name in class_counts if name.endswith("___healthy")]
    nonhealthy_classes = [name for name in class_counts if not name.endswith("___healthy")]
    crop_set = sorted(crop_counts)

    manifest_fields = [
        "crop",
        "condition",
        "class_id",
        "split",
        "output_path",
        "source_archive",
        "original_path",
        "original_label",
        "original_sha256",
        "normalized_pixel_sha256",
        "original_width",
        "original_height",
        "original_format",
    ]
    write_csv(OUTPUT_ROOT / "reports" / "manifest.csv", records, manifest_fields)
    write_csv(
        OUTPUT_ROOT / "reports" / "removed_duplicates.csv",
        duplicates,
        ["reason", "source_archive", "original_path", "class_id", "duplicate_of"],
    )
    write_csv(
        OUTPUT_ROOT / "reports" / "corrupt_or_unreadable.csv",
        corrupt,
        ["source_archive", "original_path", "error"],
    )

    stats = {
        "image_size": list(IMAGE_SIZE),
        "random_seed": RANDOM_SEED,
        "selected_images_scanned": selected_seen,
        "kept_images": len(records),
        "removed_duplicates": len(duplicates),
        "corrupt_or_unreadable": len(corrupt),
        "crop_count": len(crop_set),
        "class_count": len(class_counts),
        "healthy_class_count": len(healthy_classes),
        "nonhealthy_class_count": len(nonhealthy_classes),
        "split_counts": dict(split_counts),
        "source_selected_counts": dict(source_selected),
        "crop_counts": dict(sorted(crop_counts.items())),
        "class_counts": dict(sorted(class_counts.items())),
        "crops": crop_set,
        "expected_crops": EXPECTED_CROPS,
        "missing_expected_crops": sorted(set(EXPECTED_CROPS) - set(crop_set)),
        "elapsed_seconds": round(time.monotonic() - start, 2),
    }
    (OUTPUT_ROOT / "reports" / "cleaning_report.json").write_text(
        json.dumps(stats, indent=2), encoding="utf-8"
    )
    (OUTPUT_ROOT / "reports" / "labels.json").write_text(
        json.dumps(sorted(class_counts), indent=2), encoding="utf-8"
    )

    readme = f"""# AgriAI Clean 25-Crop Disease Dataset

This dataset was created from the supplied Kaggle ZIP archives without modifying the originals.

## Summary

- Crops: {len(crop_set)}
- Model output classes: {len(class_counts)}
- Healthy classes: {len(healthy_classes)}
- Disease/pest/symptom classes: {len(nonhealthy_classes)}
- Selected images scanned: {selected_seen:,}
- Images kept: {len(records):,}
- Exact duplicates removed: {len(duplicates):,}
- Corrupt/unreadable images removed: {len(corrupt):,}
- Train/validation/test: {split_counts['train']:,} / {split_counts['validation']:,} / {split_counts['test']:,}
- Image format: RGB JPEG, 320 x 320
- Split seed: {RANDOM_SEED}

See `reports/manifest.csv` for complete provenance and `reports/cleaning_report.json` for counts.
"""
    (OUTPUT_ROOT / "README.md").write_text(readme, encoding="utf-8")

    print("", flush=True)
    print(f"DONE: {OUTPUT_ROOT}", flush=True)
    print(f"Crops/classes: {len(crop_set)}/{len(class_counts)}", flush=True)
    print(f"Kept: {len(records):,}", flush=True)
    print(f"Duplicates removed: {len(duplicates):,}", flush=True)
    print(f"Corrupt removed: {len(corrupt):,}", flush=True)
    print(f"Splits: {dict(split_counts)}", flush=True)
    print(f"Missing expected crops: {stats['missing_expected_crops']}", flush=True)


if __name__ == "__main__":
    main()
