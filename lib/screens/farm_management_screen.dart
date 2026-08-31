import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/crop_catalog.dart';
import '../services/firebase_backend.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  Future<void> _addFarm() async {
    final name = TextEditingController();
    final area = TextEditingController(text: '1');
    final notes = TextEditingController();
    var crop = CropCatalog.crops.first.name;
    var plantedOn = DateTime.now();
    var harvestOn = DateTime.now().add(const Duration(days: 120));
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr('Add New Farm')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: tr('Farm Name')),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: crop,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tr('Current Crop')),
                  items: CropCatalog.crops
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.name,
                          child: Text('${item.emoji} ${tr(item.name)}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => crop = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: area,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: tr('Area in acres')),
                ),
                const SizedBox(height: 10),
                _DateField(
                  label: 'Planting Date',
                  value: plantedOn,
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 730),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                      initialDate: plantedOn,
                    );
                    if (value != null) {
                      setDialogState(() => plantedOn = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _DateField(
                  label: 'Expected Harvest',
                  value: harvestOn,
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      firstDate: plantedOn,
                      lastDate: plantedOn.add(const Duration(days: 730)),
                      initialDate: harvestOn.isBefore(plantedOn)
                          ? plantedOn
                          : harvestOn,
                    );
                    if (value != null) {
                      setDialogState(() => harvestOn = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '${tr('Notes')} (${tr('Optional')})',
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
                final acres = double.tryParse(area.text.trim());
                if (name.text.trim().isEmpty || acres == null || acres <= 0) {
                  showDemoMessage(context, 'Enter farm name and valid area.');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(tr('Save Farm')),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      try {
        await FirebaseBackend.addFarm(
          name: name.text.trim(),
          crop: crop,
          acres: double.parse(area.text.trim()),
          plantedOn: plantedOn,
          harvestOn: harvestOn,
          notes: notes.text,
        );
        if (mounted) showDemoMessage(context, 'Farm saved successfully.');
      } catch (error) {
        if (mounted) {
          showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
        }
      }
    }
    name.dispose();
    area.dispose();
    notes.dispose();
  }

  Future<void> _deleteFarm(Map<String, dynamic> farm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Delete Farm')),
        content: Text('${tr('Remove')} ${farm['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseBackend.deleteFarm(farm['id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseBackend.farmsStream(),
      builder: (context, snapshot) {
        final farms = snapshot.data ?? const <Map<String, dynamic>>[];
        final harvests =
            farms.where((farm) {
              final date = farm['harvestOn'];
              return date is Timestamp && date.toDate().isAfter(DateTime.now());
            }).toList()..sort(
              (a, b) => (a['harvestOn'] as Timestamp).compareTo(
                b['harvestOn'] as Timestamp,
              ),
            );
        return AgriPage(
          title: 'Farm Management',
          subtitle: 'Crop, area and harvest tracking in one place',
          child: Column(
            children: [
              AgriHeroCard(
                eyebrow: 'My Farms',
                title: '${farms.length} Active Farms',
                subtitle: harvests.isEmpty
                    ? 'Add planting and harvest dates'
                    : '${harvests.length} upcoming harvests',
                trailing: const Icon(
                  Icons.agriculture_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (snapshot.hasError)
                AgriSection(
                  child: Text(FirebaseBackend.friendlyMessage(snapshot.error!)),
                )
              else if (farms.isEmpty)
                AgriSection(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.add_business_rounded,
                        size: 42,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(tr('No farms yet. Add your first farm.')),
                    ],
                  ),
                )
              else
                ...farms.map(
                  (farm) =>
                      _FarmCard(farm: farm, onDelete: () => _deleteFarm(farm)),
                ),
              if (harvests.isNotEmpty)
                AgriSection(
                  title: 'Next Harvest',
                  child: _HarvestRow(farm: harvests.first),
                ),
              const SizedBox(height: 14),
              AgriPrimaryButton(
                label: 'Add New Farm',
                icon: Icons.add_rounded,
                onPressed: _addFarm,
              ),
              const SizedBox(height: 10),
              AgriPrimaryButton(
                label: 'Open Free Farm Map',
                icon: Icons.map_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.farmMap),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.calendar_month_rounded),
    title: Text(tr(label)),
    subtitle: Text(DateFormat('dd MMM yyyy').format(value)),
    trailing: const Icon(Icons.edit_calendar_rounded),
    onTap: onTap,
  );
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm, required this.onDelete});
  final Map<String, dynamic> farm;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final harvest = farm['harvestOn'] is Timestamp
        ? (farm['harvestOn'] as Timestamp).toDate()
        : null;
    return AgriSection(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.backgroundDeep,
            child: Icon(Icons.grass_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm['name']?.toString() ?? 'Farm',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  '${tr(farm['crop']?.toString() ?? 'Not selected')} • ${farm['area'] ?? '-'}\n${tr(farm['location']?.toString() ?? '-')}\n${harvest == null ? tr('Harvest date not set') : '${tr('Harvest')}: ${DateFormat('dd MMM yyyy').format(harvest)}'}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'analytics') {
                Navigator.pushNamed(context, AppRoutes.farmAnalytics);
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'analytics', child: Text(tr('Analytics'))),
              PopupMenuItem(value: 'delete', child: Text(tr('Delete'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _HarvestRow extends StatelessWidget {
  const _HarvestRow({required this.farm});
  final Map<String, dynamic> farm;

  @override
  Widget build(BuildContext context) {
    final date = (farm['harvestOn'] as Timestamp).toDate();
    final days = date.difference(DateTime.now()).inDays + 1;
    return Row(
      children: [
        const Icon(Icons.event_available_rounded, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${farm['name']} • $days ${tr('days remaining')}\n${DateFormat('dd MMM yyyy').format(date)}',
          ),
        ),
      ],
    );
  }
}
