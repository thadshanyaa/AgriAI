from __future__ import annotations

import json
import shutil
from pathlib import Path

import h5py
import numpy as np
import tensorflow as tf


ROOT = Path(__file__).resolve().parent
INPUT_DIR = ROOT / "model_input"
OUTPUT_DIR = ROOT / "mobile_model_output"
WEIGHTS_PATH = INPUT_DIR / "model.weights.h5"
LABELS_PATH = INPUT_DIR / "labels.txt"
CONFIG_PATH = INPUT_DIR / "config.json"


def build_inference_model(class_count: int) -> tf.keras.Model:
    # TFLite float16 quantization stores weights in float16 while keeping
    # activations in float32. Building the inference graph in float32 avoids
    # unsupported float16 TensorFlow ops on older, stable converters.
    tf.keras.mixed_precision.set_global_policy("float32")
    inputs = tf.keras.Input(
        shape=(192, 192, 3), name="leaf_image", dtype=tf.float32
    )
    backbone = tf.keras.applications.MobileNetV3Large(
        input_shape=(192, 192, 3),
        include_top=False,
        weights=None,
        include_preprocessing=True,
    )
    features = backbone(inputs, training=False)
    features = tf.keras.layers.GlobalAveragePooling2D(
        name="global_average_pooling"
    )(features)
    features = tf.keras.layers.Dropout(0.30, name="dropout")(features)
    outputs = tf.keras.layers.Dense(
        class_count,
        activation="softmax",
        dtype="float32",
        name="crop_disease_probabilities",
    )(features)
    return tf.keras.Model(
        inputs, outputs, name="agriai_mobilenetv3large_122class"
    )


def _numeric_keys(group: h5py.Group) -> list[str]:
    return sorted(group.keys(), key=lambda value: int(value))


def _collect_saved_layers(
    group: h5py.Group, saved_layers: dict[str, list[np.ndarray]]
) -> None:
    """Index Keras 3 variables by their original layer names."""
    layers = group.get("layers")
    if isinstance(layers, h5py.Group):
        for layer_name in layers.keys():
            _collect_saved_layers(layers[layer_name], saved_layers)
    variables = group.get("vars")
    if isinstance(variables, h5py.Group) and len(variables):
        original_name = variables.attrs.get("name")
        if isinstance(original_name, bytes):
            original_name = original_name.decode("utf-8")
        if original_name:
            saved_layers[str(original_name)] = [
                np.asarray(variables[variable_name])
                for variable_name in _numeric_keys(variables)
            ]


def _ordered_layer_names(serialized_model: dict) -> list[str]:
    names: list[str] = []
    for layer in serialized_model.get("config", {}).get("layers", []):
        if layer.get("class_name") == "Functional":
            names.extend(_ordered_layer_names(layer))
        else:
            name = layer.get("config", {}).get("name")
            if name:
                names.append(str(name))
    return names


def load_keras3_weights(
    model: tf.keras.Model, path: Path, config_path: Path
) -> dict:
    saved_layers: dict[str, list[np.ndarray]] = {}
    with h5py.File(path, "r") as handle:
        _collect_saved_layers(handle, saved_layers)
    serialized_model = json.loads(config_path.read_text(encoding="utf-8"))
    arrays: list[np.ndarray] = []
    for layer_name in _ordered_layer_names(serialized_model):
        arrays.extend(saved_layers.get(layer_name, []))

    expected_shapes = [tuple(weight.shape) for weight in model.weights]
    saved_shapes = [tuple(array.shape) for array in arrays]
    if expected_shapes != saved_shapes:
        mismatch = next(
            (
                index
                for index, (expected, saved) in enumerate(
                    zip(expected_shapes, saved_shapes)
                )
                if expected != saved
            ),
            min(len(expected_shapes), len(saved_shapes)),
        )
        raise RuntimeError(
            "Serialized layer order does not match rebuilt model weights: "
            f"expected {len(expected_shapes)}, found {len(saved_shapes)}; "
            f"first mismatch index {mismatch}"
        )
    model.set_weights(arrays)
    return {
        "weight_arrays": len(arrays),
        "weight_parameters": int(sum(array.size for array in arrays)),
        "saved_weight_layers": len(saved_layers),
    }


def main() -> None:
    labels = [
        value.strip()
        for value in LABELS_PATH.read_text(encoding="utf-8").splitlines()
        if value.strip()
    ]
    if len(labels) != 122:
        raise RuntimeError(f"Expected 122 labels, found {len(labels)}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    model = build_inference_model(len(labels))
    weight_summary = load_keras3_weights(model, WEIGHTS_PATH, CONFIG_PATH)

    sample = np.zeros((1, 192, 192, 3), dtype=np.float32)
    keras_prediction = model(sample, training=False).numpy()
    if keras_prediction.shape != (1, len(labels)):
        raise RuntimeError(f"Unexpected Keras output: {keras_prediction.shape}")
    if not np.isfinite(keras_prediction).all():
        raise RuntimeError("Keras smoke test produced non-finite values")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_bytes = converter.convert()

    tflite_path = OUTPUT_DIR / "agriai_disease_float16.tflite"
    tflite_path.write_bytes(tflite_bytes)
    shutil.copy2(LABELS_PATH, OUTPUT_DIR / "labels.txt")

    interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
    interpreter.allocate_tensors()
    input_info = interpreter.get_input_details()[0]
    output_info = interpreter.get_output_details()[0]
    interpreter.set_tensor(input_info["index"], sample.astype(input_info["dtype"]))
    interpreter.invoke()
    tflite_prediction = interpreter.get_tensor(output_info["index"])

    if tflite_prediction.shape != (1, len(labels)):
        raise RuntimeError(f"Unexpected TFLite output: {tflite_prediction.shape}")
    if not np.isfinite(tflite_prediction).all():
        raise RuntimeError("TFLite smoke test produced non-finite values")

    max_abs_difference = float(
        np.max(np.abs(keras_prediction - tflite_prediction))
    )
    top1_match = int(np.argmax(keras_prediction[0])) == int(
        np.argmax(tflite_prediction[0])
    )
    results = {
        "tensorflow_version": tf.__version__,
        "python_workflow": "Python 3.11 TensorFlow 2.15.1",
        "conversion_method": "float32_inference_graph_with_float16_weights",
        "tflite_model": tflite_path.name,
        "tflite_bytes": tflite_path.stat().st_size,
        "tflite_mb": round(tflite_path.stat().st_size / (1024 * 1024), 2),
        "input_shape": input_info["shape"].tolist(),
        "input_dtype": str(input_info["dtype"]),
        "output_shape": output_info["shape"].tolist(),
        "output_dtype": str(output_info["dtype"]),
        "class_count": len(labels),
        "label_count": len(labels),
        "keras_probability_sum": float(keras_prediction[0].sum()),
        "tflite_probability_sum": float(tflite_prediction[0].sum()),
        "keras_tflite_max_abs_difference": max_abs_difference,
        "keras_tflite_top1_match": top1_match,
        "smoke_test": "passed",
        **weight_summary,
    }
    (OUTPUT_DIR / "CONVERSION_RESULTS.json").write_text(
        json.dumps(results, indent=2), encoding="utf-8"
    )
    archive = shutil.make_archive(
        str(ROOT / "AgriAI_TFLite_Mobile_Package"),
        "zip",
        root_dir=str(OUTPUT_DIR),
    )
    print(json.dumps(results, indent=2))
    print(f"Mobile package: {archive}")


if __name__ == "__main__":
    main()
