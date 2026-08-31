import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/disease_classifier_service.dart';
import '../services/firebase_backend.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  static const _supportedCrops = [
    'Apple',
    'Banana',
    'Bean',
    'Brinjal',
    'Cabbage',
    'Chilli',
    'Citrus / Lemon',
    'Coconut',
    'Coffee',
    'Cucumber',
    'Grapes',
    'Groundnut',
    'Guava',
    'Maize / Corn',
    'Mango',
    'Okra',
    'Onion',
    'Papaya',
    'Pineapple',
    'Potato',
    'Pumpkin',
    'Rice',
    'Sugarcane',
    'Tea',
    'Tomato',
  ];

  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _crop;
  String _stage = 'Leaf Area';
  bool _analyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final preferences = await SharedPreferences.getInstance();
        if (preferences.getBool('camera_enabled') == false) {
          if (mounted) {
            showDemoMessage(context, 'Camera is disabled in AgriAI Settings.');
          }
          return;
        }
      }
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() => _imageBytes = bytes);
        showDemoMessage(
          context,
          'Photo ready. Select the correct crop when known, then analyze.',
        );
      }
    } catch (_) {
      if (mounted) showDemoMessage(context, 'Unable to open image source');
    }
  }

  Future<void> _chooseSource() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: AgriPrimaryButton(
                  label: 'Camera',
                  icon: Icons.camera_alt_rounded,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AgriPrimaryButton(
                  label: 'Gallery',
                  icon: Icons.photo_library_rounded,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyze() async {
    final imageBytes = _imageBytes;
    if (imageBytes == null) {
      showDemoMessage(context, 'Please upload a clear leaf photo first');
      return;
    }
    final selectedCrop = _crop;
    if (selectedCrop == null) {
      showDemoMessage(
        context,
        'Please select the crop before disease analysis',
      );
      return;
    }
    setState(() => _analyzing = true);
    try {
      final prediction = await DiseaseClassifierService.classify(
        imageBytes,
        expectedCrop: selectedCrop,
      );
      try {
        final unsupported = prediction.isUnsupported;
        await FirebaseBackend.saveDiseaseScan(
          selectedCrop: selectedCrop,
          detectedCrop: selectedCrop,
          growthStage: _stage,
          result: unsupported
              ? 'Possible ${prediction.disease} - low confidence'
              : prediction.disease,
          rawLabel: prediction.rawLabel,
          confidence: prediction.confidence,
        );
      } catch (_) {
        // Prediction is fully on-device and remains available when offline.
      }
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.diseaseResult,
        arguments: DiseaseScanResult(
          prediction: prediction,
          imageBytes: imageBytes,
          selectedCrop: selectedCrop,
          growthStage: _stage,
        ),
      );
    } catch (error) {
      if (mounted) {
        showDemoMessage(context, 'AI analysis failed: $error');
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: 'Disease Detection',
      subtitle: 'AI-powered plant health scanner',
      child: Column(
        children: [
          const AgriHeroCard(
            eyebrow: 'AI Plant Scanner',
            title: 'Scan Plant Disease',
            subtitle: 'Upload a leaf image to identify diseases',
            trailing: Icon(
              Icons.document_scanner_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          AgriSection(
            title: 'Upload Image',
            child: Column(
              children: [
                InkWell(
                  onTap: _chooseSource,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 165,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFCFE3D1),
                        width: 1.2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_rounded,
                                color: AppColors.primary,
                                size: 38,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tr('Tap to Upload Leaf Photo'),
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                tr('Camera or Gallery'),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        : Image.memory(_imageBytes!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _crop,
                  decoration: InputDecoration(
                    labelText: tr('Crop Type'),
                    helperText: tr(
                      'Required — the AI checks diseases only for this crop',
                    ),
                  ),
                  hint: Text(tr('Select Crop')),
                  items: _supportedCrops
                      .map(
                        (crop) => DropdownMenuItem(
                          value: crop,
                          child: Text(tr(crop)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _crop = value),
                ),
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tr(
                      'Select the crop first; automatic crop identification is not used for disease diagnosis.',
                    ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: ['Early', 'Leaf Area', 'Flowering']
                        .map(
                          (stage) => AgriChip(
                            label: stage,
                            selected: _stage == stage,
                            onTap: () => setState(() => _stage = stage),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                AgriPrimaryButton(
                  label: _analyzing ? 'Analyzing...' : 'Analyze with AI',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _analyzing ? null : _analyze,
                ),
              ],
            ),
          ),
          AgriSection(
            title: 'AI Result',
            child: Text(
              tr(
                'Disease name • Confidence score • Treatment recommendation • Organic solution',
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          AgriSection(
            title: 'Photo Tips',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('• Use one leaf with good daylight.')),
                const SizedBox(height: 6),
                Text(tr('• Keep the leaf close and in focus.')),
                const SizedBox(height: 6),
                Text(tr('• Avoid fingers, shadows and a busy background.')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
