# AgriAI datasets: inventory and acquisition notes

## What is included

The repository contains dataset preparation scripts, crop/class lists and
historical cleaning/validation summary reports. It does **not** contain the raw
image datasets, ZIP/TAR archives, full per-image manifest or training checkpoints.
No Git LFS or paid dataset storage has been configured.

## Original Kaggle source links: verification pending

The available local inventory identifies the supplied downloads by ZIP filename,
but it does not record exact Kaggle owner/dataset URLs, versions or licenses.
The checked download metadata also did not provide those dataset URLs. No
guessed dataset links have been substituted. A matching crop name alone does
not establish that another Kaggle dataset is the one used here.

Use the original download records to confirm each source below. Record its
canonical URL, owner, version/date and license before redistributing images or
claiming that another person can reproduce the exact dataset from this repository.

| Supplied archive | Selected crops | Exact source URL / license |
|---|---|---|
| `archive (12).zip` | Maize/Corn, Tomato, Potato, Pumpkin, Bean, Apple, Grapes, Guava, Citrus/Lemon, Sugarcane, Groundnut | Pending verification |
| `archive (17).zip` | Brinjal | Pending verification |
| `archive (18).zip` | Okra | Pending verification |
| `archive (19).zip` | Cabbage | Pending verification |
| `archive (20).zip` | Rice, Cucumber, Chilli, Onion | Pending verification |
| `archive (21).zip` | Banana | Pending verification |
| `archive (22).zip` | Coconut | Pending verification |
| `archive (23).zip` | Pineapple | Pending verification |
| `archive (24).zip` | Tea | Pending verification |
| `archive (25).zip` | Coffee | Pending verification |
| `archive (26).zip` | Mango | Pending verification |
| `archive (27).zip` | Papaya | Pending verification |

The broader inventory also examined `archive (16).zip`, but it was not selected
by the final cleaner: its bell-pepper data was not treated as chilli data.

## Recorded cleaned dataset

These counts come from the saved reports, not a new scan of the images:

| Measure | Recorded value |
|---|---:|
| Crops | 25 |
| Model output classes | 122 |
| Healthy classes | 24 |
| Disease/pest/symptom classes | 98 |
| Selected source images scanned | 125,265 |
| Images retained | 123,811 |
| Exact duplicates removed | 1,454 |
| Corrupt/unreadable images removed | 0 |
| Training images | 99,045 |
| Validation images | 12,383 |
| Test images | 12,383 |

Images were prepared as 320 x 320 RGB JPEGs with split seed 42. The recorded
validation found no duplicate normalized-pixel hashes, but exact-duplicate
checking does not rule out near-duplicates or guarantee independence between
source datasets. The 122 outputs are crop/condition combinations, not 122
distinct diseases. Some crops have only generic healthy/diseased labels.

## Download and preparation procedure

1. Confirm each original Kaggle page and its dataset version from your download
   records. Download from that source under its access and license conditions.
2. Retain the original archives and record their source URLs, versions, licenses
   and checksums. Do not use an arbitrary same-named crop dataset as a substitute.
3. Review and update archive/output path constants in
   `ml_training/dataset_preparation/` for your machine. The scripts preserve
   historical Windows paths; they are not portable without that configuration.
4. Run inventory, cleaning and validation in that order. Inspect the resulting
   class list and split counts before training.
5. Point `AGRIAI_DATASET_ROOT` at the resulting directory containing `train/`,
   `validation/` and `test/`. Follow the training README for the remaining steps.

Until the pending URLs/versions are supplied, this is a provenance inventory
and workflow guide, not a complete independently reproducible download manifest.

## Supporting files

- [Training guide](ml_training/README.md)
- [Pre-cleaning crop coverage](ml_training/reports/AgriAI_25_Crop_Coverage.md)
- [Crop/disease class list](ml_training/reports/CROP_DISEASE_LIST.md)
- [Cleaning report](ml_training/reports/cleaning_report.json)
- [Validation report](ml_training/reports/validation_report.json)
- [Class labels](ml_training/reports/labels.json)
