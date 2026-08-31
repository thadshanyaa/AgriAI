import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ThemeController {
  static const _storageKey = 'dark_mode_enabled';
  static final ValueNotifier<ThemeMode> current = ValueNotifier(
    ThemeMode.light,
  );

  static bool get isDark => current.value == ThemeMode.dark;

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    current.value = preferences.getBool(_storageKey) == true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool enabled) async {
    current.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_storageKey, enabled);
  }
}
