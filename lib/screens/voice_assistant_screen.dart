import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../localization/app_language.dart';
import '../services/ai_farming_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _manualQuestion = TextEditingController();
  late final AnimationController _waveController;

  bool _initializing = true;
  bool _available = false;
  bool _listening = false;
  bool _processing = false;
  String? _speechLocale;
  String _heard = '';
  String _reply = 'Tap the microphone and ask a farming question.';
  String? _error;
  double _soundLevel = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      String? locale;
      if (available) {
        final locales = await _speech.locales();
        final prefix = switch (AppLanguageController.current.value) {
          AppLanguage.tamil => 'ta',
          AppLanguage.sinhala => 'si',
          AppLanguage.english => 'en',
        };
        for (final candidate in locales) {
          if (candidate.localeId.toLowerCase().startsWith(prefix)) {
            locale = candidate.localeId;
            break;
          }
        }
        locale ??= (await _speech.systemLocale())?.localeId;
      }
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.0);
      if (!mounted) return;
      setState(() {
        _available = available;
        _speechLocale = locale;
        _initializing = false;
        _error = available
            ? null
            : 'Speech recognition is unavailable. Check microphone permission and Google speech services.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _available = false;
        _initializing = false;
        _error = 'Voice initialization failed: $error';
      });
    }
  }

  void _onStatus(String status) {
    if (!mounted) return;
    final active = status == SpeechToText.listeningStatus;
    setState(() => _listening = active);
    if (active) {
      _waveController.repeat(reverse: true);
    } else {
      _waveController.stop();
      _waveController.value = 0;
    }
    if ((status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) &&
        _heard.trim().isNotEmpty &&
        !_processing) {
      _answerHeardQuestion();
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _listening = false;
      _error = 'Speech recognition: ${error.errorMsg}';
    });
    _waveController.stop();
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _heard = result.recognizedWords;
      _error = null;
    });
    if (result.finalResult && _heard.trim().isNotEmpty) {
      _answerHeardQuestion();
    }
  }

  Future<void> _startListening() async {
    if (_initializing || _processing) return;
    if (!_available) {
      await _initializeVoice();
      if (!_available) return;
    }
    await _tts.stop();
    setState(() {
      _heard = '';
      _reply = '';
      _error = null;
      _listening = true;
    });
    _waveController.repeat(reverse: true);
    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: (level) {
          if (mounted) setState(() => _soundLevel = level);
        },
        listenOptions: SpeechListenOptions(
          localeId: _speechLocale,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _error = 'Unable to start microphone: $error';
      });
      _waveController.stop();
    }
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    await _speech.stop();
    if (_heard.trim().isNotEmpty) {
      await _answerHeardQuestion();
    } else if (mounted) {
      setState(() {
        _listening = false;
        _error = 'No speech detected. Tap Start and speak clearly.';
      });
    }
  }

  Future<void> _answerHeardQuestion() async {
    final question = _heard.trim();
    if (question.isEmpty || _processing) return;
    setState(() => _processing = true);
    await _speech.stop();
    String answer;
    try {
      answer = await AiFarmingService.ask(question);
    } catch (error) {
      answer = AiFarmingService.friendlyError(error);
    }
    if (mounted) {
      setState(() {
        _listening = false;
        _reply = answer;
        _error = null;
      });
    }
    _waveController.stop();
    try {
      final ttsLocale = switch (AppLanguageController.current.value) {
        AppLanguage.tamil => 'ta-IN',
        AppLanguage.sinhala => 'si-LK',
        AppLanguage.english => 'en-US',
      };
      await _tts.setLanguage(ttsLocale);
      await _tts.speak(answer);
    } catch (_) {
      // The text answer remains usable if a language voice is not installed.
    } finally {
      _processing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _submitManualQuestion() async {
    final value = _manualQuestion.text.trim();
    if (value.isEmpty || _processing) return;
    setState(() {
      _heard = value;
      _manualQuestion.clear();
      _error = null;
    });
    await _answerHeardQuestion();
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    _manualQuestion.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amplitude = _listening
        ? (0.35 + (_soundLevel.abs() / 25)).clamp(0.35, 1.0)
        : 0.15;
    return AgriPage(
      title: 'AI Voice Assistant',
      subtitle: 'Real speech recognition and spoken farming guidance',
      child: Column(
        children: [
          AgriHeroCard(
            title: _initializing
                ? 'Preparing Microphone...'
                : _listening
                ? 'Listening...'
                : _processing
                ? 'Preparing Answer...'
                : 'Tap to Speak',
            subtitle: _available
                ? 'Tamil, Sinhala and English device speech support'
                : 'Microphone or speech service is unavailable',
            trailing: GestureDetector(
              onTap: _listening ? _stopListening : _startListening,
              child: CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Icon(
                  _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
            ),
          ),
          AgriSection(
            title: _listening ? 'Listening to your question...' : 'Voice Wave',
            child: SizedBox(
              height: 95,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) => CustomPaint(
                  painter: _WavePainter(
                    amplitude:
                        amplitude *
                        (_listening ? 0.7 + _waveController.value * 0.3 : 1),
                  ),
                ),
              ),
            ),
          ),
          if (_error != null)
            AgriSection(
              title: 'Voice Status',
              child: Text(
                tr(_error!),
                style: const TextStyle(color: AppColors.warning),
              ),
            ),
          AgriSection(
            title: 'Conversation',
            child: Column(
              children: [
                if (_heard.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _VoiceBubble(_heard, user: true),
                  ),
                if (_heard.isNotEmpty && _reply.isNotEmpty)
                  const SizedBox(height: 8),
                if (_reply.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _VoiceBubble(_reply, user: false),
                  ),
              ],
            ),
          ),
          AgriSection(
            title: 'Voice fallback',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualQuestion,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitManualQuestion(),
                    decoration: InputDecoration(
                      hintText: tr(
                        'Type your farming question if speech is unavailable',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _processing ? null : _submitManualQuestion,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AgriPrimaryButton(
            label: _listening ? 'Stop & Answer' : 'Start Voice Chat',
            icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
            onPressed: _initializing || _processing
                ? null
                : (_listening ? _stopListening : _startListening),
          ),
        ],
      ),
    );
  }
}

class _VoiceBubble extends StatelessWidget {
  const _VoiceBubble(this.text, {required this.user});

  final String text;
  final bool user;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: user ? AppColors.backgroundDeep : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.amplitude});

  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(0, size.height / 2);
    const pattern = [
      0.1,
      -0.5,
      0.75,
      -0.35,
      0.95,
      -0.7,
      0.45,
      -0.2,
      0.65,
      -0.5,
      0.2,
      0.0,
    ];
    for (var i = 0; i < pattern.length; i++) {
      final x = size.width * (i + 1) / pattern.length;
      final y = size.height / 2 + pattern[i] * size.height * 0.38 * amplitude;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.amplitude != amplitude;
}
