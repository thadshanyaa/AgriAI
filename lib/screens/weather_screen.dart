import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/firebase_backend.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load weather. Check your internet connection.';
      });
    }
  }

  IconData _weatherIcon(int code) {
    if (code == 0 || code == 1) return Icons.wb_sunny_rounded;
    if (code == 2 || code == 3) return Icons.cloud_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    if (code >= 51) return Icons.water_drop_rounded;
    return Icons.cloud_rounded;
  }

  List<String> _advice(WeatherReport report) {
    final advice = <String>[];
    if (report.today.rainChance >= 60) {
      advice.add(
        'Rain is likely. Delay irrigation and protect harvested crops.',
      );
    } else {
      advice.add('Low rain chance. Irrigate crops early in the morning.');
    }
    if (report.windSpeed >= 25) {
      advice.add('Strong wind expected. Avoid pesticide spraying.');
    } else {
      advice.add('Wind conditions are suitable for normal field work.');
    }
    if (report.today.uvIndex >= 7) {
      advice.add('High UV level. Avoid long field work around midday.');
    }
    return advice;
  }

  Widget _content() {
    final report = _report;
    if (_loading && report == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
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

    final today = report.today;
    return Column(
      children: [
        AgriHeroCard(
          eyebrow: "Today's Weather",
          title: '${report.temperature.round()}°C',
          subtitle:
              '${tr(WeatherService.condition(report.weatherCode))} • ${tr(report.district)}',
          trailing: Icon(
            _weatherIcon(report.weatherCode),
            color: Colors.amber,
            size: 52,
          ),
        ),
        AgriSection(
          title: 'Weather Details',
          child: Column(
            children: [
              AgriInfoRow('Humidity', '${report.humidity}%'),
              AgriInfoRow('Rain Chance', '${today.rainChance}%'),
              AgriInfoRow(
                'Wind Speed',
                '${report.windSpeed.toStringAsFixed(1)} km/h',
              ),
              AgriInfoRow('UV Index', today.uvIndex.toStringAsFixed(1)),
              AgriInfoRow(
                'Sunrise',
                DateFormat('hh:mm a').format(today.sunrise),
              ),
            ],
          ),
        ),
        AgriSection(
          title: 'Farming Advice',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _advice(
              report,
            ).map((item) => _WeatherAdvice(item)).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: 'Weather Advisory',
      subtitle: 'Real-time weather insights for your farm',
      actions: [
        IconButton(
          tooltip: tr('Refresh Forecast'),
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        children: [
          _content(),
          const SizedBox(height: 14),
          AgriPrimaryButton(
            label: 'View 7-Day Forecast',
            icon: Icons.calendar_month_rounded,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.forecast),
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

class _WeatherAdvice extends StatelessWidget {
  const _WeatherAdvice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '✓ ${tr(text)}',
        style: const TextStyle(color: AppColors.primaryDark, fontSize: 12),
      ),
    );
  }
}
