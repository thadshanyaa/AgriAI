import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../services/disease_classifier_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class DiseaseResultScreen extends StatelessWidget {
  const DiseaseResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = ModalRoute.of(context)?.settings.arguments;
    if (result is! DiseaseScanResult) {
      return AgriPage(
        title: 'Disease Analysis Result',
        subtitle: 'AI diagnosis',
        child: AgriSection(
          title: 'No Scan Result',
          child: Column(
            children: [
              Text(tr('Please scan a leaf image first.')),
              const SizedBox(height: 14),
              AgriPrimaryButton(
                label: 'Back to Scanner',
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    final prediction = result.prediction;
    if (prediction.isUnsupported) {
      final cropWasSelected = result.selectedCrop != 'Auto Detect';
      return AgriPage(
        title: 'Disease Analysis Result',
        subtitle: 'On-device AI diagnosis',
        child: Column(
          children: [
            AgriHeroCard(
              eyebrow: 'Preliminary AI Result',
              title: cropWasSelected
                  ? '${tr('Possible Disease')}: ${tr(prediction.disease)}'
                  : '${tr('Possible Crop')}: ${tr(prediction.crop)}',
              subtitle: cropWasSelected
                  ? '${tr(result.selectedCrop)} • ${prediction.confidenceText} • ${tr('Low confidence — verify before treatment')}'
                  : '${prediction.confidenceText} • ${tr('Select the crop manually for a disease estimate')}',
              trailing: const Icon(
                Icons.manage_search_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            AgriSection(
              title: 'Scan Status',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      result.imageBytes,
                      width: 100,
                      height: 112,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        AgriInfoRow(
                          cropWasSelected ? 'Selected Crop' : 'Possible Crop',
                          cropWasSelected
                              ? result.selectedCrop
                              : prediction.crop,
                        ),
                        AgriInfoRow(
                          cropWasSelected
                              ? 'Disease Confidence'
                              : 'Model Confidence',
                          prediction.confidenceText,
                        ),
                        AgriInfoRow(
                          'Disease Result',
                          cropWasSelected
                              ? '${tr('Possible')} ${tr(prediction.disease)}'
                              : 'Select Crop First',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AgriSection(
              title: 'Top 3 Possible AI Matches',
              child: Column(
                children: prediction.topPredictions
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AgriInfoRow(
                          '${tr(item.crop)} — ${tr(item.disease)}',
                          item.confidenceText,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            AgriSection(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      tr(
                        'This is a preliminary low-confidence AI estimate, not a confirmed diagnosis. Do not apply chemicals without agriculture-officer advice.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AgriSection(
              title: 'What to do next',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('• Fill most of the photo with one leaf only.')),
                  const SizedBox(height: 7),
                  Text(
                    tr(
                      '• If the crop is supported, retake it in good daylight.',
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    tr(
                      cropWasSelected
                          ? '• Keep the damaged area visible and avoid branches or other leaves.'
                          : '• Select the crop manually when you know its name.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AgriPrimaryButton(
              label: 'Scan Another Leaf',
              icon: Icons.document_scanner_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    final healthy = prediction.isHealthy;
    final lowConfidence = prediction.isLowConfidence;
    final resultTitle = healthy
        ? '${prediction.crop} Looks Healthy'
        : prediction.disease;
    final statusText = lowConfidence
        ? 'Low confidence — retake a clear leaf photo'
        : 'Confidence: ${prediction.confidenceText}';

    return AgriPage(
      title: 'Disease Analysis Result',
      subtitle: 'On-device AI diagnosis',
      child: Column(
        children: [
          AgriHeroCard(
            eyebrow: healthy ? 'Healthy Plant' : 'AI Scan Complete',
            title: resultTitle,
            subtitle: '${prediction.crop} • $statusText',
            trailing: Icon(
              healthy ? Icons.verified_rounded : Icons.biotech_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          AgriSection(
            title: 'Detection Details',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    result.imageBytes,
                    width: 100,
                    height: 112,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      AgriInfoRow('Detected Crop', prediction.crop),
                      AgriInfoRow('Disease', prediction.disease),
                      AgriInfoRow('Confidence', prediction.confidenceText),
                      if (prediction.usedExpectedCrop)
                        AgriInfoRow(
                          'Selected Crop Match',
                          '${(prediction.cropEvidence * 100).toStringAsFixed(1)}%',
                        ),
                      AgriInfoRow('Growth Stage', result.growthStage),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AgriSection(
            title: 'Top 3 AI Matches',
            child: Column(
              children: prediction.topPredictions
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AgriInfoRow(
                        '${item.crop} — ${item.disease}',
                        item.confidenceText,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          AgriSection(
            title: healthy ? 'Plant Care' : 'Recommended Next Steps',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: healthy
                  ? [
                      Text(tr('• Continue regular crop monitoring.')),
                      const SizedBox(height: 6),
                      Text(tr('• Maintain balanced water and nutrition.')),
                    ]
                  : [
                      Text(tr('• Isolate the affected plant when possible.')),
                      const SizedBox(height: 6),
                      Text(tr('• Remove severely affected leaves safely.')),
                      const SizedBox(height: 6),
                      Text(tr('• Avoid spreading tools between plants.')),
                      const SizedBox(height: 6),
                      Text(
                        tr(
                          '• Confirm treatment with an agriculture officer before applying pesticides.',
                        ),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Dataset test accuracy: 92.55%. Real field-photo accuracy varies with lighting, focus and background.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
