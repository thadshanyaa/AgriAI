import 'dart:convert';

import 'package:http/http.dart' as http;

import '../localization/app_language.dart';

/// Small no-key translation client used for live external content.
///
/// Static application labels still use the reviewed local translations in
/// [app_language.dart]. Only changing RSS/API text is sent to MyMemory.
abstract final class TranslationService {
  static final Map<String, String> _cache = <String, String>{};

  static Future<String> translate(
    String source, {
    required AppLanguage language,
  }) async {
    final text = source.trim();
    if (text.isEmpty || language == AppLanguage.english) return text;

    final target = language == AppLanguage.tamil ? 'ta' : 'si';
    final clipped = text.length > 450 ? text.substring(0, 450) : text;
    final cacheKey = '$target::$clipped';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': clipped,
      'langpair': 'en|$target',
      'mt': '1',
      'de': 'thadshanyaa@gmail.com',
    });
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return text;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final responseData = json['responseData'] as Map<String, dynamic>?;
      final translated = _decodeHtml(
        responseData?['translatedText']?.toString().trim() ?? '',
      );
      if (translated.isEmpty ||
          translated.toUpperCase() == 'NO QUERY SPECIFIED') {
        return text;
      }
      _cache[cacheKey] = translated;
      return translated;
    } catch (_) {
      return text;
    }
  }

  static String _decodeHtml(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
