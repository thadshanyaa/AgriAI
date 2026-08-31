import 'package:flutter/material.dart';
import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/biometric_auth_service.dart';
import '../services/firebase_backend.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _changePassword(String profileEmail) async {
    final email = profileEmail.trim().isNotEmpty
        ? profileEmail.trim()
        : FirebaseBackend.currentUser?.email ?? '';
    if (email.isEmpty) {
      showDemoMessage(context, 'Add a verified email to reset your password.');
      return;
    }
    try {
      await FirebaseBackend.sendPasswordResetEmail(
        email,
        languageCode: AppLanguageController.current.value.code,
      );
      if (mounted) {
        showDemoMessage(context, 'Password reset link sent to $email');
      }
    } catch (error) {
      if (mounted) {
        showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
      }
    }
  }

  Future<void> _editProfile({
    required String initialName,
    required String initialPhone,
    required String initialEmail,
  }) async {
    final name = TextEditingController(text: initialName);
    final phone = TextEditingController(text: initialPhone);
    final email = TextEditingController(text: initialEmail);
    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Edit Profile')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: tr('Full Name')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                decoration: InputDecoration(labelText: tr('Phone')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: tr('Email')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('Save')),
          ),
        ],
      ),
    );
    if (updated == true && mounted) {
      try {
        final verificationSent = await FirebaseBackend.updateProfile(
          fullName: name.text.trim().isEmpty ? initialName : name.text,
          phone: phone.text.trim().isEmpty ? initialPhone : phone.text,
          contactEmail: email.text.trim(),
        );
        if (mounted) {
          showDemoMessage(
            context,
            verificationSent
                ? 'Verification email sent. Open the link, then use your email for login and password reset.'
                : 'Profile updated',
          );
        }
      } catch (error) {
        if (mounted) {
          showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
        }
      }
    }
    name.dispose();
    phone.dispose();
    email.dispose();
  }

  Future<void> _signOut() async {
    await BiometricAuthService.setEnabled(false);
    await FirebaseBackend.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirebaseBackend.profileStream(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?['fullName'] as String? ?? 'Farmer Name';
        final phone = profile?['phone'] as String? ?? '+94 77 XXX XXXX';
        final email = profile?['contactEmail'] as String? ?? '';
        final district = profile?['district'] as String? ?? 'Trincomalee';
        void edit() => _editProfile(
          initialName: name,
          initialPhone: phone,
          initialEmail: email,
        );

        return AgriPage(
          title: 'Profile',
          subtitle: 'Manage your farmer account',
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
          child: Column(
            children: [
              AgriHeroCard(
                title: name,
                subtitle: phone,
                trailing: CircleAvatar(
                  radius: 31,
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isEmpty ? 'F' : name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              AgriSection(
                title: 'Personal Information',
                child: Column(
                  children: [
                    AgriInfoRow(
                      'Email',
                      email.isEmpty ? 'Not provided' : email,
                    ),
                    AgriInfoRow(
                      'Language',
                      AppLanguageController.current.value.label,
                    ),
                    AgriInfoRow('District', district),
                    const AgriInfoRow('Farm Size', '5.5 Acres'),
                    const AgriInfoRow('Main Crop', 'Rice'),
                  ],
                ),
              ),
              AgriSection(
                title: 'Account Actions',
                child: Column(
                  children: [
                    AgriActionTile(
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      icon: Icons.edit_rounded,
                      onTap: edit,
                    ),
                    const SizedBox(height: 8),
                    AgriActionTile(
                      title: 'Change Password',
                      subtitle: 'Keep your account secure',
                      icon: Icons.password_rounded,
                      onTap: () => _changePassword(email),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AgriPrimaryButton(
                label: 'Edit Profile',
                icon: Icons.edit_rounded,
                onPressed: edit,
              ),
              TextButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: Text(tr('Sign Out')),
              ),
            ],
          ),
        );
      },
    );
  }
}
