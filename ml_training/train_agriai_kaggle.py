from __future__ import annotations

import csv
import json
import math
import os
import random
import subprocess
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from sklearn.metrics import classification_report, confusion_matrix


SEED = int(os.environ.get("AGRIAI_SEED", "42"))
IMAGE_SIZE = int(os.environ.get("AGRIAI_IMAGE_SIZE", "224"))
BATCH_SIZE = int(os.environ.get("AGRIAI_BATCH_SIZE", "32"))
HEAD_EPOCHS = int(os.environ.get("AGRIAI_HEAD_EPOCHS", "5"))
FINE_TUNE_EPOCHS = int(os.environ.get("AGRIAI_FINE_TUNE_EPOCHS", "5"))
FINE_TUNE_LAYERS = int(os.environ.get("AGRIAI_FINE_TUNE_LAYERS", "50"))
EXPORT_TFLITE = os.environ.get("AGRIAI_EXPORT_TFLITE", "1") == "1"
OUTPUT_ROOT = Path(os.environ.get("AGRIAI_OUTPUT_ROOT", "/kaggle/working/agriai_training_output"))


def find_dataset_root() -> Path:
    configured = os.environ.get("AGRIAI_DATASET_ROOT")
    candidates: list[Path] = []
    if configured:
        candidates.append(Path(configured))
    candidates.extend(
        [
            Path("/kaggle/input/agriai-clean-25crop-disease/AgriAI_Disease_Dataset_Clean_25Crops"),
            Path("/kaggle/input/agriai-clean-25crop-disease"),
            Path(r"D:\Projects\AgriAI_Disease_Dataset_Clean_25Crops"),
        ]
    )
    for candidate in candidates:
        if all((candidate / split).is_dir() for split in ("train", "validation", "test")):
            return candidate
    kaggle_input = Path("/kaggle/input")
    if kaggle_input.is_dir():
        for train_dir in kaggle_input.rglob("train"):
            parent = train_dir.parent
            if (parent / "validation").is_dir() and (parent / "test").is_dir():
                return parent
        tar_archives = list(kaggle_input.rglob("AgriAI_25Crop_Disease_Clean.tar"))
        if tar_archives:
            extraction_root = Path("/kaggle/working/agriai_dataset_extracted")
            expected = extraction_root / "AgriAI_Disease_Dataset_Clean_25Crops"
            if not expected.is_dir():
                extraction_root.mkdir(parents=True, exist_ok=True)
                print(f"Extracting {tar_archives[0]} to {extraction_root} ...", flush=True)
                subprocess.run(
                    ["tar", "-xf", str(tar_archives[0]), "-C", str(extraction_root)],
                    check=True,
                )
            if all((expected / split).is_dir() for split in ("train", "validation", "test")):
                return expected
    raise FileNotFoundError(
        "Could not find a dataset root containing train, validation, and test folders. "
        "Set AGRIAI_DATASET_ROOT to the correct Kaggle input path, or attach "
        "AgriAI_25Crop_Disease_Clean.tar."
    )


def set_reproducibility() -> None:
    os.environ["PYTHONHASHSEED"] = str(SEED)
    random.seed(SEED)
    np.random.seed(SEED)
    tf.random.set_seed(SEED)
    try:
        tf.config.experimental.enable_op_determinism()
    except Exception:
        pass


def configure_accelerator() -> dict:
    gpus = tf.config.list_physical_devices("GPU")
    for gpu in gpus:
        try:
            tf.config.experimental.set_memory_growth(gpu, True)
        except RuntimeError:
            pass
    if gpus:
        tf.keras.mixed_precision.set_global_policy("mixed_float16")
    return {
        "tensorflow_version": tf.__version__,
        "gpu_count": len(gpus),
        "gpus": [gpu.name for gpu in gpus],
        "mixed_precision_policy": tf.keras.mixed_precision.global_policy().name,
    }


def image_count(folder: Path) -> int:
    extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".tif", ".tiff"}
    return sum(1 for path in folder.iterdir() if path.is_file() and path.suffix.lower() in extensions)


def calculate_class_weights(train_dir: Path, class_names: list[str]) -> tuple[dict[int, float], dict[str, int]]:
    counts = {name: image_count(train_dir / name) for name in class_names}
    maximum = max(counts.values())
    raw = {index: math.sqrt(maximum / max(1, counts[name])) for index, name in enumerate(class_names)}
    mean_weight = sum(raw.values()) / len(raw)
    weights = {index: float(np.clip(value / mean_weight, 0.35, 8.0)) for index, value in raw.items()}
    return weights, counts


def load_datasets(dataset_root: Path):
    common = dict(
        labels="inferred",
        label_mode="int",
        class_names=None,
        image_size=(IMAGE_SIZE, IMAGE_SIZE),
        batch_size=BATCH_SIZE,
    )
    train_raw = tf.keras.utils.image_dataset_from_directory(
        dataset_root / "train",
        shuffle=True,
        seed=SEED,
        **common,
    )
    class_names = list(train_raw.class_names)
    validation_raw = tf.keras.utils.image_dataset_from_directory(
        dataset_root / "validation",
        shuffle=False,
        class_names=class_names,
        labels="inferred",
        label_mode="int",
        image_size=(IMAGE_SIZE, IMAGE_SIZE),
        batch_size=BATCH_SIZE,
    )
    test_raw = tf.keras.utils.image_dataset_from_directory(
        dataset_root / "test",
        shuffle=False,
        class_names=class_names,
        labels="inferred",
        label_mode="int",
        image_size=(IMAGE_SIZE, IMAGE_SIZE),
        batch_size=BATCH_SIZE,
    )

    augmentation = tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal_and_vertical", seed=SEED),
            tf.keras.layers.RandomRotation(0.10, fill_mode="reflect", seed=SEED),
            tf.keras.layers.RandomZoom(0.10, fill_mode="reflect", seed=SEED),
            tf.keras.layers.RandomContrast(0.12, seed=SEED),
        ],
        name="training_augmentation",
    )
    autotune = tf.data.AUTOTUNE
    train = train_raw.map(
        lambda images, labels: (augmentation(images, training=True), labels),
        num_parallel_calls=autotune,
        deterministic=False,
    ).prefetch(autotune)
    validation = validation_raw.prefetch(autotune)
    test = test_raw.prefetch(autotune)
    return train_raw, train, validation_raw, validation, test_raw, test, class_names


def build_model(class_count: int) -> tuple[tf.keras.Model, tf.keras.Model]:
    inputs = tf.keras.Input(shape=(IMAGE_SIZE, IMAGE_SIZE, 3), name="leaf_image", dtype=tf.float32)
    backbone = tf.keras.applications.MobileNetV3Large(
        input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3),
        include_top=False,
        weights="imagenet",
        include_preprocessing=True,
    )
    backbone.trainable = False
    features = backbone(inputs, training=False)
    features = tf.keras.layers.GlobalAveragePooling2D(name="global_average_pooling")(features)
    features = tf.keras.layers.Dropout(0.30, name="dropout")(features)
    outputs = tf.keras.layers.Dense(
        class_count,
        activation="softmax",
        dtype="float32",
        name="crop_disease_probabilities",
    )(features)
    model = tf.keras.Model(inputs, outputs, name="agriai_mobilenetv3large_122class")
    return model, backbone


def compile_model(model: tf.keras.Model, learning_rate: float) -> None:
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=[
            tf.keras.metrics.SparseCategoricalAccuracy(name="top1_accuracy"),
            tf.keras.metrics.SparseTopKCategoricalAccuracy(k=3, name="top3_accuracy"),
        ],
    )


def callbacks_for(stage: str, checkpoint_path: Path) -> list[tf.keras.callbacks.Callback]:
    return [
        tf.keras.callbacks.ModelCheckpoint(
            checkpoint_path,
            monitor="val_loss",
            save_best_only=True,
            verbose=1,
        ),
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=2,
            restore_best_weights=True,
            verbose=1,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.25,
            patience=1,
            min_lr=1e-7,
            verbose=1,
        ),
        tf.keras.callbacks.CSVLogger(OUTPUT_ROOT / f"{stage}_training_log.csv"),
        tf.keras.callbacks.TerminateOnNaN(),
    ]


def save_history(history: tf.keras.callbacks.History, name: str) -> None:
    serializable = {key: [float(value) for value in values] for key, values in history.history.items()}
    (OUTPUT_ROOT / f"{name}_history.json").write_text(json.dumps(serializable, indent=2), encoding="utf-8")


def evaluate_per_class(model, test_raw, class_names: list[str]) -> dict:
    y_true_parts: list[np.ndarray] = []
    y_probability_parts: list[np.ndarray] = []
    for images, labels in test_raw:
        probabilities = model(images, training=False).numpy()
        y_true_parts.append(labels.numpy())
        y_probability_parts.append(probabilities)
    y_true = np.concatenate(y_true_parts)
    probabilities = np.concatenate(y_probability_parts)
    y_pred = np.argmax(probabilities, axis=1)

    report = classification_report(
        y_true,
        y_pred,
        labels=np.arange(len(class_names)),
        target_names=class_names,
        output_dict=True,
        zero_division=0,
    )
    with (OUTPUT_ROOT / "classification_report.csv").open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.writer(handle)
        writer.writerow(["class_id", "precision", "recall", "f1_score", "support"])
        for class_name in class_names:
            values = report[class_name]
            writer.writerow(
                [class_name, values["precision"], values["recall"], values["f1-score"], values["support"]]
            )

    matrix = confusion_matrix(y_true, y_pred, labels=np.arange(len(class_names)))
    np.save(OUTPUT_ROOT / "confusion_matrix.npy", matrix)
    row_totals = matrix.sum(axis=1, keepdims=True)
    normalized = np.divide(matrix, row_totals, out=np.zeros_like(matrix, dtype=float), where=row_totals != 0)
    plt.figure(figsize=(20, 18))
    plt.imshow(normalized, interpolation="nearest", cmap="viridis", vmin=0, vmax=1)
    plt.title("AgriAI normalized confusion matrix — 122 classes")
    plt.xlabel("Predicted class index")
    plt.ylabel("True class index")
    plt.colorbar()
    plt.tight_layout()
    plt.savefig(OUTPUT_ROOT / "confusion_matrix.png", dpi=180)
    plt.close()

    summary = {
        "test_images": int(len(y_true)),
        "macro_precision": float(report["macro avg"]["precision"]),
        "macro_recall": float(report["macro avg"]["recall"]),
        "macro_f1": float(report["macro avg"]["f1-score"]),
        "weighted_f1": float(report["weighted avg"]["f1-score"]),
    }
    (OUTPUT_ROOT / "classification_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary


def export_tflite(model: tf.keras.Model, train_raw) -> dict:
    exports: dict[str, dict] = {}

    float_converter = tf.lite.TFLiteConverter.from_keras_model(model)
    float_model = float_converter.convert()
    float_path = OUTPUT_ROOT / "agriai_disease_float32.tflite"
    float_path.write_bytes(float_model)
    exports["float32"] = {"path": float_path.name, "bytes": float_path.stat().st_size}

    float16_converter = tf.lite.TFLiteConverter.from_keras_model(model)
    float16_converter.optimizations = [tf.lite.Optimize.DEFAULT]
    float16_converter.target_spec.supported_types = [tf.float16]
    float16_model = float16_converter.convert()
    float16_path = OUTPUT_ROOT / "agriai_disease_float16.tflite"
    float16_path.write_bytes(float16_model)
    exports["float16"] = {"path": float16_path.name, "bytes": float16_path.stat().st_size}

    def representative_dataset():
        for images, _ in train_raw.unbatch().batch(1).take(250):
            yield [tf.cast(images, tf.float32)]

    try:
        int8_converter = tf.lite.TFLiteConverter.from_keras_model(model)
        int8_converter.optimizations = [tf.lite.Optimize.DEFAULT]
        int8_converter.representative_dataset = representative_dataset
        int8_converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        int8_converter.inference_input_type = tf.uint8
        int8_converter.inference_output_type = tf.uint8
        int8_model = int8_converter.convert()
        int8_path = OUTPUT_ROOT / "agriai_disease_int8.tflite"
        int8_path.write_bytes(int8_model)
        exports["int8"] = {"path": int8_path.name, "bytes": int8_path.stat().st_size}
    except Exception as exc:
        exports["int8"] = {"error": f"{type(exc).__name__}: {exc}"}

    (OUTPUT_ROOT / "tflite_exports.json").write_text(json.dumps(exports, indent=2), encoding="utf-8")
    return exports


def tflite_smoke_test(model_path: Path, test_raw, class_names: list[str]) -> dict:
    interpreter = tf.lite.Interpreter(model_path=str(model_path))
    interpreter.allocate_tensors()
    input_detail = interpreter.get_input_details()[0]
    output_detail = interpreter.get_output_details()[0]
    images, labels = next(iter(test_raw.take(1)))
    sample = images[:1].numpy().astype(np.float32)
    if input_detail["dtype"] == np.uint8:
        scale, zero_point = input_detail["quantization"]
        sample = np.clip(np.rint(sample / scale + zero_point), 0, 255).astype(np.uint8)
    interpreter.set_tensor(input_detail["index"], sample)
    interpreter.invoke()
    output = interpreter.get_tensor(output_detail["index"])
    if output_detail["dtype"] == np.uint8:
        scale, zero_point = output_detail["quantization"]
        output = (output.astype(np.float32) - zero_point) * scale
    predicted_index = int(np.argmax(output[0]))
    actual_index = int(labels[0].numpy())
    result = {
        "model": model_path.name,
        "input_dtype": str(input_detail["dtype"]),
        "output_dtype": str(output_detail["dtype"]),
        "actual_index": actual_index,
        "actual_class": class_names[actual_index],
        "predicted_index": predicted_index,
        "predicted_class": class_names[predicted_index],
        "confidence": float(np.max(output[0])),
    }
    (OUTPUT_ROOT / "tflite_smoke_test.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    return result


def main() -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    set_reproducibility()
    accelerator = configure_accelerator()
    dataset_root = find_dataset_root()
    print("Dataset root:", dataset_root)
    print("Accelerator:", json.dumps(accelerator, indent=2))
    if accelerator["gpu_count"] == 0:
        raise RuntimeError("No GPU detected. Enable a Kaggle T4 GPU before training.")

    train_raw, train, validation_raw, validation, test_raw, test, class_names = load_datasets(dataset_root)
    if len(class_names) != 122:
        raise RuntimeError(f"Expected 122 classes, found {len(class_names)}")
    class_weights, train_counts = calculate_class_weights(dataset_root / "train", class_names)
    (OUTPUT_ROOT / "labels.txt").write_text("\n".join(class_names) + "\n", encoding="utf-8")
    (OUTPUT_ROOT / "training_configuration.json").write_text(
        json.dumps(
            {
                "dataset_root": str(dataset_root),
                "output_root": str(OUTPUT_ROOT),
                "seed": SEED,
                "image_size": IMAGE_SIZE,
                "batch_size": BATCH_SIZE,
                "head_epochs": HEAD_EPOCHS,
                "fine_tune_epochs": FINE_TUNE_EPOCHS,
                "fine_tune_layers": FINE_TUNE_LAYERS,
                "class_count": len(class_names),
                "train_counts": train_counts,
                "class_weights": {class_names[index]: weight for index, weight in class_weights.items()},
                "accelerator": accelerator,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    model, backbone = build_model(len(class_names))
    compile_model(model, learning_rate=1e-3)
    model.summary()

    head_checkpoint = OUTPUT_ROOT / "best_head_model.keras"
    head_history = model.fit(
        train,
        validation_data=validation,
        epochs=HEAD_EPOCHS,
        class_weight=class_weights,
        callbacks=callbacks_for("head", head_checkpoint),
        verbose=1,
    )
    save_history(head_history, "head")
    head_model = tf.keras.models.load_model(head_checkpoint)
    head_validation = head_model.evaluate(validation, verbose=1, return_dict=True)

    model = head_model
    backbone = next(layer for layer in model.layers if isinstance(layer, tf.keras.Model))
    backbone.trainable = True
    for layer in backbone.layers[:-FINE_TUNE_LAYERS]:
        layer.trainable = False
    for layer in backbone.layers:
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False
    compile_model(model, learning_rate=1e-5)

    fine_checkpoint = OUTPUT_ROOT / "best_fine_tuned_model.keras"
    fine_history = model.fit(
        train,
        validation_data=validation,
        epochs=FINE_TUNE_EPOCHS,
        class_weight=class_weights,
        callbacks=callbacks_for("fine_tune", fine_checkpoint),
        verbose=1,
    )
    save_history(fine_history, "fine_tune")
    fine_model = tf.keras.models.load_model(fine_checkpoint)
    fine_validation = fine_model.evaluate(validation, verbose=1, return_dict=True)

    if fine_validation["loss"] <= head_validation["loss"]:
        model = fine_model
        selected_stage = "fine_tuned"
        selected_validation = fine_validation
    else:
        model = head_model
        selected_stage = "head"
        selected_validation = head_validation

    final_model_path = OUTPUT_ROOT / "agriai_disease_model.keras"
    model.save(final_model_path)
    test_metrics = model.evaluate(test, verbose=1, return_dict=True)
    classification_summary = evaluate_per_class(model, test_raw, class_names)
    tflite_exports = {}
    smoke = None
    if EXPORT_TFLITE:
        tflite_exports = export_tflite(model, train_raw)
        preferred_tflite = OUTPUT_ROOT / (
            tflite_exports.get("int8", {}).get("path") or tflite_exports["float16"]["path"]
        )
        smoke = tflite_smoke_test(preferred_tflite, test_raw, class_names)
    else:
        print("Skipping inline TFLite export; use the separate conversion job.")

    final_summary = {
        "selected_stage": selected_stage,
        "validation_metrics": {key: float(value) for key, value in selected_validation.items()},
        "test_metrics": {key: float(value) for key, value in test_metrics.items()},
        "classification_summary": classification_summary,
        "tflite_exports": tflite_exports,
        "tflite_smoke_test": smoke,
    }
    (OUTPUT_ROOT / "FINAL_RESULTS.json").write_text(json.dumps(final_summary, indent=2), encoding="utf-8")
    print("FINAL RESULTS")
    print(json.dumps(final_summary, indent=2))


if __name__ == "__main__":
    main()
