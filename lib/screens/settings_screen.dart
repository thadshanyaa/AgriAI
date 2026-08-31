import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/firebase_backend.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/agri_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _notificationsKey = 'notifications_enabled';
  static const _gpsKey = 'gps_enabled';
  static const _cameraKey = 'camera_enabled';

  late AppLanguage _language;
  bool _darkMode = false;
  bool _notifications = true;
  bool _gps = false;
  bool _camera = false;

  @override
  void initState() {
    super.initState();
    _language = AppLanguageController.current.value;
    _darkMode = ThemeController.isDark;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final notificationStatus = await Permission.notification.status;
    final locationStatus = await Permission.locationWhenInUse.status;
    final cameraStatus = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _notifications =
          preferences.getBool(_notificationsKey) ??
          notificationStatus.isGranted;
      _gps = preferences.getBool(_gpsKey) ?? locationStatus.isGranted;
      _camera = preferences.getBool(_cameraKey) ?? cameraStatus.isGranted;
    });
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _darkMode = value);
    await ThemeController.setDarkMode(value);
  }

  Future<void> _setNotifications(bool value) async {
    var enabled = false;
    try {
      enabled = await NotificationService.setEnabled(value);
    } catch (_) {
      enabled = false;
    }
    if (!enabled && value && mounted) {
      await _showPermissionDialog(
        await Permission.notification.isPermanentlyDenied,
      );
    }
    if (mounted) setState(() => _notifications = enabled);
  }

  Future<void> _setPermission({
    required Permission permission,
    required String preferenceKey,
    required bool value,
    required ValueChanged<bool> update,
  }) async {
    var enabled = false;
    if (value) {
      final status = await permission.request();
      enabled = status.isGranted || status.isLimited;
      if (!enabled && mounted) {
        await _showPermissionDialog(status.isPermanentlyDenied);
      }
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(preferenceKey, enabled);
    if (mounted) setState(() => update(enabled));
  }

  Future<void> _showPermissionDialog(bool permanentlyDenied) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Permission Required')),
        content: Text(
          tr(
            permanentlyDenied
                ? 'Permission is blocked. Open phone settings to enable it.'
                : 'Permission was not granted. You can try again.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('Cancel')),
          ),
          if (permanentlyDenied)
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await openAppSettings();
              },
              child: Text(tr('Open Phone Settings')),
            ),
        ],
      ),
    );
  }

  Future<void> _showPrivacyOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Privacy & Permissions'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  'AgriAI stores your account, farm history and saved results in Firebase. Camera and location are used only when you choose those features.',
                ),
              ),
              const SizedBox(height: 16),
              AgriPrimaryButton(
                label: 'Open Phone Settings',
                icon: Icons.settings_rounded,
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await openAppSettings();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_notificationsKey, _notifications),
      preferences.setBool(_gpsKey, _gps),
      preferences.setBool(_cameraKey, _camera),
    ]);
    if (mounted) showDemoMessage(context, 'Settings saved');
  }

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: 'Settings',
      subtitle: 'Customize your AgriAI experience',
      child: Column(
        children: [
          const AgriHeroCard(
            eyebrow: 'App Preferences',
            title: 'Settings',
            subtitle: 'Control language, privacy and permissions',
            trailing: Icon(Icons.tune_rounded, color: Colors.white, size: 42),
          ),
          AgriSection(
            child: Column(
              children: [
                DropdownButtonFormField<AppLanguage>(
                  initialValue: _language,
                  decoration: InputDecoration(
                    labelText: tr('Language'),
                    prefixIcon: const Icon(Icons.language_rounded),
                  ),
                  items: AppLanguage.values
                      .map(
                        (language) => DropdownMenuItem(
                          value: language,
                          child: Text(language.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _language = value);
                    await AppLanguageController.setLanguage(value);
                    try {
                      await FirebaseBackend.updateLanguage(value.code);
                    } catch (error) {
                      if (context.mounted) {
                        showDemoMessage(
                          context,
                          FirebaseBackend.friendlyMessage(error),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                _SettingSwitch(
                  title: 'Dark Mode',
                  icon: Icons.dark_mode_rounded,
                  value: _darkMode,
                  onChanged: _setDarkMode,
                ),
                _SettingSwitch(
                  title: 'Notifications',
                  icon: Icons.notifications_rounded,
                  value: _notifications,
                  onChanged: _setNotifications,
                ),
                _SettingSwitch(
                  title: 'GPS Permission',
                  icon: Icons.location_on_rounded,
                  value: _gps,
                  onChanged: (value) => _setPermission(
                    permission: Permission.locationWhenInUse,
                    preferenceKey: _gpsKey,
                    value: value,
                    update: (enabled) => _gps = enabled,
                  ),
                ),
                _SettingSwitch(
                  title: 'Camera Permission',
                  icon: Icons.camera_alt_rounded,
                  value: _camera,
                  onChanged: (value) => _setPermission(
                    permission: Permission.camera,
                    preferenceKey: _cameraKey,
                    value: value,
                    update: (enabled) => _camera = enabled,
                  ),
                ),
                const SizedBox(height: 6),
                AgriActionTile(
                  title: 'Privacy',
                  subtitle: 'Manage your data preferences',
                  icon: Icons.privacy_tip_rounded,
                  onTap: _showPrivacyOptions,
                ),
                const SizedBox(height: 8),
                AgriActionTile(
                  title: 'Help & Support',
                  subtitle: 'Open the AgriAI help center',
                  icon: Icons.help_rounded,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.help),
                ),
                const SizedBox(height: 8),
                AgriActionTile(
                  title: 'About App',
                  subtitle: 'Version 1.6.0',
                  icon: Icons.info_rounded,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AgriPrimaryButton(
            label: 'Save Settings',
            icon: Icons.save_rounded,
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(
        tr(title),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
