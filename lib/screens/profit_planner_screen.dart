import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../localization/app_language.dart';
import '../services/crop_catalog.dart';
import '../services/firebase_backend.dart';
import '../services/market_price_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class ProfitPlannerScreen extends StatefulWidget {
  const ProfitPlannerScreen({super.key});

  @override
  State<ProfitPlannerScreen> createState() => _ProfitPlannerScreenState();
}

class _ProfitPlannerScreenState extends State<ProfitPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _land = TextEditingController(text: '1');
  final _seed = TextEditingController();
  final _fertilizer = TextEditingController();
  final _labour = TextEditingController();
  final _yield = TextEditingController();
  final _price = TextEditingController();
  String _crop = 'Rice';
  double _investment = 0;
  double _revenue = 0;
  bool _saving = false;
  bool _loadingEstimate = false;
  String _priceSource = '25-crop planning reference';
  int _estimateRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEstimate());
  }

  @override
  void dispose() {
    for (final controller in [
      _land,
      _seed,
      _fertilizer,
      _labour,
      _yield,
      _price,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double _number(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  Future<void> _loadEstimate() async {
    final request = ++_estimateRequest;
    setState(() => _loadingEstimate = true);
    final selectedCrop = _crop;
    final crop = CropCatalog.byName(selectedCrop);
    final acres = _number(_land) > 0 ? _number(_land) : 1;
    _yield.text = (crop.yieldPerAcre * acres).round().toString();
    var price = crop.pricePerUnit;
    var source = '25-crop planning reference';
    try {
      final communityPrice = await FirebaseBackend.communityPriceForCrop(
        selectedCrop,
      );
      if (communityPrice != null) {
        price = communityPrice;
        source = 'Community Market average';
      } else {
        final bulletins = await MarketPriceService.fetchLatestBulletins();
        if (bulletins.isNotEmpty) {
          source =
              'Planning reference • HARTI bulletin ${DateFormat('dd MMM yyyy').format(bulletins.first.date)} available';
        }
      }
    } catch (_) {}
    if (!mounted || request != _estimateRequest || selectedCrop != _crop) {
      return;
    }
    _price.text = price.round().toString();
    setState(() {
      _priceSource = source;
      _loadingEstimate = false;
    });
    _updatePreview();
  }

  void _updateYieldForLand() {
    final crop = CropCatalog.byName(_crop);
    final acres = _number(_land);
    _yield.text = (crop.yieldPerAcre * acres).round().toString();
    _updatePreview();
  }

  void _updatePreview() {
    final investment = _number(_seed) + _number(_fertilizer) + _number(_labour);
    final revenue = _number(_yield) * _number(_price);
    if (!mounted) {
      _investment = investment;
      _revenue = revenue;
      return;
    }
    setState(() {
      _investment = investment;
      _revenue = revenue;
    });
  }

  Future<void> _calculate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final investment = _number(_seed) + _number(_fertilizer) + _number(_labour);
    final revenue = _number(_yield) * _number(_price);
    final expectedProfit = revenue - investment;
    setState(() {
      _investment = investment;
      _revenue = revenue;
      _saving = true;
    });
    try {
      await FirebaseBackend.saveProfitPlan(
        crop: _crop,
        acres: _number(_land),
        investment: investment,
        revenue: revenue,
        expectedProfit: expectedProfit,
        expectedYield: _number(_yield),
        pricePerUnit: _number(_price),
      );
      if (mounted) showDemoMessage(context, 'Profit estimate saved');
    } catch (error) {
      if (mounted) {
        showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _money(double value) => 'Rs. ${NumberFormat('#,##0').format(value)}';

  @override
  Widget build(BuildContext context) {
    final profit = _revenue - _investment;
    final acres = _number(_land);
    final profitPerAcre = acres > 0 ? profit / acres : 0.0;
    final roi = _investment > 0 ? (profit / _investment) * 100 : 0.0;
    return AgriPage(
      title: 'Profit Planner',
      subtitle: 'Estimate costs, revenue and profit for all 25 crops',
      child: Column(
        children: [
          const AgriHeroCard(
            eyebrow: 'AI Profit Calculator',
            title: 'Plan Before You Plant',
            subtitle: '25 crops • Editable costs • Automatic yield and price',
            trailing: Icon(
              Icons.savings_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          AgriSection(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _crop,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr('Crop Type'),
                      prefixIcon: const Icon(Icons.eco_rounded),
                    ),
                    items: CropCatalog.crops
                        .map(
                          (crop) => DropdownMenuItem(
                            value: crop.name,
                            child: Text('${crop.emoji} ${tr(crop.name)}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _crop = value;
                      _loadEstimate();
                    },
                  ),
                  const SizedBox(height: 10),
                  _numberField(
                    _land,
                    'Land Size (Acres)',
                    suffix: tr('acres'),
                    onChanged: (_) => _updateYieldForLand(),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loadingEstimate ? null : _loadEstimate,
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    label: Text(
                      tr(
                        _loadingEstimate
                            ? 'Updating yield and price...'
                            : 'Update Yield & Current Price',
                      ),
                    ),
                  ),
                  Text(
                    '${tr('Price source')}: ${tr(_priceSource)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _numberField(_seed, 'Seed / Planting Material Cost'),
                  _numberField(_fertilizer, 'Fertilizer & Input Cost'),
                  _numberField(_labour, 'Labour Cost'),
                  _numberField(
                    _yield,
                    'Expected Yield (kg/units)',
                    readOnly: true,
                    helperText: 'Automatically calculated from crop and land',
                    fieldKey: const Key('automatic_expected_yield'),
                  ),
                  _numberField(
                    _price,
                    'Expected Selling Price (per kg/unit)',
                    readOnly: true,
                    helperText: 'Automatically loaded for the selected crop',
                    fieldKey: const Key('automatic_selling_price'),
                  ),
                  const SizedBox(height: 4),
                  AgriPrimaryButton(
                    label: _saving ? 'Saving...' : 'Calculate Profit',
                    icon: Icons.calculate_rounded,
                    onPressed: _saving ? null : _calculate,
                  ),
                ],
              ),
            ),
          ),
          AgriSection(
            title: 'Estimated Results',
            child: Column(
              children: [
                AgriInfoRow('Investment', _money(_investment)),
                AgriInfoRow('Revenue', _money(_revenue)),
                AgriInfoRow(
                  'Expected Profit',
                  _money(profit),
                  valueColor: profit >= 0 ? AppColors.primary : Colors.red,
                ),
                AgriInfoRow('Profit per Acre', _money(profitPerAcre)),
                AgriInfoRow('Estimated ROI', '${roi.toStringAsFixed(1)}%'),
              ],
            ),
          ),
          AgriSection(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.warning,
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    tr(
                      'Yield and selling price are selected automatically. Enter only your actual planting, input and labour costs. Confirm the market price before making a farming decision.',
                    ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    String? suffix,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    String? helperText,
    Key? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        readOnly: readOnly,
        enableInteractiveSelection: !readOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: tr(label),
          helperText: helperText == null ? null : tr(helperText),
          suffixIcon: readOnly
              ? const Icon(Icons.lock_outline_rounded, size: 19)
              : null,
          fillColor: readOnly
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          prefixText: label.contains('Cost') || label.contains('Price')
              ? 'Rs. '
              : null,
          suffixText: suffix,
        ),
        onChanged: (value) {
          _updatePreview();
          onChanged?.call(value);
        },
        validator: (value) {
          final number = double.tryParse(value?.trim() ?? '');
          return number == null || number < 0
              ? tr('Enter a valid amount')
              : null;
        },
      ),
    );
  }
}
