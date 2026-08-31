from __future__ import annotations

import csv
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(r"D:\Projects\AgriAI_Disease_Dataset_Clean_25Crops")
MANIFEST = ROOT / "reports" / "manifest.csv"
OUTPUT = ROOT / "reports" / "CROP_DISEASE_LIST.md"

DISPLAY_CROPS = {
    "rice": "Rice",
    "maize_corn": "Maize / Corn",
    "tomato": "Tomato",
    "potato": "Potato",
    "cucumber": "Cucumber",
    "pumpkin": "Pumpkin",
    "bean": "Bean",
    "apple": "Apple",
    "grapes": "Grapes",
    "guava": "Guava",
    "citrus_lemon": "Citrus / Lemon",
    "sugarcane": "Sugarcane",
    "groundnut": "Groundnut",
    "chilli": "Chilli",
    "brinjal": "Brinjal",
    "okra": "Okra",
    "cabbage": "Cabbage",
    "onion": "Onion",
    "banana": "Banana",
    "coconut": "Coconut",
    "papaya": "Papaya",
    "mango": "Mango",
    "pineapple": "Pineapple",
    "tea": "Tea",
    "coffee": "Coffee",
}


def display_condition(value: str) -> str:
    return value.replace("_", " ").title()


def main() -> None:
    with MANIFEST.open("r", newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))

    crop_images = Counter(row["crop"] for row in rows)
    class_images = Counter((row["crop"], row["condition"]) for row in rows)
    crop_conditions: dict[str, list[str]] = defaultdict(list)
    for crop, condition in sorted(class_images):
        crop_conditions[crop].append(condition)

    healthy_count = sum(1 for crop in crop_conditions if "healthy" in crop_conditions[crop])
    nonhealthy_count = sum(
        1 for conditions in crop_conditions.values() for condition in conditions if condition != "healthy"
    )
    total_classes = sum(len(conditions) for conditions in crop_conditions.values())

    lines = [
        "# AgriAI Final Crop and Disease Identification List",
        "",
        "## Final cleaned dataset",
        "",
        f"- Crops: {len(crop_conditions)}",
        f"- Total model output classes: {total_classes}",
        f"- Healthy classes: {healthy_count}",
        f"- Disease/pest/symptom classes: {nonhealthy_count}",
        f"- Images: {len(rows):,}",
        "",
        "| # | Crop | Images | Total classes | Non-healthy classes | Healthy available |",
        "|---:|---|---:|---:|---:|---|",
    ]
    for index, crop in enumerate(DISPLAY_CROPS, start=1):
        conditions = crop_conditions[crop]
        nonhealthy = sum(1 for condition in conditions if condition != "healthy")
        lines.append(
            f"| {index} | {DISPLAY_CROPS[crop]} | {crop_images[crop]:,} | {len(conditions)} | "
            f"{nonhealthy} | {'Yes' if 'healthy' in conditions else 'No'} |"
        )

    lines.extend(["", "## Detailed classes", ""])
    for crop in DISPLAY_CROPS:
        lines.append(f"### {DISPLAY_CROPS[crop]}")
        lines.append("")
        for condition in crop_conditions[crop]:
            label_type = "Healthy" if condition == "healthy" else "Disease/pest/symptom"
            lines.append(
                f"- `{crop}___{condition}` — {display_condition(condition)} — "
                f"{class_images[(crop, condition)]:,} images — {label_type}"
            )
        lines.append("")

    lines.extend(
        [
            "## Dataset limitations to state in the report",
            "",
            "- Okra has a generic `diseased_leaf_unspecified` label rather than a named disease.",
            "- Coconut WCLWD labels include symptom stages; they are not necessarily separate diseases.",
            "- Coffee has rust and leaf-miner classes but no healthy class.",
            "- Papaya has relatively few source images, especially bacterial blight; apply augmentation to the training split only.",
            "- Tea retains the source label `gray_light`; verify whether the source intended `gray blight` before changing the scientific label.",
            "",
        ]
    )

    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Report: {OUTPUT}")


if __name__ == "__main__":
    main()
