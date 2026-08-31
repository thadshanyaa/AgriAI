# AgriAI Final Crop and Disease Identification List

## Final cleaned dataset

- Crops: 25
- Total model output classes: 122
- Healthy classes: 24
- Disease/pest/symptom classes: 98
- Images: 123,811

| # | Crop | Images | Total classes | Non-healthy classes | Healthy available |
|---:|---|---:|---:|---:|---|
| 1 | Rice | 3,355 | 4 | 3 | Yes |
| 2 | Maize / Corn | 10,947 | 5 | 4 | Yes |
| 3 | Tomato | 13,864 | 6 | 5 | Yes |
| 4 | Potato | 11,184 | 3 | 2 | Yes |
| 5 | Cucumber | 3,830 | 4 | 3 | Yes |
| 6 | Pumpkin | 1,999 | 5 | 4 | Yes |
| 7 | Bean | 1,167 | 3 | 2 | Yes |
| 8 | Apple | 9,704 | 4 | 3 | Yes |
| 9 | Grapes | 9,027 | 4 | 3 | Yes |
| 10 | Guava | 3,784 | 3 | 2 | Yes |
| 11 | Citrus / Lemon | 1,352 | 9 | 8 | Yes |
| 12 | Sugarcane | 19,086 | 6 | 5 | Yes |
| 13 | Groundnut | 10,351 | 5 | 4 | Yes |
| 14 | Chilli | 479 | 5 | 4 | Yes |
| 15 | Brinjal | 2,216 | 2 | 1 | Yes |
| 16 | Okra | 1,949 | 2 | 1 | Yes |
| 17 | Cabbage | 1,550 | 8 | 7 | Yes |
| 18 | Onion | 4,778 | 5 | 4 | Yes |
| 19 | Banana | 408 | 7 | 6 | Yes |
| 20 | Coconut | 5,138 | 6 | 5 | Yes |
| 21 | Papaya | 133 | 4 | 3 | Yes |
| 22 | Mango | 3,979 | 8 | 7 | Yes |
| 23 | Pineapple | 2,107 | 4 | 3 | Yes |
| 24 | Tea | 882 | 8 | 7 | Yes |
| 25 | Coffee | 542 | 2 | 2 | No |

## Detailed classes

### Rice

- `rice___brown_spot` — Brown Spot — 523 images — Disease/pest/symptom
- `rice___healthy` — Healthy — 1,488 images — Healthy
- `rice___hispa` — Hispa — 565 images — Disease/pest/symptom
- `rice___leaf_blast` — Leaf Blast — 779 images — Disease/pest/symptom

### Maize / Corn

- `maize_corn___cercospora_leaf_spot` — Cercospora Leaf Spot — 2,052 images — Disease/pest/symptom
- `maize_corn___common_rust` — Common Rust — 1,306 images — Disease/pest/symptom
- `maize_corn___gray_leaf_spot` — Gray Leaf Spot — 574 images — Disease/pest/symptom
- `maize_corn___healthy` — Healthy — 3,486 images — Healthy
- `maize_corn___northern_leaf_blight` — Northern Leaf Blight — 3,529 images — Disease/pest/symptom

### Tomato

- `tomato___bacterial_spot` — Bacterial Spot — 2,127 images — Disease/pest/symptom
- `tomato___early_blight` — Early Blight — 2,400 images — Disease/pest/symptom
- `tomato___healthy` — Healthy — 2,401 images — Healthy
- `tomato___late_blight` — Late Blight — 2,304 images — Disease/pest/symptom
- `tomato___septoria_leaf_spot` — Septoria Leaf Spot — 2,181 images — Disease/pest/symptom
- `tomato___yellow_leaf_curl_virus` — Yellow Leaf Curl Virus — 2,451 images — Disease/pest/symptom

### Potato

- `potato___early_blight` — Early Blight — 4,051 images — Disease/pest/symptom
- `potato___healthy` — Healthy — 3,295 images — Healthy
- `potato___late_blight` — Late Blight — 3,838 images — Disease/pest/symptom

### Cucumber

- `cucumber___anthracnose` — Anthracnose — 951 images — Disease/pest/symptom
- `cucumber___bacterial_wilt` — Bacterial Wilt — 959 images — Disease/pest/symptom
- `cucumber___gummy_stem_blight` — Gummy Stem Blight — 960 images — Disease/pest/symptom
- `cucumber___healthy` — Healthy — 960 images — Healthy

### Pumpkin

- `pumpkin___bacterial_leaf_spot` — Bacterial Leaf Spot — 400 images — Disease/pest/symptom
- `pumpkin___downy_mildew` — Downy Mildew — 400 images — Disease/pest/symptom
- `pumpkin___healthy` — Healthy — 400 images — Healthy
- `pumpkin___mosaic_disease` — Mosaic Disease — 400 images — Disease/pest/symptom
- `pumpkin___powdery_mildew` — Powdery Mildew — 399 images — Disease/pest/symptom

### Bean

- `bean___angular_leaf_spot` — Angular Leaf Spot — 389 images — Disease/pest/symptom
- `bean___healthy` — Healthy — 385 images — Healthy
- `bean___rust` — Rust — 393 images — Disease/pest/symptom

### Apple

- `apple___black_rot` — Black Rot — 2,484 images — Disease/pest/symptom
- `apple___cedar_apple_rust` — Cedar Apple Rust — 2,200 images — Disease/pest/symptom
- `apple___healthy` — Healthy — 2,500 images — Healthy
- `apple___scab` — Scab — 2,520 images — Disease/pest/symptom

### Grapes

- `grapes___black_rot` — Black Rot — 2,360 images — Disease/pest/symptom
- `grapes___esca_black_measles` — Esca Black Measles — 2,400 images — Disease/pest/symptom
- `grapes___healthy` — Healthy — 2,115 images — Healthy
- `grapes___leaf_blight` — Leaf Blight — 2,152 images — Disease/pest/symptom

### Guava

- `guava___anthracnose` — Anthracnose — 1,544 images — Disease/pest/symptom
- `guava___fruit_fly` — Fruit Fly — 1,312 images — Disease/pest/symptom
- `guava___healthy` — Healthy — 928 images — Healthy

### Citrus / Lemon

- `citrus_lemon___anthracnose` — Anthracnose — 100 images — Disease/pest/symptom
- `citrus_lemon___bacterial_blight` — Bacterial Blight — 105 images — Disease/pest/symptom
- `citrus_lemon___citrus_canker` — Citrus Canker — 178 images — Disease/pest/symptom
- `citrus_lemon___curl_virus` — Curl Virus — 115 images — Disease/pest/symptom
- `citrus_lemon___deficiency` — Deficiency — 193 images — Disease/pest/symptom
- `citrus_lemon___dry_leaf` — Dry Leaf — 185 images — Disease/pest/symptom
- `citrus_lemon___healthy` — Healthy — 210 images — Healthy
- `citrus_lemon___sooty_mould` — Sooty Mould — 152 images — Disease/pest/symptom
- `citrus_lemon___spider_mites` — Spider Mites — 114 images — Disease/pest/symptom

### Sugarcane

- `sugarcane___bacterial_blight` — Bacterial Blight — 4,800 images — Disease/pest/symptom
- `sugarcane___healthy` — Healthy — 2,948 images — Healthy
- `sugarcane___mosaic` — Mosaic — 2,428 images — Disease/pest/symptom
- `sugarcane___red_rot` — Red Rot — 3,108 images — Disease/pest/symptom
- `sugarcane___rust` — Rust — 2,816 images — Disease/pest/symptom
- `sugarcane___yellow_leaf_disease` — Yellow Leaf Disease — 2,986 images — Disease/pest/symptom

### Groundnut

- `groundnut___early_leaf_spot` — Early Leaf Spot — 1,731 images — Disease/pest/symptom
- `groundnut___healthy` — Healthy — 1,862 images — Healthy
- `groundnut___late_leaf_spot` — Late Leaf Spot — 1,896 images — Disease/pest/symptom
- `groundnut___nutrition_deficiency` — Nutrition Deficiency — 1,665 images — Disease/pest/symptom
- `groundnut___rust` — Rust — 3,197 images — Disease/pest/symptom

### Chilli

- `chilli___healthy` — Healthy — 100 images — Healthy
- `chilli___leaf_curl` — Leaf Curl — 98 images — Disease/pest/symptom
- `chilli___leaf_spot` — Leaf Spot — 100 images — Disease/pest/symptom
- `chilli___whitefly` — Whitefly — 99 images — Disease/pest/symptom
- `chilli___yellowish` — Yellowish — 82 images — Disease/pest/symptom

### Brinjal

- `brinjal___cercospora_leaf_spot` — Cercospora Leaf Spot — 1,039 images — Disease/pest/symptom
- `brinjal___healthy` — Healthy — 1,177 images — Healthy

### Okra

- `okra___diseased_leaf_unspecified` — Diseased Leaf Unspecified — 1,072 images — Disease/pest/symptom
- `okra___healthy` — Healthy — 877 images — Healthy

### Cabbage

- `cabbage___alternaria_leaf_spot` — Alternaria Leaf Spot — 192 images — Disease/pest/symptom
- `cabbage___bacterial_spot_rot` — Bacterial Spot Rot — 195 images — Disease/pest/symptom
- `cabbage___black_rot` — Black Rot — 187 images — Disease/pest/symptom
- `cabbage___cabbage_aphid_colony` — Cabbage Aphid Colony — 195 images — Disease/pest/symptom
- `cabbage___club_root` — Club Root — 197 images — Disease/pest/symptom
- `cabbage___downy_mildew` — Downy Mildew — 191 images — Disease/pest/symptom
- `cabbage___healthy` — Healthy — 200 images — Healthy
- `cabbage___ring_spot` — Ring Spot — 193 images — Disease/pest/symptom

### Onion

- `onion___alternaria_d` — Alternaria D — 506 images — Disease/pest/symptom
- `onion___botrytis_leaf_blight` — Botrytis Leaf Blight — 289 images — Disease/pest/symptom
- `onion___healthy` — Healthy — 2,937 images — Healthy
- `onion___purple_blotch` — Purple Blotch — 847 images — Disease/pest/symptom
- `onion___virosis_d` — Virosis D — 199 images — Disease/pest/symptom

### Banana

- `banana___black_sigatoka` — Black Sigatoka — 67 images — Disease/pest/symptom
- `banana___bract_mosaic_virus` — Bract Mosaic Virus — 50 images — Disease/pest/symptom
- `banana___healthy` — Healthy — 86 images — Healthy
- `banana___insect_pest` — Insect Pest — 86 images — Disease/pest/symptom
- `banana___moko_disease` — Moko Disease — 55 images — Disease/pest/symptom
- `banana___panama_disease` — Panama Disease — 41 images — Disease/pest/symptom
- `banana___yellow_sigatoka` — Yellow Sigatoka — 23 images — Disease/pest/symptom

### Coconut

- `coconut___cci_caterpillars` — Cci Caterpillars — 990 images — Disease/pest/symptom
- `coconut___cci_leaflets` — Cci Leaflets — 795 images — Disease/pest/symptom
- `coconut___healthy` — Healthy — 123 images — Healthy
- `coconut___wclwd_drying_of_leaflets` — Wclwd Drying Of Leaflets — 1,078 images — Disease/pest/symptom
- `coconut___wclwd_flaccidity` — Wclwd Flaccidity — 1,068 images — Disease/pest/symptom
- `coconut___wclwd_yellowing` — Wclwd Yellowing — 1,084 images — Disease/pest/symptom

### Papaya

- `papaya___bacterial_blight` — Bacterial Blight — 11 images — Disease/pest/symptom
- `papaya___healthy` — Healthy — 39 images — Healthy
- `papaya___insect_hole` — Insect Hole — 54 images — Disease/pest/symptom
- `papaya___yellow_necrotic_spots_holes` — Yellow Necrotic Spots Holes — 29 images — Disease/pest/symptom

### Mango

- `mango___anthracnose` — Anthracnose — 486 images — Disease/pest/symptom
- `mango___bacterial_canker` — Bacterial Canker — 500 images — Disease/pest/symptom
- `mango___cutting_weevil` — Cutting Weevil — 500 images — Disease/pest/symptom
- `mango___die_back` — Die Back — 493 images — Disease/pest/symptom
- `mango___gall_midge` — Gall Midge — 500 images — Disease/pest/symptom
- `mango___healthy` — Healthy — 500 images — Healthy
- `mango___powdery_mildew` — Powdery Mildew — 500 images — Disease/pest/symptom
- `mango___sooty_mould` — Sooty Mould — 500 images — Disease/pest/symptom

### Pineapple

- `pineapple___fusarium` — Fusarium — 566 images — Disease/pest/symptom
- `pineapple___healthy` — Healthy — 502 images — Healthy
- `pineapple___leaf_blight` — Leaf Blight — 520 images — Disease/pest/symptom
- `pineapple___mealybug_wilt` — Mealybug Wilt — 519 images — Disease/pest/symptom

### Tea

- `tea___algal_leaf` — Algal Leaf — 113 images — Disease/pest/symptom
- `tea___anthracnose` — Anthracnose — 100 images — Disease/pest/symptom
- `tea___bird_eye_spot` — Bird Eye Spot — 99 images — Disease/pest/symptom
- `tea___brown_blight` — Brown Blight — 113 images — Disease/pest/symptom
- `tea___gray_light` — Gray Light — 98 images — Disease/pest/symptom
- `tea___healthy` — Healthy — 74 images — Healthy
- `tea___red_leaf_spot` — Red Leaf Spot — 143 images — Disease/pest/symptom
- `tea___white_spot` — White Spot — 142 images — Disease/pest/symptom

### Coffee

- `coffee___leaf_miner` — Leaf Miner — 257 images — Disease/pest/symptom
- `coffee___rust` — Rust — 285 images — Disease/pest/symptom

## Dataset limitations to state in the report

- Okra has a generic `diseased_leaf_unspecified` label rather than a named disease.
- Coconut WCLWD labels include symptom stages; they are not necessarily separate diseases.
- Coffee has rust and leaf-miner classes but no healthy class.
- Papaya has relatively few source images, especially bacterial blight; apply augmentation to the training split only.
- Tea retains the source label `gray_light`; verify whether the source intended `gray blight` before changing the scientific label.
