import 'package:flutter/material.dart';
import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/firebase_backend.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<WeatherReport> _weather;

  static const _features = [
    (Icons.eco_rounded, 'Crop', AppRoutes.cropAdvisory),
    (Icons.bug_report_rounded, 'Disease', AppRoutes.diseaseDetection),
    (Icons.cloud_rounded, 'Weather', AppRoutes.weather),
    (Icons.savings_rounded, 'Profit', AppRoutes.profitPlanner),
    (Icons.agriculture_rounded, 'My Farm', AppRoutes.farmManagement),
    (Icons.analytics_rounded, 'Reports', AppRoutes.reports),
    (Icons.storefront_rounded, 'Market', AppRoutes.marketPrices),
    (Icons.person_rounded, 'Profile', AppRoutes.profile),
  ];

  @override
  void initState() {
    super.initState();
    _weather = _loadWeather();
  }

  Future<WeatherReport> _loadWeather() async {
    final district = await FirebaseBackend.currentDistrict();
    return WeatherService.fetch(district);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _firstName(Map<String, dynamic>? profile) {
    final fullName = (profile?['fullName'] as String? ?? '').trim();
    if (fullName.isEmpty) return tr('Farmer');
    return fullName.split(RegExp(r'\s+')).first;
  }

  String _initial(Map<String, dynamic>? profile) {
    final name = _firstName(profile).trim();
    return name.isEmpty ? 'F' : name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirebaseBackend.profileStream(),
      builder: (context, profileSnapshot) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseBackend.notificationsStream(),
        builder: (context, notificationSnapshot) {
          final profile = profileSnapshot.data;
          final notifications =
              notificationSnapshot.data ?? const <Map<String, dynamic>>[];
          final unread = notifications
              .where((item) => item['isRead'] != true)
              .length;
          final name = _firstName(profile);

          return FutureBuilder<WeatherReport>(
            future: _weather,
            builder: (context, weatherSnapshot) {
              final weather = weatherSnapshot.data;
              final weatherText = weather != null
                  ? '${weather.temperature.round()}°C • ${tr(WeatherService.condition(weather.weatherCode))} • ${tr(weather.district)}'
                  : weatherSnapshot.hasError
                  ? tr('Weather unavailable')
                  : tr('Loading weather...');

              return AgriPage(
                title: 'AgriAI',
                subtitle: 'Your smart farming dashboard',
                showBack: false,
                actions: [
                  IconButton(
                    tooltip: tr('Refresh'),
                    onPressed: () => setState(() {
                      _weather = _loadWeather();
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    tooltip: tr('Notifications'),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    icon: unread == 0
                        ? const Icon(Icons.notifications_none_rounded)
                        : Badge(
                            label: Text(unread > 99 ? '99+' : '$unread'),
                            child: const Icon(Icons.notifications_none_rounded),
                          ),
                  ),
                ],
                child: Column(
                  children: [
                    AgriHeroCard(
                      eyebrow: _greeting(),
                      title: '${tr('Welcome')}, $name',
                      subtitle: weatherText,
                      trailing: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Text(
                          _initial(profile),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _features.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.45,
                          ),
                      itemBuilder: (context, index) {
                        final feature = _features[index];
                        return _HomeFeature(
                          icon: feature.$1,
                          label: feature.$2,
                          onTap: () => Navigator.pushNamed(context, feature.$3),
                        );
                      },
                    ),
                    AgriSection(
                      title: 'AI Farming Tip',
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr(
                                'Water crops early morning to reduce evaporation and improve absorption.',
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.assistant),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(tr('Ask AgriAI Assistant')),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeFeature extends StatelessWidget {
  const _HomeFeature({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 29),
              const Spacer(),
              Text(
                tr(label),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
