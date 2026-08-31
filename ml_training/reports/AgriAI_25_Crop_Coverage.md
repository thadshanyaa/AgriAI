# AgriAI 25-Crop Dataset Coverage

> Inventory and selection plan. Original ZIP files were not modified.

## Result

- Target crops: 25
- Ready crops: 25
- Missing crops: 0
- Selected images before exact/corrupt duplicate cleaning: 125,265
- Selected crop-disease/health classes: 122

## Crop coverage

| # | Crop | Status | Selected source | Images | Classes | Note |
|---:|---|---|---|---:|---:|---|
| 1 | Rice | Ready | archive (20).zip | 3,355 | 4 | Uses named disease classes instead of the master dataset's generic diseased/healthy labels. |
| 2 | Maize / Corn | Ready | archive (12).zip | 10,947 | 5 |  |
| 3 | Tomato | Ready | archive (12).zip | 13,864 | 6 |  |
| 4 | Potato | Ready | archive (12).zip | 11,184 | 3 |  |
| 5 | Cucumber | Ready | archive (20).zip | 3,840 | 4 | Uses named disease classes instead of generic diseased/healthy labels. |
| 6 | Pumpkin | Ready | archive (12).zip | 1,999 | 5 |  |
| 7 | Bean | Ready | archive (12).zip | 1,167 | 3 |  |
| 8 | Apple | Ready | archive (12).zip | 9,704 | 4 |  |
| 9 | Grapes | Ready | archive (12).zip | 9,027 | 4 |  |
| 10 | Guava | Ready | archive (12).zip | 3,784 | 3 |  |
| 11 | Citrus / Lemon | Ready | archive (12).zip | 1,352 | 9 |  |
| 12 | Sugarcane | Ready | archive (12).zip | 19,086 | 6 |  |
| 13 | Groundnut | Ready | archive (12).zip | 10,351 | 5 |  |
| 14 | Chilli | Ready | archive (20).zip | 500 | 5 | archive (16) is Bell Pepper, not Chilli. |
| 15 | Brinjal | Ready | archive (17).zip | 2,216 | 2 |  |
| 16 | Okra | Ready | archive (18).zip | 1,949 | 2 | Only healthy vs diseased labels are present in the folders. |
| 17 | Cabbage | Ready | archive (19).zip | 1,600 | 8 | Balanced dataset; all classes contain 200 images. |
| 18 | Onion | Ready | archive (20).zip | 5,918 | 5 |  |
| 19 | Banana | Ready | archive (21).zip | 408 | 7 | Original images only. Excludes 2,856 pre-augmented images to reduce train/test leakage. |
| 20 | Coconut | Ready | archive (22).zip | 5,139 | 6 |  |
| 21 | Papaya | Ready | archive (27).zip | 135 | 4 | Only 135 images; use careful augmentation and stratified evaluation. |
| 22 | Mango | Ready | archive (26).zip | 4,000 | 8 | Balanced dataset with 500 images per class. |
| 23 | Pineapple | Ready | archive (23).zip | 2,313 | 4 | Original folder only. Excludes duplicate preprocessed/augmented folder sets. |
| 24 | Tea | Ready | archive (24).zip | 885 | 8 |  |
| 25 | Coffee | Ready | archive (25).zip | 542 | 2 | Rust and leaf-miner images with matching XML annotations; no healthy class. |

## Selected class list

### Rice — Ready

- `Rice___Healthy` — 1,488 images
- `Rice___Leaf_Blast` — 779 images
- `Rice___Hispa` — 565 images
- `Rice___Brown_Spot` — 523 images

### Maize / Corn — Ready

- `corn_northern_leaf_blight` — 3,529 images
- `healthy_corn` — 3,486 images
- `corn_cercospora_leaf_spot` — 2,052 images
- `corn_common_rust` — 1,306 images
- `corn_gray_leaf_spot` — 574 images

### Tomato — Ready

- `tomato_yellow_leaf_curl_virus` — 2,451 images
- `healthy_tomato` — 2,401 images
- `tomato_early_blight` — 2,400 images
- `tomato_late_blight` — 2,304 images
- `tomato_septoria_leaf_spot` — 2,181 images
- `tomato_bacterial_spot` — 2,127 images

### Potato — Ready

- `potato_early_blight` — 4,051 images
- `potato_late_blight` — 3,838 images
- `healthy_potato` — 3,295 images

### Cucumber — Ready

- `Cucumber___Anthracnose` — 960 images
- `Cucumber___Bacterial_Wilt` — 960 images
- `Cucumber___Gummy_Stem_Blight` — 960 images
- `Cucumber___Healthy_leaf` — 960 images

### Pumpkin — Ready

- `healthy_pumpkin` — 400 images
- `pumpkin_bacterial_leaf_spot` — 400 images
- `pumpkin_downy_mildew` — 400 images
- `pumpkin_mosaic_disease` — 400 images
- `pumpkin_powdery_mildew` — 399 images

### Bean — Ready

- `bean_rust` — 393 images
- `bean_angular_leaf_spot` — 389 images
- `healthy_bean` — 385 images

### Apple — Ready

- `apple_apple_scab` — 2,520 images
- `healthy_apple` — 2,500 images
- `apple_black_rot` — 2,484 images
- `apple_cedar_apple_rust` — 2,200 images

### Grapes — Ready

- `grape_esca_black_measles` — 2,400 images
- `grape_black_rot` — 2,360 images
- `grape_leaf_blight` — 2,152 images
- `healthy_grape` — 2,115 images

### Guava — Ready

- `guava_anthracnose` — 1,544 images
- `guava_fruit_fly` — 1,312 images
- `healthy_guava` — 928 images

### Citrus / Lemon — Ready

- `healthy_lemon` — 210 images
- `lemon_deficiency` — 193 images
- `lemon_dry_leaf` — 185 images
- `lemon_citrus_canker` — 178 images
- `lemon_sooty_mould` — 152 images
- `lemon_curl_virus` — 115 images
- `lemon_spider_mites` — 114 images
- `lemon_bacterial_blight` — 105 images
- `lemon_anthracnose` — 100 images

### Sugarcane — Ready

- `sugarcane_bacterial_blight` — 4,800 images
- `sugarcane_red_rot` — 3,108 images
- `sugarcane_yellow_leaf_disease` — 2,986 images
- `healthy_sugarcane` — 2,948 images
- `sugarcane_rust` — 2,816 images
- `sugarcane_mosaic` — 2,428 images

### Groundnut — Ready

- `groundnut_rust` — 3,197 images
- `groundnut_late_leaf_spot` — 1,896 images
- `healthy_groundnut` — 1,862 images
- `groundnut_early_leaf_spot` — 1,731 images
- `groundnut_nutrition_deficiency` — 1,665 images

### Chilli — Ready

- `Chili__healthy` — 100 images
- `Chili__leaf curl` — 100 images
- `Chili__leaf spot` — 100 images
- `Chili__whitefly` — 100 images
- `Chili__yellowish` — 100 images

### Brinjal — Ready

- `Fresh Brinjal Leaf` — 1,177 images
- `Diseased Brinjal Leaf - Cercospora Leaf Spot` — 1,039 images

### Okra — Ready

- `diseased okra leaf` — 1,072 images
- `fresh okra leaf` — 877 images

### Cabbage — Ready

- `Alternaria_Leaf_Spot` — 200 images
- `Bacterial spot rot` — 200 images
- `Black Rot` — 200 images
- `Cabbage aphid colony` — 200 images
- `Downy Mildew` — 200 images
- `No disease` — 200 images
- `club root` — 200 images
- `ring spot` — 200 images

### Onion — Ready

- `Onion___Healthy` — 3,440 images
- `Onion___Purple_blotch` — 847 images
- `Onion___Alternaria_D` — 830 images
- `Onion___Virosis-D` — 512 images
- `Onion___Botrytis_Leaf_Blight` — 289 images

### Banana — Ready

- `Banana Healthy Leaf` — 86 images
- `Banana Insect Pest Disease` — 86 images
- `Banana Black Sigatoka Disease` — 67 images
- `Banana Moko Disease` — 55 images
- `Banana Bract Mosaic Virus Disease` — 50 images
- `Banana Panama Disease` — 41 images
- `Banana Yellow Sigatoka Disease` — 23 images

### Coconut — Ready

- `WCLWD_Yellowing` — 1,084 images
- `WCLWD_DryingofLeaflets` — 1,078 images
- `WCLWD_Flaccidity` — 1,069 images
- `CCI_Caterpillars` — 990 images
- `CCI_Leaflets` — 795 images
- `Healthy_Leaves` — 123 images

### Papaya — Ready

- `Carica_Insect_Hole` — 54 images
- `healthy_leaf` — 40 images
- `Yellow_Necrotic_Spots_Holes` — 30 images
- `Bacterial_Blight` — 11 images

### Mango — Ready

- `Anthracnose` — 500 images
- `Bacterial Canker` — 500 images
- `Cutting Weevil` — 500 images
- `Die Back` — 500 images
- `Gall Midge` — 500 images
- `Healthy` — 500 images
- `Powdery Mildew` — 500 images
- `Sooty Mould` — 500 images

### Pineapple — Ready

- `Pineapple__leaf_blight` — 608 images
- `Pineapple_fusarium` — 590 images
- `Pineapple_healthy` — 576 images
- `Pineapple_mealybug_wilt` — 539 images

### Tea — Ready

- `red leaf spot` — 143 images
- `white spot` — 142 images
- `algal leaf` — 113 images
- `brown blight` — 113 images
- `Anthracnose` — 100 images
- `bird eye spot` — 100 images
- `gray light` — 100 images
- `healthy` — 74 images

### Coffee — Ready

- `rust_xml_image` — 285 images
- `miner_img_xml` — 257 images

## Important cleaning rules

- Do not use `archive (16).zip` for Chilli; it contains Bell Pepper only.
- From `archive (17).zip`, select Brinjal only; its Tomato and Bell Pepper images overlap other sources.
- From `archive (20).zip`, select Rice, Cucumber, Chilli, and Onion only; ignore the other overlapping crops.
- From `archive (21).zip`, preserve originals and generate augmentation only during model training.
- From `archive (23).zip`, use the original dataset folder only; do not mix original, preprocessed, and augmented copies.
- Remove exact SHA-256 duplicates before splitting, validate every image, and perform the train/validation/test split only after cleaning.
- Normalize labels but retain `source_archive`, `original_path`, and `original_label` in a CSV manifest.
