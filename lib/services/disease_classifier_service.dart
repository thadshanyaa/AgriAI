import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DiseasePredictionItem {
  const DiseasePredictionItem({
    required this.rawLabel,
    required this.crop,
    required this.disease,
    required this.confidence,
  });

  final String rawLabel;
  final String crop;
  final String disease;
  final double confidence;

  String get confidenceText => '${(confidence * 100).toStringAsFixed(1)}%';
}

class DiseasePrediction extends DiseasePredictionItem {
  const DiseasePrediction({
    required super.rawLabel,
    required super.crop,
    required super.disease,
    required super.confidence,
    required this.topPredictions,
    this.usedExpectedCrop = false,
    this.cropEvidence = 1,
  });

  final List<DiseasePredictionItem> topPredictions;
  final bool usedExpectedCrop;
  final double cropEvidence;

  bool get isHealthy => disease.toLowerCase() == 'healthy';
  bool get isLowConfidence => confidence < 0.60;
  double get confidenceMargin => topPredictions.length < 2
      ? confidence
      : confidence - topPredictions[1].confidence;

  // This is a conservative closed-set rejection rule. A dedicated unknown
  // class can improve it further when unsupported-leaf training data exists.
  bool get isUnsupported =>
      (usedExpectedCrop && cropEvidence < 0.035) ||
      confidence < 0.45 ||
      confidenceMargin < 0.08;
}

class DiseaseScanResult {
  const DiseaseScanResult({
    required this.prediction,
    required this.imageBytes,
    required this.selectedCrop,
    required this.growthStage,
  });

  final DiseasePrediction prediction;
  final Uint8List imageBytes;
  final String selectedCrop;
  final String growthStage;
}

abstract final class DiseaseClassifierService {
  static const _modelPath = 'assets/models/agriai_disease_float16.tflite';
  static const _labelsPath = 'assets/models/labels.txt';
  static const _inputSize = 192;
  static const _classCount = 122;

  static Interpreter? _interpreter;
  static List<String>? _labels;

  static Future<void> _load() async {
    if (_interpreter != null && _labels != null) return;

    final labelsText = await rootBundle.loadString(_labelsPath);
    final labels = labelsText
        .split(RegExp(r'\r?\n'))
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    if (labels.length != _classCount) {
      throw StateError(
        'Disease model requires $_classCount labels, found ${labels.length}.',
      );
    }

    final interpreter = await Interpreter.fromAsset(_modelPath);
    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;
    if (!_sameShape(inputShape, const [1, _inputSize, _inputSize, 3]) ||
        !_sameShape(outputShape, const [1, _classCount])) {
      interpreter.close();
      throw StateError(
        'Unexpected disease model shape: input $inputShape, output $outputShape.',
      );
    }

    _labels = labels;
    _interpreter = interpreter;
  }

  static bool _sameShape(List<int> actual, List<int> expected) {
    if (actual.length != expected.length) return false;
    for (var index = 0; index < actual.length; index++) {
      if (actual[index] != expected[index]) return false;
    }
    return true;
  }

  static Future<DiseasePrediction> classify(
    Uint8List imageBytes, {
    String? expectedCrop,
  }) async {
    await _load();

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw const FormatException(
        'This image could not be read. Please choose a JPG or PNG leaf photo.',
      );
    }
    // Camera images can contain EXIF rotation and are commonly 4:3 or 16:9.
    // Bake the orientation first, then use a centre square crop so a leaf is
    // not stretched into the square input used during model training.
    final oriented = img.bakeOrientation(decoded);
    final resized = img.copyResizeCropSquare(
      oriented,
      size: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // MobileNetV3 preprocessing is embedded in the model, so RGB values must
    // remain in their original 0-255 range.
    final input = [
      List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
        }, growable: false),
        growable: false,
      ),
    ];
    final output = [List<double>.filled(_classCount, 0)];
    _interpreter!.run(input, output);

    final scores = _asProbabilities(output.first);
    final expectedKey = expectedCrop == null ? null : _cropKey(expectedCrop);
    final matchingIndexes = expectedKey == null
        ? <int>[]
        : List<int>.generate(scores.length, (index) => index)
              .where(
                (index) => _labels![index].split('___').first == expectedKey,
              )
              .toList(growable: false);
    final candidateIndexes = matchingIndexes.isEmpty
        ? List<int>.generate(scores.length, (index) => index)
        : matchingIndexes;
    final cropEvidence = matchingIndexes.isEmpty
        ? 1.0
        : matchingIndexes.fold<double>(0, (sum, index) => sum + scores[index]);
    final candidateScores = <int, double>{
      for (final index in candidateIndexes)
        index: matchingIndexes.isNotEmpty && cropEvidence > 0
            ? scores[index] / cropEvidence
            : scores[index],
    };
    final rankedIndexes = candidateIndexes
      ..sort((a, b) => scores[b].compareTo(scores[a]));
    final topPredictions = rankedIndexes
        .take(3)
        .map(
          (index) => _predictionItem(
            _labels![index],
            candidateScores[index] ?? scores[index],
          ),
        )
        .toList(growable: false);
    final best = topPredictions.first;

    return DiseasePrediction(
      rawLabel: best.rawLabel,
      crop: best.crop,
      disease: best.disease,
      confidence: best.confidence,
      topPredictions: topPredictions,
      usedExpectedCrop: matchingIndexes.isNotEmpty,
      cropEvidence: cropEvidence.clamp(0.0, 1.0),
    );
  }

  static List<double> _asProbabilities(List<double> values) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final alreadyProbabilities =
        values.every((value) => value.isFinite && value >= 0 && value <= 1) &&
        total > 0.98 &&
        total < 1.02;
    if (alreadyProbabilities) return values;

    final maximum = values.reduce((a, b) => a > b ? a : b);
    final exponents = values
        .map((value) => _safeExponent(value - maximum))
        .toList(growable: false);
    final sum = exponents.fold<double>(0, (a, b) => a + b);
    if (sum <= 0 || !sum.isFinite) {
      return List<double>.filled(values.length, 1 / values.length);
    }
    return exponents.map((value) => value / sum).toList(growable: false);
  }

  static double _safeExponent(double value) {
    return math.exp(value);
  }

  static DiseasePredictionItem _predictionItem(
    String rawLabel,
    double confidence,
  ) {
    final parts = rawLabel.split('___');
    final rawCrop = parts.first;
    final rawDisease = parts.length > 1
        ? parts.sublist(1).join(' ')
        : 'unknown';
    return DiseasePredictionItem(
      rawLabel: rawLabel,
      crop: _friendlyName(rawCrop),
      disease: _friendlyName(rawDisease),
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  static String _cropKey(String crop) {
    return switch (crop.toLowerCase()) {
      'citrus / lemon' => 'citrus_lemon',
      'maize / corn' => 'maize_corn',
      _ => crop.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
    };
  }

  static String _friendlyName(String value) {
    final expanded = switch (value) {
      'citrus_lemon' => 'citrus / lemon',
      'maize_corn' => 'maize / corn',
      'alternaria_d' => 'alternaria disease',
      'virosis_d' => 'virosis disease',
      _ => value.replaceAll('_', ' '),
    };
    return expanded
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part == '/'
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
