from __future__ import annotations

import json
from pathlib import Path


INVENTORY_PATH = Path(r"D:\Projects\Kaggle_Batch_Inventory.json")
OUTPUT_PATH = Path(r"D:\Projects\AgriAI_25_Crop_Coverage.md")


def archive_name(value: str) -> str:
    return Path(value).name


def class_map(archives: dict[str, dict], archive: str) -> dict[str, int]:
    return {
        str(key): int(value)
        for key, value in archives[archive].get("candidate_classes", {}).items()
    }


def selected(classes: dict[str, int], names: list[str]) -> dict[str, int]:
    return {name: classes[name] for name in names if name in classes}


def selected_prefix(classes: dict[str, int], prefixes: tuple[str, ...]) -> dict[str, int]:
    return {
        name: count
        for name, count in classes.items()
        if name.lower().startswith(tuple(prefix.lower() for prefix in prefixes))
    }


def main() -> None:
    payload = json.loads(INVENTORY_PATH.read_text(encoding="utf-8"))
    archives = {archive_name(item["archive"]): item for item in payload["archives"]}
    classes = {name: class_map(archives, name) for name in archives}

    master = classes["archive (12).zip"]
    multi = classes["archive (20).zip"]

    rows: list[dict] = []

    def add(crop: str, archive: str, picked: dict[str, int], note: str = "") -> None:
        rows.append(
            {
                "crop": crop,
                "status": "Ready" if picked else "Missing",
                "archive": archive if picked else "—",
                "classes": picked,
                "images": sum(picked.values()),
                "note": note,
            }
        )

    add("Rice", "archive (20).zip", selected_prefix(multi, ("Rice___",)), "Uses named disease classes instead of the master dataset's generic diseased/healthy labels.")
    add("Maize / Corn", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("corn_") or name == "healthy_corn"})
    add("Tomato", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("tomato_") or name == "healthy_tomato"})
    add("Potato", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("potato_") or name == "healthy_potato"})
    add("Cucumber", "archive (20).zip", selected_prefix(multi, ("Cucumber___",)), "Uses named disease classes instead of generic diseased/healthy labels.")
    add("Pumpkin", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("pumpkin_") or name == "healthy_pumpkin"})
    add("Bean", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("bean_") or name == "healthy_bean"})
    add("Apple", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("apple_") or name == "healthy_apple"})
    add("Grapes", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("grape_") or name == "healthy_grape"})
    add("Guava", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("guava_") or name == "healthy_guava"})
    add("Citrus / Lemon", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("lemon_") or name == "healthy_lemon"})
    add("Sugarcane", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("sugarcane_") or name == "healthy_sugarcane"})
    add("Groundnut", "archive (12).zip", {name: count for name, count in master.items() if name.startswith("groundnut_") or name == "healthy_groundnut"})
    add("Chilli", "archive (20).zip", selected_prefix(multi, ("Chili__",)), "archive (16) is Bell Pepper, not Chilli.")
    add("Brinjal", "archive (17).zip", selected(classes["archive (17).zip"], ["Fresh Brinjal Leaf", "Diseased Brinjal Leaf - Cercospora Leaf Spot"]))
    add("Okra", "archive (18).zip", classes["archive (18).zip"], "Only healthy vs diseased labels are present in the folders.")
    add("Cabbage", "archive (19).zip", classes["archive (19).zip"], "Balanced dataset; all classes contain 200 images.")
    add("Onion", "archive (20).zip", selected_prefix(multi, ("Onion___",)))

    banana_original_names = [name for name in classes["archive (21).zip"] if not name.startswith("Augmented ")]
    add("Banana", "archive (21).zip", selected(classes["archive (21).zip"], banana_original_names), "Original images only. Excludes 2,856 pre-augmented images to reduce train/test leakage.")

    add("Coconut", "archive (22).zip", classes["archive (22).zip"])
    add("Papaya", "archive (27).zip", classes["archive (27).zip"], "Only 135 images; use careful augmentation and stratified evaluation.")
    add("Mango", "archive (26).zip", classes["archive (26).zip"], "Balanced dataset with 500 images per class.")

    pineapple_counts = {
        "Pineapple__leaf_blight": 608,
        "Pineapple_fusarium": 590,
        "Pineapple_healthy": 576,
        "Pineapple_mealybug_wilt": 539,
    }
    add("Pineapple", "archive (23).zip", pineapple_counts, "Original folder only. Excludes duplicate preprocessed/augmented folder sets.")
    add("Tea", "archive (24).zip", classes["archive (24).zip"])
    add("Coffee", "archive (25).zip", classes["archive (25).zip"], "Rust and leaf-miner images with matching XML annotations; no healthy class.")

    ready = [row for row in rows if row["status"] == "Ready"]
    missing = [row for row in rows if row["status"] == "Missing"]
    selected_images = sum(row["images"] for row in ready)
    selected_classes = sum(len(row["classes"]) for row in ready)

    lines = [
        "# AgriAI 25-Crop Dataset Coverage",
        "",
        "> Inventory and selection plan. Original ZIP files were not modified.",
        "",
        "## Result",
        "",
        f"- Target crops: {len(rows)}",
        f"- Ready crops: {len(ready)}",
        f"- Missing crops: {len(missing)}" + (f" ({', '.join(row['crop'] for row in missing)})" if missing else ""),
        f"- Selected images before exact/corrupt duplicate cleaning: {selected_images:,}",
        f"- Selected crop-disease/health classes: {selected_classes}",
        "",
        "## Crop coverage",
        "",
        "| # | Crop | Status | Selected source | Images | Classes | Note |",
        "|---:|---|---|---|---:|---:|---|",
    ]
    for index, row in enumerate(rows, start=1):
        lines.append(
            f"| {index} | {row['crop']} | {row['status']} | {row['archive']} | "
            f"{row['images']:,} | {len(row['classes'])} | {row['note']} |"
        )

    lines.extend(["", "## Selected class list", ""])
    for row in rows:
        lines.append(f"### {row['crop']} — {row['status']}")
        lines.append("")
        if not row["classes"]:
            lines.append(f"- {row['note']}")
        else:
            for name, count in row["classes"].items():
                lines.append(f"- `{name}` — {count:,} images")
        lines.append("")

    lines.extend(
        [
            "## Important cleaning rules",
            "",
            "- Do not use `archive (16).zip` for Chilli; it contains Bell Pepper only.",
            "- From `archive (17).zip`, select Brinjal only; its Tomato and Bell Pepper images overlap other sources.",
            "- From `archive (20).zip`, select Rice, Cucumber, Chilli, and Onion only; ignore the other overlapping crops.",
            "- From `archive (21).zip`, preserve originals and generate augmentation only during model training.",
            "- From `archive (23).zip`, use the original dataset folder only; do not mix original, preprocessed, and augmented copies.",
            "- Remove exact SHA-256 duplicates before splitting, validate every image, and perform the train/validation/test split only after cleaning.",
            "- Normalize labels but retain `source_archive`, `original_path`, and `original_label` in a CSV manifest.",
            "",
        ]
    )

    OUTPUT_PATH.write_text("\n".join(lines), encoding="utf-8")
    print(f"Ready: {len(ready)}/25 crops")
    print(f"Missing: {', '.join(row['crop'] for row in missing) if missing else 'None'}")
    print(f"Selected before cleaning: {selected_images:,} images / {selected_classes} classes")
    print(f"Report: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
