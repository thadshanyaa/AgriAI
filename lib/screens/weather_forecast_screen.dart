import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../localization/app_language.dart';
import '../services/crop_catalog.dart';
import '../services/firebase_backend.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({super.key});

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  WeatherReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool notify = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final district = await FirebaseBackend.currentDistrict();
      final report = await WeatherService.fetch(district);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
      if (notify) showDemoMessage(context, 'Forecast updated');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load weather. Check your internet connection.';
      });
    }
  }

  IconData _icon(int code) {
    if (code <= 1) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.cloud_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    if (code >= 51) return Icons.water_drop_rounded;
    return Icons.cloud_rounded;
  }

  List<String> _recommendations(WeatherReport report) {
    final tomorrow = report.days.length > 1 ? report.days[1] : report.today;
    final wettest = report.days.reduce(
      (first, second) => first.rainChance >= second.rainChance ? first : second,
    );
    return [
      tomorrow.rainChance >= 55
          ? 'Rain is likely tomorrow. Reduce irrigation.'
          : 'Irrigate crops tomorrow morning.',
      'Highest rain chance is ${wettest.rainChance}% on ${DateFormat('EEEE').format(wettest.date)}.',
      wettest.maximumWindSpeed >= 25
          ? 'Avoid spraying on windy forecast days.'
          : 'Wind forecast is suitable for normal farm work.',
    ];
  }

  Widget _body() {
    final report = _report;
    if (_loading && report == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 52),
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null && report == null) {
      return AgriSection(
        child: Column(
          children: [
            Text(tr(_error!), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr('Try Again')),
            ),
          ],
        ),
      );
    }
    if (report == null) return const SizedBox.shrink();

    return Column(
      children: [
        AgriHeroCard(
          eyebrow: "Today's Weather",
          title: '${report.temperature.round()}°C',
          subtitle:
              '${tr(WeatherService.condition(report.weatherCode))} • ${tr(report.district)} • ${report.today.rainChance}% ${tr('Rain Chance')}',
          trailing: Icon(
            _icon(report.weatherCode),
            color: Colors.amber,
            size: 52,
          ),
        ),
        AgriSection(
          title: 'Next 5 Days - Best Crop',
          child: SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: report.days.take(5).length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final day = report.days[index];
                final best = CropCatalog.forDay(day).first;
                return Container(
                  width: 126,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _icon(day.weatherCode),
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const Spacer(),
                          Text(
                            '${day.rainChance}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        tr(DateFormat('EEE').format(day.date)),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${day.maximumTemperature.round()}° / ${day.minimumTemperature.round()}°',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${best.crop.emoji} ${tr(best.crop.name)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${best.score}% ${tr('suitable')}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        AgriSection(
          title: 'Detailed 7-Day Crop Advice',
          child: Column(
            children: report.days
                .map(
                  (day) => _DailyCropRecommendation(
                    day: day,
                    icon: _icon(day.weatherCode),
                  ),
                )
                .toList(),
          ),
        ),
        AgriSection(
          title: 'All 25 Crops - Weekly Suitability',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  'Weather suitability uses temperature, rain and wind. Confirm soil, season and local advice before planting.',
                ),
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CropCatalog.forWeek(report.days)
                        .map(
                          (item) => SizedBox(
                            width: itemWidth,
                            child: _WeeklyCropSuitability(item: item),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        AgriSection(
          title: 'Farming Recommendations',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _recommendations(report)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• ${tr(item)}'),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: '7-Day Weather Forecast',
      subtitle: 'Live weather forecast and farming advice',
      child: Column(
        children: [
          _body(),
          const SizedBox(height: 14),
          AgriPrimaryButton(
            label: 'Refresh Forecast',
            icon: Icons.refresh_rounded,
            onPressed: _loading ? null : () => _load(notify: true),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Weather data: Open-Meteo'),
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DailyCropRecommendation extends StatelessWidget {
  const _DailyCropRecommendation({required this.day, required this.icon});

  final WeatherDay day;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final recommendations = CropCatalog.forDay(day).take(4).toList();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(DateFormat('EEEE').format(day.date)),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(day.date),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${day.maximumTemperature.round()}°/${day.minimumTemperature.round()}° • ${day.rainChance}% ${tr('rain')}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tr('Recommended from your 25 crops'),
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: recommendations
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      '${item.crop.emoji} ${tr(item.crop.name)} ${item.score}%',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCropSuitability extends StatelessWidget {
  const _WeeklyCropSuitability({required this.item});

  final CropSuitability item;

  Color get _color {
    if (item.score >= 78) return AppColors.primary;
    if (item.score >= 62) return const Color(0xFF6A9E2E);
    if (item.score >= 45) return AppColors.warning;
    return const Color(0xFFB85C4B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Text(item.crop.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(item.crop.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  tr(item.level),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _color, fontSize: 8.5),
                ),
              ],
            ),
          ),
          Text(
            '${item.score}%',
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
