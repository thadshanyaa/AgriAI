import 'package:flutter/material.dart';
import '../app_routes.dart';
import '../localization/app_language.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late int _selected;

  static const _languages = [
    ('🇬🇧', 'English', 'Smart farming in English'),
    ('🇱🇰', 'தமிழ்', 'தமிழில் விவசாய ஆலோசனை'),
    ('🇱🇰', 'සිංහල', 'ස්මාර්ට් ගොවිතැන් උපදෙස්'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = AppLanguageController.current.value.index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FFF6), AppColors.backgroundDeep],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              children: [
                Image.asset('assets/images/agriai_logo.png', width: 150),
                Text(
                  tr('Choose Language'),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Select your preferred language'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: _languages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _languages[index];
                      final selected = _selected == index;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selected = index);
                            AppLanguageController.setLanguage(
                              AppLanguage.values[index],
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xFFDDEADD),
                                width: selected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.background,
                                  child: Text(item.$1),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.$2,
                                        style: const TextStyle(
                                          color: AppColors.text,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        item.$3,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                InkWell(
                  onTap: () => showDemoMessage(
                    context,
                    '${_languages[_selected].$2} language preview',
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pause_circle_filled_rounded,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          tr('Tap to hear language preview'),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AgriPrimaryButton(
                  label: 'Continue',
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
