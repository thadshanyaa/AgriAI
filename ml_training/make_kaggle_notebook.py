from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
TRAINING_SCRIPT = ROOT / "train_agriai_kaggle.py"
OUTPUT_NOTEBOOK = ROOT / "AgriAI_25Crop_Disease_Training.ipynb"


def code_cell(source: str) -> dict:
    return {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": [line + "\n" for line in source.splitlines()],
    }


notebook = {
    "cells": [
        {
            "cell_type": "markdown",
            "metadata": {},
            "source": [
                "# AgriAI — 25-Crop Disease Identification Training\n",
                "\n",
                "MobileNetV3Large transfer learning for 122 crop/disease/health classes. "
                "Enable a Kaggle **T4 GPU** and **Internet** before running all cells.\n",
            ],
        },
        code_cell(
            """import os
os.environ[\"AGRIAI_IMAGE_SIZE\"] = \"224\"
os.environ[\"AGRIAI_BATCH_SIZE\"] = \"32\"
os.environ[\"AGRIAI_HEAD_EPOCHS\"] = \"5\"
os.environ[\"AGRIAI_FINE_TUNE_EPOCHS\"] = \"5\"
os.environ[\"AGRIAI_FINE_TUNE_LAYERS\"] = \"50\"
os.environ[\"AGRIAI_OUTPUT_ROOT\"] = \"/kaggle/working/agriai_training_output\"
print(\"Training configuration loaded.\")"""
        ),
        code_cell(TRAINING_SCRIPT.read_text(encoding="utf-8")),
        code_cell(
            """from pathlib import Path
output = Path('/kaggle/working/agriai_training_output')
for path in sorted(output.iterdir()):
    if path.is_file():
        print(f'{path.name}: {path.stat().st_size / (1024 * 1024):.2f} MB')"""
        ),
    ],
    "metadata": {
        "accelerator": "GPU",
        "kaggle": {"accelerator": "gpu"},
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {"name": "python", "version": "3.11"},
    },
    "nbformat": 4,
    "nbformat_minor": 5,
}

OUTPUT_NOTEBOOK.write_text(json.dumps(notebook, indent=1), encoding="utf-8")
print(f"Notebook: {OUTPUT_NOTEBOOK}")
