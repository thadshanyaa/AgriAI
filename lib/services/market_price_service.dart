import 'package:http/http.dart' as http;

class MarketPriceBulletin {
  const MarketPriceBulletin({required this.date, required this.pdfUrl});

  final DateTime date;
  final Uri pdfUrl;
}

abstract final class MarketPriceService {
  static final _pageUri = Uri.parse('https://www.harti.gov.lk/daily-price.php');

  static Future<List<MarketPriceBulletin>> fetchLatestBulletins() async {
    final response = await http
        .get(
          _pageUri,
          headers: const {
            'Accept': 'text/html',
            'User-Agent': 'AgriAI/1.0 (Sri Lanka market price reader)',
          },
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception('Market price service returned ${response.statusCode}.');
    }

    final pattern = RegExp(
      r'<td>\s*(\d{4}-\d{2}-\d{2})\s*</td>[\s\S]*?'
      r'<a\s+href="([^"]+\.pdf)"',
      caseSensitive: false,
    );
    final bulletins = <MarketPriceBulletin>[];
    final seenDates = <String>{};
    for (final match in pattern.allMatches(response.body)) {
      final dateText = match.group(1)!;
      if (!seenDates.add(dateText)) continue;
      final href = match.group(2)!.replaceAll('&amp;', '&').trim();
      bulletins.add(
        MarketPriceBulletin(
          date: DateTime.parse(dateText),
          pdfUrl: _pageUri.resolve(Uri.encodeFull(href)),
        ),
      );
      if (bulletins.length == 10) break;
    }
    if (bulletins.isEmpty) {
      throw const FormatException('No HARTI price bulletins were found.');
    }
    return List.unmodifiable(bulletins);
  }
}
