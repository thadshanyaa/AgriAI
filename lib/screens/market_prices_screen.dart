import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/market_price_service.dart';
import '../services/crop_catalog.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  List<MarketPriceBulletin> _bulletins = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool notify = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bulletins = await MarketPriceService.fetchLatestBulletins();
      if (!mounted) return;
      setState(() {
        _bulletins = bulletins;
        _loading = false;
      });
      if (notify) showDemoMessage(context, 'Market prices updated');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Unable to load market prices. Check your internet connection.';
      });
    }
  }

  Future<void> _openBulletin(MarketPriceBulletin bulletin) async {
    final opened = await launchUrl(
      bulletin.pdfUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      showDemoMessage(context, 'Unable to open the price bulletin.');
    }
  }

  Future<void> _callPriceService() async {
    final opened = await launchUrl(Uri.parse('tel:6666'));
    if (!opened && mounted) {
      showDemoMessage(context, 'Unable to open the phone dialler.');
    }
  }

  Widget _bulletinList() {
    if (_loading && _bulletins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null && _bulletins.isEmpty) {
      return AgriSection(
        child: Column(
          children: [
            Text(tr(_error!), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr('Try Again')),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_loading) const LinearProgressIndicator(),
        ..._bulletins.map(
          (bulletin) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AgriActionTile(
              title:
                  '${tr('Daily Price Bulletin')} • ${DateFormat('dd MMM yyyy').format(bulletin.date)}',
              subtitle: 'English PDF • Official wholesale and retail prices',
              icon: Icons.picture_as_pdf_rounded,
              trailing: const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.primary,
              ),
              onTap: () => _openBulletin(bulletin),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestDate = _bulletins.isEmpty
        ? tr('Loading latest prices...')
        : DateFormat('dd MMM yyyy').format(_bulletins.first.date);
    return AgriPage(
      title: 'Market Prices',
      subtitle: 'Official Sri Lanka daily food commodity prices',
      actions: [
        IconButton(
          tooltip: tr('Refresh Market Prices'),
          onPressed: _loading ? null : () => _load(notify: true),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        children: [
          AgriHeroCard(
            eyebrow: 'HARTI Market Information',
            title: 'Daily Food Prices',
            subtitle: '${tr('Latest official bulletin')}: $latestDate',
            trailing: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          _bulletinList(),
          AgriSection(
            title: 'All 25 Crops - Planning Price Reference',
            child: Column(
              children: [
                Text(
                  tr(
                    'These are editable planning estimates, not extracted live HARTI prices. Confirm the current daily price before selling.',
                  ),
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 10),
                ...CropCatalog.crops.map(
                  (crop) => AgriInfoRow(
                    '${crop.emoji} ${tr(crop.name)}',
                    'Rs. ${NumberFormat('#,##0').format(crop.pricePerUnit)} / kg',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _callPriceService,
            icon: const Icon(Icons.call_rounded),
            label: Text(tr('Call HARTI price service 6666')),
          ),
          const SizedBox(height: 14),
          AgriPrimaryButton(
            label: 'Open Community Market',
            icon: Icons.storefront_rounded,
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.communityMarket),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Source: HARTI Sri Lanka • Tap a bulletin to view official prices',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
