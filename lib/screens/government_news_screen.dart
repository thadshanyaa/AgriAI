import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_language.dart';
import '../services/agriculture_news_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class GovernmentNewsScreen extends StatefulWidget {
  const GovernmentNewsScreen({super.key});

  @override
  State<GovernmentNewsScreen> createState() => _GovernmentNewsScreenState();
}

class _GovernmentNewsScreenState extends State<GovernmentNewsScreen> {
  List<AgricultureNewsArticle> _articles = const [];
  bool _loading = true;
  String? _error;
  DateTime? _lastCheckedAt;
  Timer? _autoRefreshTimer;
  late AppLanguage _loadedLanguage;

  @override
  void initState() {
    super.initState();
    _loadedLanguage = AppLanguageController.current.value;
    _loadNews();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted && !_loading) _loadNews();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNews({bool showConfirmation = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rawArticles = await AgricultureNewsService.fetchLatest();
      final language = AppLanguageController.current.value;
      final articles = <AgricultureNewsArticle>[];
      for (final article in rawArticles.take(8)) {
        final title = await TranslationService.translate(
          article.title,
          language: language,
        );
        final description = await TranslationService.translate(
          article.description,
          language: language,
        );
        articles.add(article.copyWith(title: title, description: description));
      }
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _loadedLanguage = language;
        _loading = false;
        _lastCheckedAt = DateTime.now();
      });
      if (showConfirmation) {
        showDemoMessage(context, 'Agriculture news updated');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Unable to load agriculture news. Check your internet connection and try again.';
      });
    }
  }

  Future<void> _openArticle(AgricultureNewsArticle article) async {
    final opened = await launchUrl(
      article.link,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      showDemoMessage(context, 'Unable to open the original article.');
    }
  }

  String _articleSubtitle(AgricultureNewsArticle article) {
    final parts = <String>[];
    if (article.description.isNotEmpty) {
      final description = article.description.length > 180
          ? '${article.description.substring(0, 177)}...'
          : article.description;
      parts.add(description);
    }
    final publishedAt = article.publishedAt;
    final date = publishedAt == null
        ? null
        : DateFormat('dd MMM yyyy • h:mm a').format(publishedAt.toLocal());
    parts.add([article.source, date].whereType<String>().join(' • '));
    return parts.join('\n');
  }

  Widget _statusContent() {
    if (_loading && _articles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 42),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _articles.isEmpty) {
      return AgriSection(
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.muted,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              tr(_error!),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loading ? null : _loadNews,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr('Try Again')),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      return AgriSection(
        child: Text(
          tr('No Sri Lankan agriculture news is available right now.'),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        ..._articles.map(
          (article) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AgriActionTile(
              title: article.title,
              subtitle: _articleSubtitle(article),
              icon: Icons.article_rounded,
              onTap: () => _openArticle(article),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = AppLanguageController.current.value;
    if (_loadedLanguage != currentLanguage && !_loading) {
      _loadedLanguage = currentLanguage;
      Future<void>.microtask(_loadNews);
    }
    return AgriPage(
      title: 'Sri Lanka Agriculture News',
      subtitle: 'Live updates from Sri Lankan news sources',
      child: Column(
        children: [
          const AgriHeroCard(
            eyebrow: 'Latest Updates',
            title: 'Local Farmer News',
            subtitle: 'Agriculture stories from Daily Mirror Sri Lanka',
            trailing: Icon(
              Icons.newspaper_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          _statusContent(),
          if (_lastCheckedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              '${tr('Last checked')}: ${DateFormat('dd MMM yyyy • hh:mm a').format(_lastCheckedAt!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 5),
          Text(
            tr('Auto refresh: every 15 minutes while this page is open'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.primary, fontSize: 11),
          ),
          const SizedBox(height: 14),
          AgriPrimaryButton(
            label: 'Refresh Agriculture News',
            icon: Icons.refresh_rounded,
            onPressed: _loading
                ? null
                : () => _loadNews(showConfirmation: true),
          ),
          const SizedBox(height: 10),
          Text(
            '${tr('Source')}: Daily Mirror Sri Lanka • ${tr('Live article text is translated for Tamil and Sinhala. Tap to open the English original.')}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
