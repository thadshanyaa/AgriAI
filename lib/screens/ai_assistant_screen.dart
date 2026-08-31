import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/ai_farming_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      'Hello Farmer! How can I help you today?',
      isUser: false,
    ),
  ];
  bool _responding = false;
  bool _onlineConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadAiStatus();
  }

  Future<void> _loadAiStatus() async {
    final configured = await AiFarmingService.isOnlineConfigured;
    if (mounted) setState(() => _onlineConfigured = configured);
  }

  Future<void> _showAiSetup() async {
    final key = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Free AI Setup')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  'Use a free Groq key with the Qwen open model. No billing or card is required on the Free Plan.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: key,
                obscureText: true,
                decoration: InputDecoration(labelText: tr('Groq API key')),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://console.groq.com/keys'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(tr('Create free Groq key')),
              ),
              Text(
                tr(
                  'The key stays on this phone. Leave it empty to use offline farming help.',
                ),
                style: const TextStyle(fontSize: 11),
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
    if (saved == true) {
      await AiFarmingService.saveFreeApiKey(key.text);
      await _loadAiStatus();
      if (mounted) showDemoMessage(context, 'AI setup saved');
    }
    key.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _responding) return;
    setState(() {
      _messages.add(_ChatMessage(text, isUser: true));
      _controller.clear();
      _responding = true;
    });
    try {
      final answer = await AiFarmingService.ask(text);
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(answer, isUser: false)));
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          _ChatMessage(
            AiFarmingService.friendlyError(error),
            isUser: false,
            isError: true,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: 'AI Farming Assistant',
      subtitle: 'Ask anything about your crops',
      scrollable: false,
      actions: [
        IconButton(
          tooltip: 'Voice assistant',
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.voiceAssistant),
          icon: const Icon(Icons.mic_rounded),
        ),
      ],
      child: Column(
        children: [
          const AgriHeroCard(
            title: 'Hello Farmer!',
            subtitle: 'How can I help you today?',
            trailing: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Text(
                'AI',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              label: Text(
                tr(
                  _onlineConfigured
                      ? 'Qwen Online AI • Groq Free Plan'
                      : 'Offline Farming Help • Tap for Free AI Setup',
                ),
              ),
              onPressed: _showAiSetup,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length + (_responding ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        final message = _messages[index];
                        final bubbleColor = message.isUser
                            ? AppColors.backgroundDeep
                            : message.isError
                            ? Theme.of(context).colorScheme.errorContainer
                            : AppColors.surfaceSoft;
                        final textColor = message.isError
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : AppColors.text;
                        return Align(
                          alignment: message.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            margin: const EdgeInsets.only(bottom: 9),
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              tr(message.text),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.voiceAssistant,
                        ),
                        icon: const Icon(Icons.mic_rounded),
                      ),
                      IconButton(
                        onPressed: () => showDemoMessage(
                          context,
                          'Use Disease Detection for leaf images',
                        ),
                        icon: const Icon(Icons.image_rounded),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: tr('Type your message...'),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
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

class _ChatMessage {
  const _ChatMessage(this.text, {required this.isUser, this.isError = false});

  final String text;
  final bool isUser;
  final bool isError;
}
