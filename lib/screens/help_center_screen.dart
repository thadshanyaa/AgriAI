import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/firebase_backend.dart';
import '../widgets/agri_ui.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showDemoMessage(context, 'Unable to open this service.');
    }
  }

  Future<void> _showFaqs(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Frequently Asked Questions')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Faq(
                question: 'How do I detect a crop disease?',
                answer:
                    'Open Disease Detection, upload one clear leaf photo and tap Analyze with AI.',
              ),
              _Faq(
                question: 'Does AgriAI work without internet?',
                answer:
                    'Disease detection works on the phone. Weather, news and Firebase features require internet.',
              ),
              _Faq(
                question: 'Why is a crop shown as not supported?',
                answer:
                    'The image did not confidently match one of the 25 trained crops. Retake a clear photo or use a supported crop.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final feedback = TextEditingController();
    final email = TextEditingController(
      text: FirebaseBackend.currentUser?.email ?? '',
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Send Feedback')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: tr('Your email (optional)'),
                  helperText: tr('Add it to receive a copy of your feedback.'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedback,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: tr('Your feedback'),
                  hintText: tr('Tell us what should be improved...'),
                ),
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
            child: Text(tr('Submit')),
          ),
        ],
      ),
    );
    if (submitted == true && context.mounted) {
      try {
        await FirebaseBackend.saveFeedback(
          feedback.text,
          contactEmail: email.text,
        );
        if (context.mounted) {
          final optionalEmail = email.text.trim();
          final mailUri = Uri(
            scheme: 'mailto',
            path: 'thadshanyaa@gmail.com',
            queryParameters: {
              'subject': 'AgriAI user feedback',
              if (optionalEmail.isNotEmpty) 'cc': optionalEmail,
              'body': feedback.text.trim(),
            },
          );
          final opened = await launchUrl(
            mailUri,
            mode: LaunchMode.externalApplication,
          );
          if (context.mounted) {
            showDemoMessage(
              context,
              opened
                  ? 'Feedback saved. Tap Send in your email app.'
                  : 'Feedback saved to AgriAI support.',
            );
          }
        }
      } catch (error) {
        if (context.mounted) {
          showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
        }
      }
    }
    feedback.dispose();
    email.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.quiz_rounded,
        'FAQs',
        'Common farming questions',
        () => _showFaqs(context),
      ),
      (
        Icons.play_circle_rounded,
        'Video Tutorials',
        'Learn with step-by-step guides',
        () => _launch(
          context,
          Uri.parse(
            'https://www.youtube.com/results?search_query=Department+of+Agriculture+Sri+Lanka+farming+tutorials',
          ),
        ),
      ),
      (
        Icons.auto_awesome_rounded,
        'AI Chat Assistant',
        'Ask farming questions instantly',
        () => Navigator.pushNamed(context, AppRoutes.assistant),
      ),
      (
        Icons.account_balance_rounded,
        'Agriculture Officer',
        'Call Sri Lanka agriculture advisory service 1920',
        () => _launch(context, Uri(scheme: 'tel', path: '1920')),
      ),
      (
        Icons.feedback_rounded,
        'Feedback',
        'Share your suggestions',
        () => _sendFeedback(context),
      ),
      (
        Icons.support_agent_rounded,
        'Customer Support',
        'Email agriculture advisory support',
        () => _launch(
          context,
          Uri(
            scheme: 'mailto',
            path: '1920service@doa.gov.lk',
            queryParameters: {'subject': 'AgriAI agriculture support'},
          ),
        ),
      ),
    ];

    return AgriPage(
      title: 'Help Center',
      subtitle: 'Get support and farming guidance',
      child: Column(
        children: [
          const AgriHeroCard(
            eyebrow: 'Need Assistance?',
            title: "We're Here to Help",
            subtitle: 'AI & official farmer support',
            trailing: Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AgriActionTile(
                title: item.$2,
                subtitle: item.$3,
                icon: item.$1,
                onTap: item.$4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AgriPrimaryButton(
            label: 'Call 1920 Agriculture Support',
            icon: Icons.call_rounded,
            onPressed: () => _launch(context, Uri(scheme: 'tel', path: '1920')),
          ),
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(question),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(tr(answer)),
        ],
      ),
    );
  }
}
