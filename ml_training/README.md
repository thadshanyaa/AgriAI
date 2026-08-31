# AgriAI model training source

These are the existing project training and dataset-preparation files, copied
without changing their code. Uploading them does not start training or certify
the deployed model's accuracy.

## Contents

- `train_agriai_kaggle.py`: MobileNetV3Large training, evaluation and export.
- `AgriAI_25Crop_Disease_Training.ipynb`: saved Kaggle notebook source.
- `make_kaggle_notebook.py`: historical notebook-generation helper.
- `convert_tflite_py311.py`: recovery conversion into a float16-weight TFLite model.
- `dataset_preparation/`: inventory, cleaning, validation, coverage and packaging tools.
- `model_input/`: model configuration and label metadata, not trained weights.
- `reports/`: historical dataset cleaning, validation and class-coverage reports.
- `mobile_model_output/CONVERSION_RESULTS.json`: saved conversion smoke-test report.

## Data and expected input

Read [DATASETS.md](../DATASETS.md) first. Training expects `train`, `validation`
and `test` folders with matching class subdirectories. The saved cleaned dataset
has 25 crops and 122 crop/disease/health classes. Raw images are not in Git.

## Training workflow

1. Obtain the source datasets with permission and verify their versions/licenses.
2. Review the scripts before running them: dataset preparation and notebook
   generation helpers contain historical absolute Windows paths. Update those
   path constants to your input and output folders. They create datasets,
   reports or archives; do not point them at irreplaceable folders.
3. Inspect the archives, run the cleaning script, then validate the clean dataset.
4. In a suitable Python/TensorFlow environment, install the dependencies used
   by the code: TensorFlow, NumPy, matplotlib, scikit-learn, Pillow and h5py.
   The training environment is not lockfile-pinned; compatibility must be checked.
5. Set `AGRIAI_DATASET_ROOT` to your clean dataset folder and
   `AGRIAI_OUTPUT_ROOT` to a writable output folder. Run
   `python ml_training/train_agriai_kaggle.py` from the repository root.
   Alternatively, import the notebook into Kaggle and attach the clean dataset.
6. The default training configuration uses 224 x 224 input, seed 42, batch 32,
   5 head-training epochs and 5 fine-tuning epochs. These can be changed using
   the `AGRIAI_*` environment variables defined at the top of the script.
7. Review evaluation results before exporting or replacing the app model.

The script can download ImageNet weights. GPU availability and service quotas
depend on the environment. This repository does not enable billing, provision
compute, or launch a paid training job.

## Recovery converter and missing checkpoint

The historical recovery converter uses Python 3.11 / TensorFlow 2.15.1 and a
192 x 192 inference graph. It requires `model_input/model.weights.h5`, which is
deliberately excluded from Git. The included `config.json`, `metadata.json` and
`labels.txt` are metadata only and cannot replace the missing checkpoint.
Run the converter only with its matching checkpoint and environment.

The deployed TFLite file is already tracked at
`../assets/models/agriai_disease_float16.tflite` with its app labels. The original
224-pixel training defaults and the recovery converter's 192-pixel graph are
different workflows: this source bundle is not a claim that running the default
notebook exactly reproduces the deployed model.

## Evidence and limitations

The reports were saved during earlier work; no new dataset validation or model
training was run during this GitHub upload. The notebook contains source cells,
not saved training outputs. Conversion smoke-test success and matching top-1
outputs are not test accuracy or proof of reliable field-photo recognition.
The full per-image manifest, raw images, checkpoints, and training accuracy
outputs are not included. Exact original Kaggle dataset URLs still need to be
verified; see the provenance table in `DATASETS.md`.
