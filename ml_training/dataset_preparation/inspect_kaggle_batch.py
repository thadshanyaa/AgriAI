from __future__ import annotations

import json
import re
import zipfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


ARCHIVES = [
    Path(r"C:\Users\omkal\Downloads\archive (12).zip"),
    Path(r"C:\Users\omkal\Downloads\archive (16).zip"),
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

IMAGE_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".bmp",
    ".gif",
    ".tif",
    ".tiff",
    ".webp",
    ".jfif",
}

IGNORED_CLASS_FOLDERS = {
    "archive",
    "data",
    "dataset",
    "datasets",
    "image",
    "images",
    "img",
    "imgs",
    "leaf",
    "leaves",
    "plant",
    "plants",
    "raw",
    "processed",
    "resized",
    "augmented",
    "augmentation",
    "original",
    "train",
    "training",
    "test",
    "testing",
    "valid",
    "validation",
    "val",
}


def human_bytes(value: int) -> str:
    size = float(value)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if size < 1024 or unit == "TB":
            return f"{size:.2f} {unit}"
        size /= 1024
    return f"{size:.2f} TB"


def normalize_part(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[_\-.]+", " ", value)
    value = re.sub(r"\s+", " ", value)
    return value


def candidate_class(parts: tuple[str, ...]) -> str:
    """Return the closest meaningful parent folder for an image."""
    for part in reversed(parts[:-1]):
        normalized = normalize_part(part)
        if normalized and normalized not in IGNORED_CLASS_FOLDERS:
            return part
    return "(unclassified)"


def inspect_archive(path: Path) -> dict:
    result: dict = {
        "archive": str(path),
        "exists": path.exists(),
        "compressed_bytes": path.stat().st_size if path.exists() else 0,
    }
    if not path.exists():
        result["error"] = "File not found"
        return result

    extension_counts: Counter[str] = Counter()
    top_level_counts: Counter[str] = Counter()
    parent_path_counts: Counter[str] = Counter()
    candidate_class_counts: Counter[str] = Counter()
    non_image_samples: list[str] = []
    total_files = 0
    image_files = 0
    uncompressed_bytes = 0
    compressed_member_bytes = 0

    try:
        with zipfile.ZipFile(path) as archive:
            for info in archive.infolist():
                if info.is_dir():
                    continue
                total_files += 1
                uncompressed_bytes += info.file_size
                compressed_member_bytes += info.compress_size

                member = info.filename.replace("\\", "/").strip("/")
                parts = tuple(part for part in member.split("/") if part)
                if not parts:
                    continue
                extension = Path(parts[-1]).suffix.lower() or "(no extension)"
                extension_counts[extension] += 1
                top_level_counts[parts[0]] += 1

                if extension in IMAGE_EXTENSIONS:
                    image_files += 1
                    parent_path = "/".join(parts[:-1]) or "(root)"
                    parent_path_counts[parent_path] += 1
                    candidate_class_counts[candidate_class(parts)] += 1
                elif len(non_image_samples) < 80:
                    non_image_samples.append(member)

            result.update(
                {
                    "zip_comment": archive.comment.decode("utf-8", errors="replace"),
                    "total_files": total_files,
                    "image_files": image_files,
                    "non_image_files": total_files - image_files,
                    "uncompressed_bytes": uncompressed_bytes,
                    "compressed_member_bytes": compressed_member_bytes,
                    "compression_ratio": (
                        round(uncompressed_bytes / compressed_member_bytes, 2)
                        if compressed_member_bytes
                        else None
                    ),
                    "extensions": dict(extension_counts.most_common()),
                    "top_level_entries": dict(top_level_counts.most_common(40)),
                    "candidate_classes": dict(candidate_class_counts.most_common()),
                    "image_parent_paths": dict(parent_path_counts.most_common(250)),
                    "non_image_samples": non_image_samples,
                }
            )
    except (zipfile.BadZipFile, OSError, RuntimeError) as exc:
        result["error"] = f"{type(exc).__name__}: {exc}"
    return result


def main() -> None:
    reports = []
    for archive_path in ARCHIVES:
        print(f"Scanning {archive_path.name} ...", flush=True)
        reports.append(inspect_archive(archive_path))

    totals = {
        "archive_count": len(reports),
        "compressed_bytes": sum(item.get("compressed_bytes", 0) for item in reports),
        "uncompressed_bytes": sum(item.get("uncompressed_bytes", 0) for item in reports),
        "total_files": sum(item.get("total_files", 0) for item in reports),
        "image_files": sum(item.get("image_files", 0) for item in reports),
        "archives_with_errors": sum(1 for item in reports if "error" in item),
    }
    payload = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "note": "Central-directory inventory only; image bytes were not extracted or modified.",
        "totals": totals,
        "archives": reports,
    }

    output_json = Path(r"D:\Projects\Kaggle_Batch_Inventory.json")
    output_json.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")

    lines = [
        "# Kaggle Disease Dataset Batch Inventory",
        "",
        "> ZIP central-directory scan only. Original downloads were not extracted or modified.",
        "",
        "## Batch totals",
        "",
        f"- Archives: {totals['archive_count']}",
        f"- ZIP size: {human_bytes(totals['compressed_bytes'])}",
        f"- Estimated extracted size: {human_bytes(totals['uncompressed_bytes'])}",
        f"- Files: {totals['total_files']:,}",
        f"- Images: {totals['image_files']:,}",
        f"- Archives with index/read errors: {totals['archives_with_errors']}",
        "",
        "## Archive summaries",
        "",
    ]
    for item in reports:
        path = Path(item["archive"])
        lines.extend(
            [
                f"### {path.name}",
                "",
                f"- ZIP: {human_bytes(item.get('compressed_bytes', 0))}",
                f"- Extracted estimate: {human_bytes(item.get('uncompressed_bytes', 0))}",
                f"- Files/images: {item.get('total_files', 0):,} / {item.get('image_files', 0):,}",
            ]
        )
        if "error" in item:
            lines.append(f"- Error: {item['error']}")
        else:
            lines.append("- Candidate classes:")
            for class_name, count in list(item.get("candidate_classes", {}).items())[:100]:
                lines.append(f"  - {class_name}: {count:,}")
            if len(item.get("candidate_classes", {})) > 100:
                lines.append("  - (More classes are available in the JSON report.)")
            lines.append("- Image parent paths (top 60):")
            for parent, count in list(item.get("image_parent_paths", {}).items())[:60]:
                lines.append(f"  - `{parent}`: {count:,}")
        lines.append("")

    output_markdown = Path(r"D:\Projects\Kaggle_Batch_Inventory.md")
    output_markdown.write_text("\n".join(lines), encoding="utf-8")

    print("", flush=True)
    print(f"Archives: {totals['archive_count']}", flush=True)
    print(f"ZIP size: {human_bytes(totals['compressed_bytes'])}", flush=True)
    print(f"Estimated extracted size: {human_bytes(totals['uncompressed_bytes'])}", flush=True)
    print(f"Images: {totals['image_files']:,}", flush=True)
    print(f"Errors: {totals['archives_with_errors']}", flush=True)
    print(f"JSON report: {output_json}", flush=True)
    print(f"Markdown report: {output_markdown}", flush=True)


if __name__ == "__main__":
    main()
