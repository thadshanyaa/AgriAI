import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_language.dart';

abstract final class AiFarmingService {
  static const _keyPreference = 'groq_free_api_key';
  static const modelName = 'qwen/qwen3.6-27b';
  static final _endpoint = Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions',
  );

  static Future<bool> get isOnlineConfigured async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getString(_keyPreference) ?? '').trim().isNotEmpty;
  }

  static Future<void> saveFreeApiKey(String value) async {
    final key = value.trim();
    final preferences = await SharedPreferences.getInstance();
    if (key.isEmpty) {
      await preferences.remove(_keyPreference);
    } else {
      await preferences.setString(_keyPreference, key);
    }
  }

  static String buildPrompt(String question, AppLanguage language) {
    final responseLanguage = switch (language) {
      AppLanguage.tamil => 'Tamil',
      AppLanguage.sinhala => 'Sinhala',
      AppLanguage.english => 'English',
    };
    return '''
You are AgriAI, a careful farming assistant for Sri Lankan farmers.
Answer only agriculture, crop, soil, irrigation, weather-risk, market, and plant-health questions.
Respond in $responseLanguage using clear, short, practical steps.
Never invent current prices, weather, pesticide doses, or disease certainty.
For chemical use, severe disease, poisoning, or major financial decisions, advise confirmation with Sri Lanka's 1920 agriculture advisory service or a qualified agriculture officer.
If unrelated to agriculture, politely say you only help with farming.

Farmer question: $question
''';
  }

  static Future<String> ask(String question) async {
    final preferences = await SharedPreferences.getInstance();
    final key = (preferences.getString(_keyPreference) ?? '').trim();
    if (key.isEmpty) return offlineAnswer(question);

    final response = await http
        .post(
          _endpoint,
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': modelName,
            'messages': [
              {
                'role': 'user',
                'content': buildPrompt(
                  question,
                  AppLanguageController.current.value,
                ),
              },
            ],
            'temperature': 0.35,
            'max_completion_tokens': 500,
          }),
        )
        .timeout(const Duration(seconds: 35));

    if (response.statusCode != 200) {
      throw AiFarmingException('Groq ${response.statusCode}: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    final message = choices?.isEmpty ?? true
        ? null
        : (choices!.first as Map<String, dynamic>)['message'];
    final answer = message is Map<String, dynamic>
        ? message['content']?.toString().trim()
        : null;
    if (answer == null || answer.isEmpty) {
      throw const AiFarmingException('The AI returned an empty response.');
    }
    return answer;
  }

  static String offlineAnswer(String question) {
    final text = question.toLowerCase();
    final disease =
        text.contains('disease') ||
        text.contains('leaf') ||
        text.contains('நோய்') ||
        text.contains('இலை') ||
        text.contains('රෝග') ||
        text.contains('පත්‍ර');
    final weather =
        text.contains('weather') ||
        text.contains('rain') ||
        text.contains('வானிலை') ||
        text.contains('மழை') ||
        text.contains('කාලගුණ') ||
        text.contains('වැසි');
    final market =
        text.contains('market') ||
        text.contains('price') ||
        text.contains('விலை') ||
        text.contains('சந்தை') ||
        text.contains('මිල') ||
        text.contains('වෙළඳ');
    final crop =
        text.contains('crop') ||
        text.contains('soil') ||
        text.contains('பயிர்') ||
        text.contains('மண்') ||
        text.contains('බෝග') ||
        text.contains('පස');

    return switch (AppLanguageController.current.value) {
      AppLanguage.tamil =>
        disease
            ? 'தெளிவான ஒரு இலையின் படத்தை நல்ல வெளிச்சத்தில் எடுத்து நோய் கண்டறிதல் பக்கத்தில் பதிவேற்றுங்கள். முடிவை உறுதி செய்ய 1920 விவசாய ஆலோசனை சேவையை தொடர்புகொள்ளுங்கள்.'
            : weather
            ? 'உங்கள் மாவட்டத்திற்கான நேரடி வானிலையும் 7 நாள் பயிர் பரிந்துரைகளையும் வானிலைப் பக்கத்தில் பார்க்கவும். அதிக மழை நாளில் நீர்ப்பாசனத்தை குறைக்கவும்.'
            : market
            ? 'சந்தை விலைப் பக்கத்தில் சமீபத்திய HARTI அறிவிப்பு தேதியையும் சமூக சந்தை விலைகளையும் ஒப்பிடுங்கள். விலை உறுதி செய்த பிறகே விற்பனை முடிவு எடுக்கவும்.'
            : crop
            ? 'மண் வகை, பருவம், நீர் வசதி மற்றும் நில அளவை உள்ளிட்டு பயிர் பரிந்துரை பக்கத்தை பயன்படுத்துங்கள்.'
            : 'நான் இப்போது offline விவசாய உதவியை வழங்குகிறேன். பயிர், இலை நோய், வானிலை, மண் அல்லது சந்தை விலை பற்றி கேளுங்கள்.',
      AppLanguage.sinhala =>
        disease
            ? 'හොඳ ආලෝකයක පැහැදිලි පත්‍ර ඡායාරූපයක් ගෙන රෝග හඳුනාගැනීමේ පිටුවට උඩුගත කරන්න. ප්‍රතිඵලය 1920 කෘෂිකර්ම උපදේශන සේවාවෙන් තහවුරු කරන්න.'
            : weather
            ? 'ඔබේ දිස්ත්‍රික්කයේ සජීවී කාලගුණය සහ දින 7 බෝග නිර්දේශ කාලගුණ පිටුවෙන් බලන්න. අධික වැසි දිනවල වාරිමාර්ග අඩු කරන්න.'
            : market
            ? 'වෙළඳපොළ මිල පිටුවේ නවතම HARTI නිවේදන දිනය සහ ප්‍රජා වෙළඳපොළ මිල සසඳන්න. මිල තහවුරු කර පසුව විකිණීම තීරණය කරන්න.'
            : crop
            ? 'පස, කන්නය, ජල මූලාශ්‍රය සහ භූමි ප්‍රමාණය ඇතුළත් කර බෝග නිර්දේශය භාවිතා කරන්න.'
            : 'මම දැන් offline ගොවි උපකාරය ලබා දෙමි. බෝග, පත්‍ර රෝග, කාලගුණය, පස හෝ වෙළඳපොළ මිල ගැන අසන්න.',
      AppLanguage.english =>
        disease
            ? 'Take one clear leaf photo in good light and upload it on Disease Detection. Confirm serious results with the 1920 agriculture advisory service.'
            : weather
            ? 'Open Weather for your district’s live conditions and seven-day crop advice. Reduce irrigation on high-rain days.'
            : market
            ? 'Compare the latest HARTI bulletin date and community prices on Market Prices. Confirm the buyer price before selling.'
            : crop
            ? 'Enter soil, season, water source and farm size in Crop Recommendation for a ranked result.'
            : 'I am providing offline farming help. Ask about crops, leaf disease, weather, soil or market prices.',
    };
  }

  static String friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('401') || message.contains('403')) {
      return tr(
        'The free AI key is invalid. Open AI Setup and add a valid Groq key.',
      );
    }
    if (message.contains('429')) {
      return tr(
        'Free AI limit reached. Try again later; offline farming help is still available.',
      );
    }
    return tr(
      'Online AI is unavailable. Check internet or remove the key to use offline farming help.',
    );
  }
}

class AiFarmingException implements Exception {
  const AiFarmingException(this.message);

  final String message;

  @override
  String toString() => message;
}
