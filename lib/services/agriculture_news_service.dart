import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class AgricultureNewsArticle {
  const AgricultureNewsArticle({
    required this.title,
    required this.description,
    required this.link,
    required this.source,
    required this.publishedAt,
  });

  final String title;
  final String description;
  final Uri link;
  final String source;
  final DateTime? publishedAt;

  AgricultureNewsArticle copyWith({String? title, String? description}) {
    return AgricultureNewsArticle(
      title: title ?? this.title,
      description: description ?? this.description,
      link: link,
      source: source,
      publishedAt: publishedAt,
    );
  }
}

abstract final class AgricultureNewsService {
  static const _feedUrl = 'https://www.dailymirror.lk/rss/breaking_news/108';
  static const _source = 'Daily Mirror Sri Lanka';

  static final RegExp _agricultureTerms = RegExp(
    r'\b(agricultur(?:e|al)|agri\s*business|farmer(?:s|ing)?|farm(?:s|ing)?|'
    r'paddy|rice|crop(?:s)?|cultivat(?:e|ed|ion)|fertili[sz]er(?:s)?|irrigation|'
    r'harvest(?:s|ing)?|vegetable(?:s)?|tea|coconut(?:s)?|rubber|livestock|dairy|'
    r'potato(?:es)?|maize|chilli(?:es)?|onion(?:s)?|food security|plantation(?:s)?|'
    r'agro|seed(?:s)?|soil|drought|subsid(?:y|ies))\b',
    caseSensitive: false,
  );

  static Future<List<AgricultureNewsArticle>> fetchLatest() async {
    final response = await http
        .get(
          Uri.parse(_feedUrl),
          headers: const {
            'Accept': 'application/rss+xml, application/xml, text/xml',
            'User-Agent': 'AgriAI/1.0 (Sri Lanka agriculture news reader)',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('News service returned ${response.statusCode}.');
    }

    // Daily Mirror is protected by Cloudflare, which can append analytics
    // scripts after the closing RSS element. Parse only the RSS document.
    final rssEnd = response.body.toLowerCase().lastIndexOf('</rss>');
    if (rssEnd == -1) {
      throw const FormatException('The news service returned invalid RSS.');
    }
    final rssXml = response.body.substring(0, rssEnd + '</rss>'.length);
    final document = XmlDocument.parse(rssXml);
    final articles = <AgricultureNewsArticle>[];

    for (final item in document.findAllElements('item')) {
      final title = _cleanText(_valueOf(item, 'title'));
      final description = _cleanText(_valueOf(item, 'description'));
      final link = Uri.tryParse(_valueOf(item, 'link').trim());
      final searchableText = '$title $description';

      final titleMatches = _agricultureTerms.allMatches(title).length;
      final totalMatches = _agricultureTerms.allMatches(searchableText).length;
      if (title.isEmpty ||
          link == null ||
          !link.hasScheme ||
          (titleMatches == 0 && totalMatches < 2)) {
        continue;
      }

      articles.add(
        AgricultureNewsArticle(
          title: title,
          description: description,
          link: link,
          source: _source,
          publishedAt: _parseRssDate(_valueOf(item, 'pubDate')),
        ),
      );
    }

    articles.sort((first, second) {
      final firstDate = first.publishedAt;
      final secondDate = second.publishedAt;
      if (firstDate == null && secondDate == null) return 0;
      if (firstDate == null) return 1;
      if (secondDate == null) return -1;
      return secondDate.compareTo(firstDate);
    });

    return articles.take(12).toList(growable: false);
  }

  static String _valueOf(XmlElement item, String elementName) {
    final elements = item.findElements(elementName);
    return elements.isEmpty ? '' : elements.first.innerText;
  }

  static String _cleanText(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static DateTime? _parseRssDate(String value) {
    final match = RegExp(
      r'^(?:[A-Za-z]{3},\s*)?(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+'
      r'(\d{2}):(\d{2}):(\d{2})(?:\s+([+-])(\d{2})(\d{2})|\s+GMT)?$',
    ).firstMatch(value.trim());
    if (match == null) return DateTime.tryParse(value.trim());

    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final month = months[match.group(2)!.toLowerCase()];
    if (month == null) return null;

    var result = DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );

    final sign = match.group(7);
    if (sign != null) {
      final offset = Duration(
        hours: int.parse(match.group(8)!),
        minutes: int.parse(match.group(9)!),
      );
      result = sign == '+' ? result.subtract(offset) : result.add(offset);
    }
    return result;
  }
}
