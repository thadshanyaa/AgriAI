import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_language.dart';
import '../widgets/agri_ui.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _showDocument(
    BuildContext context,
    String title,
    String content,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(title)),
        content: SingleChildScrollView(child: Text(tr(content))),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showDemoMessage(context, 'Unable to open this service.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: 'About AgriAI',
      subtitle: 'AI Smart Farming Platform',
      child: Column(
        children: [
          AgriHeroCard(
            title: 'AgriAI',
            subtitle: 'Version 1.6.0',
            trailing: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/images/agriai_logo.png',
                width: 58,
                height: 58,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const AgriSection(
            child: Column(
              children: [
                AgriInfoRow('Developed By', 'AgriAI Team'),
                AgriInfoRow('Technology', 'Flutter + Firebase + TensorFlow'),
                AgriInfoRow('Languages', 'English • Tamil • Sinhala'),
              ],
            ),
          ),
          AgriSection(
            child: Column(
              children: [
                AgriActionTile(
                  title: 'Privacy Policy',
                  subtitle: 'View how your information is protected',
                  icon: Icons.privacy_tip_rounded,
                  onTap: () => _showDocument(
                    context,
                    'Privacy Policy',
                    'AgriAI stores account details, farm records and saved results in Firebase. Camera, microphone and location are accessed only after permission and only for the feature you choose. Do not upload confidential images.',
                  ),
                ),
                const SizedBox(height: 8),
                AgriActionTile(
                  title: 'Terms & Conditions',
                  subtitle: 'View application terms',
                  icon: Icons.description_rounded,
                  onTap: () => _showDocument(
                    context,
                    'Terms & Conditions',
                    'AgriAI predictions, weather advice and profit figures are estimates for educational support. Confirm important farming and pesticide decisions with a qualified agriculture officer.',
                  ),
                ),
                const SizedBox(height: 8),
                AgriActionTile(
                  title: 'Official Website',
                  subtitle: 'Department of Agriculture Sri Lanka',
                  icon: Icons.public_rounded,
                  onTap: () =>
                      _launch(context, Uri.parse('https://doa.gov.lk/')),
                ),
                const SizedBox(height: 8),
                AgriActionTile(
                  title: 'Contact',
                  subtitle: '1920service@doa.gov.lk',
                  icon: Icons.email_rounded,
                  onTap: () => _launch(
                    context,
                    Uri(scheme: 'mailto', path: '1920service@doa.gov.lk'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AgriPrimaryButton(
            label: 'Visit Website',
            icon: Icons.open_in_browser_rounded,
            onPressed: () => _launch(context, Uri.parse('https://doa.gov.lk/')),
          ),
        ],
      ),
    );
  }
}
