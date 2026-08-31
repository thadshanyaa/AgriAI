import 'dart:async';
import 'package:flutter/material.dart';
import '../app_routes.dart';
import '../localization/app_language.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppLanguageController.hasSavedLanguage
              ? AppRoutes.login
              : AppRoutes.language,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash_bg.png', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.45),
                  const Color(0xFFF7FFF2).withValues(alpha: 0.96),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: Column(
                children: [
                  const Spacer(),
                  Image.asset('assets/images/agriai_logo.png', width: 215),
                  const SizedBox(height: 10),
                  Text(
                    tr('Empowering Farmers\nThrough Artificial Intelligence'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(flex: 2),
                  Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Image.asset('assets/images/tractor_icon.png'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr('Preparing your farming assistant...'),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 13),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) {
                      final value = _progressController.value;
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: value,
                              color: AppColors.primary,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${(value * 100).round()}%',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SplashFeature(Icons.eco_rounded, 'AI Advisory'),
                      _SplashFeature(Icons.cloud_rounded, 'Weather'),
                      _SplashFeature(Icons.bug_report_rounded, 'Disease'),
                      _SplashFeature(Icons.insights_rounded, 'Profit'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('Grow Smart • Grow Better • Grow Together'),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashFeature extends StatelessWidget {
  const _SplashFeature(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 19),
          const SizedBox(height: 3),
          Text(
            tr(label),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
