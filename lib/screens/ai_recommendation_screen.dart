import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/crop_recommendation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class AiRecommendationScreen extends StatelessWidget {
  const AiRecommendationScreen({super.key});

  static final _number = NumberFormat('#,##0');

  String _money(double value) => 'Rs. ${_number.format(value)}';

  @override
  Widget build(BuildContext context) {
    final recommendation =
        ModalRoute.of(context)?.settings.arguments as CropRecommendationBundle?;
    if (recommendation == null) {
      return AgriPage(
        title: 'AI Recommendation',
        subtitle: 'Best crop recommendation for your land',
        child: AgriSection(
          title: 'No recommendation yet',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Enter your farm details to generate a recommendation.')),
              const SizedBox(height: 14),
              AgriPrimaryButton(
                label: 'Open Crop Advisory',
                icon: Icons.eco_rounded,
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.cropAdvisory,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final best = recommendation.best;
    final request = recommendation.request;
    return AgriPage(
      title: 'AI Recommendation',
      subtitle: 'Best crop recommendation for your land',
      child: Column(
        children: [
          AgriHeroCard(
            eyebrow: 'Analysis Complete',
            title: '${best.crop.emoji} ${tr(best.crop.name)}',
            subtitle: '${tr('Suitability Score')}: ${best.score}%',
            trailing: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          AgriSection(
            title: 'Recommendation Summary',
            child: Column(
              children: [
                AgriInfoRow('District', tr(request.district)),
                AgriInfoRow('Crop', '${best.crop.emoji} ${tr(best.crop.name)}'),
                AgriInfoRow(
                  'Expected Yield',
                  '${_number.format(best.expectedYield)} kg',
                ),
                AgriInfoRow('Water Requirement', tr(best.waterRequirement)),
                AgriInfoRow('Estimated Investment', _money(best.investment)),
                AgriInfoRow('Estimated Revenue', _money(best.revenue)),
                AgriInfoRow(
                  'Estimated Profit',
                  _money(best.expectedProfit),
                  valueColor: best.expectedProfit >= 0
                      ? AppColors.primary
                      : Colors.red,
                ),
                AgriInfoRow(
                  'Risk Level',
                  tr(best.riskLevel),
                  valueColor: best.riskLevel == 'Low'
                      ? AppColors.primary
                      : best.riskLevel == 'Medium'
                      ? Colors.orange.shade800
                      : Colors.red,
                ),
              ],
            ),
          ),
          AgriSection(
            title: 'Why this crop?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final reason in best.reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tr(reason))),
                      ],
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  recommendation.liveWeatherUsed
                      ? tr('Live 7-day weather included in this score.')
                      : tr('Weather was unavailable; farm details were used.'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          AgriSection(
            title: 'Top 5 Crops',
            child: Column(
              children: recommendation.rankedCrops
                  .take(5)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                        _RankedCropRow(rank: entry.key + 1, item: entry.value),
                  )
                  .toList(),
            ),
          ),
          AgriSection(
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                tr('View all 25 crop rankings'),
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                tr('Every trained crop is checked for your farm.'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              children: recommendation.rankedCrops
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                        _RankedCropRow(rank: entry.key + 1, item: entry.value),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          AgriPrimaryButton(
            label: 'Open Profit Planner',
            icon: Icons.trending_up_rounded,
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.profitPlanner),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.weather),
            icon: const Icon(Icons.cloud_rounded),
            label: Text(tr('Review 7-Day Weather')),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Yield and profit are estimates. Confirm soil tests, input costs and market prices before planting.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RankedCropRow extends StatelessWidget {
  const _RankedCropRow({required this.rank, required this.item});

  final int rank;
  final CropRecommendationItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank.',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(item.crop.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              tr(item.crop.name),
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.backgroundDeep,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${item.score}%',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
