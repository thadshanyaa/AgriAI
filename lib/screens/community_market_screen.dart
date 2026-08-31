import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_language.dart';
import '../services/firebase_backend.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class CommunityMarketScreen extends StatefulWidget {
  const CommunityMarketScreen({super.key});

  @override
  State<CommunityMarketScreen> createState() => _CommunityMarketScreenState();
}

class _CommunityMarketScreenState extends State<CommunityMarketScreen> {
  String _category = 'All';
  String _query = '';

  Future<void> _createListing() async {
    final item = TextEditingController();
    final quantity = TextEditingController();
    final price = TextEditingController();
    final notes = TextEditingController();
    var category = 'Crop';
    var unit = 'kg';
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr('Create Market Listing')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(labelText: tr('Category')),
                  items: ['Crop', 'Tool', 'Equipment', 'Service']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(tr(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: item,
                  decoration: InputDecoration(
                    labelText: tr('Item name'),
                    hintText: tr('Example: Rice, sprayer or tractor service'),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(labelText: tr('Quantity')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration: InputDecoration(labelText: tr('Unit')),
                        items: ['kg', 'unit', 'day', 'acre', 'lot']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(tr(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => unit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: tr('Price per unit'),
                    prefixText: 'Rs. ',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: tr('Description (optional)'),
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
              onPressed: () {
                if (item.text.trim().isEmpty ||
                    quantity.text.trim().isEmpty ||
                    price.text.trim().isEmpty) {
                  showDemoMessage(context, 'Enter item, quantity and price');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(tr('Publish')),
            ),
          ],
        ),
      ),
    );
    if (created == true && mounted) {
      try {
        await FirebaseBackend.addMarketListing(
          category: category,
          item: item.text,
          quantity: quantity.text,
          unit: unit,
          price: price.text,
          notes: notes.text,
        );
        if (mounted) showDemoMessage(context, 'Listing published successfully');
      } catch (error) {
        if (mounted) {
          showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
        }
      }
    }
    item.dispose();
    quantity.dispose();
    price.dispose();
    notes.dispose();
  }

  Future<void> _openListing(Map<String, dynamic> listing) async {
    final mine = listing['ownerId'] == FirebaseBackend.currentUser?.uid;
    final phone = listing['contactPhone']?.toString() ?? '';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing['item']?.toString() ?? tr('Market listing'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              AgriInfoRow(
                'Price',
                listing['price']?.toString() ?? tr('Contact seller'),
              ),
              AgriInfoRow(
                'Quantity',
                '${listing['quantity'] ?? '-'} ${listing['unit'] ?? ''}',
              ),
              AgriInfoRow('District', listing['district']?.toString() ?? '-'),
              AgriInfoRow('Seller', listing['ownerName']?.toString() ?? '-'),
              if ((listing['notes']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(listing['notes'].toString()),
              ],
              const SizedBox(height: 16),
              if (!mine)
                AgriPrimaryButton(
                  label: phone.isEmpty
                      ? 'Seller phone unavailable'
                      : 'Call Seller',
                  icon: Icons.call_rounded,
                  onPressed: phone.isEmpty
                      ? null
                      : () => launchUrl(Uri(scheme: 'tel', path: phone)),
                ),
              if (mine)
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await FirebaseBackend.deleteMarketListing(
                      listing['id'].toString(),
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(tr('Delete My Listing')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseBackend.marketListingsStream(),
      builder: (context, snapshot) {
        final allListings = snapshot.data ?? const <Map<String, dynamic>>[];
        final listings = allListings.where((listing) {
          final category = listing['category']?.toString() ?? 'Crop';
          final text = '${listing['item']} ${listing['district']}'
              .toLowerCase();
          final categoryMatches = _category == 'All' || category == _category;
          return categoryMatches && text.contains(_query.toLowerCase());
        }).toList();

        return AgriPage(
          title: 'Community Market',
          subtitle: 'Real listings shared by registered AgriAI farmers',
          child: Column(
            children: [
              const AgriHeroCard(
                eyebrow: 'Farmer-to-Farmer Marketplace',
                title: 'Buy, Sell & Rent',
                subtitle:
                    'Publish a listing • Contact seller • Manage your posts',
                trailing: Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              AgriSection(
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: tr('Search item or district'),
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            ['All', 'Crop', 'Tool', 'Equipment', 'Service']
                                .map(
                                  (category) => Padding(
                                    padding: const EdgeInsets.only(right: 7),
                                    child: ChoiceChip(
                                      label: Text(tr(category)),
                                      selected: _category == category,
                                      onSelected: (_) {
                                        setState(() => _category = category);
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else if (snapshot.hasError)
                AgriSection(
                  child: Text(
                    FirebaseBackend.friendlyMessage(snapshot.error!),
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (listings.isEmpty)
                AgriSection(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 38,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 8),
                      Text(tr('No matching listings. Create the first one.')),
                    ],
                  ),
                )
              else
                ...listings.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: _ListingCard(
                      listing: listing,
                      onTap: () => _openListing(listing),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              AgriPrimaryButton(
                label: 'Create New Listing',
                icon: Icons.add_business_rounded,
                onPressed: _createListing,
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  'AgriAI does not process payments. Confirm quality, price and delivery directly with the seller.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onTap});

  final Map<String, dynamic> listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = listing['category']?.toString() ?? 'Crop';
    final icon = switch (category) {
      'Tool' => Icons.handyman_rounded,
      'Equipment' => Icons.agriculture_rounded,
      'Service' => Icons.miscellaneous_services_rounded,
      _ => Icons.eco_rounded,
    };
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.backgroundDeep,
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['item']?.toString() ?? tr('Market listing'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${listing['quantity'] ?? '-'} ${listing['unit'] ?? ''} • ${tr(listing['district']?.toString() ?? '')}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      listing['ownerName']?.toString() ?? tr('Farmer'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    listing['price']?.toString() ?? tr('Contact seller'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
