import 'package:flutter/material.dart';
import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/crop_recommendation_service.dart';
import '../services/firebase_backend.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class CropAdvisoryScreen extends StatefulWidget {
  const CropAdvisoryScreen({super.key});

  @override
  State<CropAdvisoryScreen> createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends State<CropAdvisoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _acres = TextEditingController(text: '5.5');
  String _district = 'Trincomalee';
  String _soil = 'Loamy';
  String _season = 'Rainy Season';
  String _water = 'Irrigation';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDistrict();
  }

  Future<void> _loadSavedDistrict() async {
    final district = await FirebaseBackend.currentDistrict();
    if (mounted && CropRecommendationService.districts.contains(district)) {
      setState(() => _district = district);
    }
  }

  @override
  void dispose() {
    _acres.dispose();
    super.dispose();
  }

  Future<void> _getRecommendation() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final request = CropRecommendationRequest(
        district: _district,
        soil: _soil,
        season: _season,
        waterSource: _water,
        acres: double.parse(_acres.text),
      );
      WeatherReport? weather;
      try {
        weather = await WeatherService.fetch(_district);
      } catch (_) {
        weather = null;
      }
      final recommendation = CropRecommendationService.recommend(
        request,
        weather: weather,
      );
      final best = recommendation.best;
      await FirebaseBackend.saveCropRecommendation(
        district: _district,
        soil: _soil,
        season: _season,
        waterSource: _water,
        acres: request.acres,
        recommendedCrop: best.crop.name,
        confidence: best.score,
        expectedYield: best.expectedYield,
        expectedProfit: best.expectedProfit,
        riskLevel: best.riskLevel,
        waterRequirement: best.waterRequirement,
        alternatives: recommendation.rankedCrops
            .take(5)
            .map((item) => {'crop': item.crop.name, 'score': item.score})
            .toList(),
        liveWeatherUsed: recommendation.liveWeatherUsed,
      );
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.aiRecommendation,
          arguments: recommendation,
        );
      }
    } catch (error) {
      if (mounted) {
        showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: 'Crop Advisory',
      subtitle: 'AI crop recommendation for your farm',
      child: Column(
        children: [
          const AgriHeroCard(
            eyebrow: 'Smart Crop Advisor',
            title: 'Find Best Crop',
            subtitle: 'Based on soil, season and your farm location',
            trailing: Icon(Icons.eco_rounded, color: Colors.white, size: 42),
          ),
          AgriSection(
            title: 'Farm Details',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(_district),
                    initialValue: _district,
                    decoration: InputDecoration(
                      labelText: tr('Location / District'),
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                    items: CropRecommendationService.districts
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(tr(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _district = value ?? _district),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('Soil Type'),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: ['Sandy', 'Clay', 'Loamy']
                        .map(
                          (soil) => AgriChip(
                            label: soil,
                            selected: _soil == soil,
                            onTap: () => setState(() => _soil = soil),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _season,
                          decoration: InputDecoration(labelText: tr('Season')),
                          items: ['Rainy Season', 'Dry Season']
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(tr(item)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _season = value ?? _season),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _water,
                          decoration: InputDecoration(
                            labelText: tr('Water Source'),
                          ),
                          items: ['Irrigation', 'Rain Water', 'Well']
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(tr(item)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _water = value ?? _water),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _acres,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: tr('Land Size (Acres)'),
                      prefixIcon: Icon(Icons.landscape_rounded),
                    ),
                    validator: (value) {
                      final acres = double.tryParse(value ?? '');
                      return acres == null || acres <= 0
                          ? tr('Enter acres')
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AgriPrimaryButton(
                    label: _loading
                        ? 'Analyzing farm and weather...'
                        : 'Get AI Recommendation',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: _loading ? null : _getRecommendation,
                  ),
                ],
              ),
            ),
          ),
          AgriSection(
            title: 'AI Output Preview',
            child: Text(
              tr(
                'Recommended crop • Expected yield • Risk level • Water requirement • Profit prediction',
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
