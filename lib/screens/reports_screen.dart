import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../services/firebase_backend.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _format = 'PDF';
  String _scope = 'All';
  bool _generating = false;
  late final Future<FarmReportSummary> _summary = ReportService.loadSummary();

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final format = _format == 'Print' ? 'PDF' : _format;
      await ReportService.generateAndShare(format: format, scope: _scope);
      await FirebaseBackend.saveReportRequest('$_scope $_format');
      if (mounted) {
        showDemoMessage(
          context,
          'Report created. Choose an app to save, print or share it.',
        );
      }
    } catch (error) {
      if (mounted) {
        showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: 'Reports',
      subtitle: 'Real farm analytics and downloadable files',
      child: Column(
        children: [
          const AgriHeroCard(
            eyebrow: 'Farm Data Report',
            title: 'Professional Summary',
            subtitle: 'Crop • Disease • Profit • Farm records',
            trailing: Icon(
              Icons.assessment_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          FutureBuilder<FarmReportSummary>(
            future: _summary,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return AgriSection(
                  child: Text(FirebaseBackend.friendlyMessage(snapshot.error!)),
                );
              }
              final item = snapshot.requireData;
              return AgriSection(
                title: 'Your Data Summary',
                child: Column(
                  children: [
                    AgriInfoRow('Active Farms', '${item.farms}'),
                    AgriInfoRow(
                      'Crop Recommendations',
                      '${item.recommendations}',
                    ),
                    AgriInfoRow('Disease Scans', '${item.diseaseScans}'),
                    AgriInfoRow('Profit Plans', '${item.profitPlans}'),
                  ],
                ),
              );
            },
          ),
          AgriSection(
            title: 'Report Content',
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: ['All', 'Crop', 'Disease', 'Profit']
                  .map(
                    (value) => AgriChip(
                      label: value,
                      selected: _scope == value,
                      onTap: () => setState(() => _scope = value),
                    ),
                  )
                  .toList(),
            ),
          ),
          AgriSection(
            title: 'Export Format',
            child: Wrap(
              spacing: 9,
              children: ['PDF', 'Excel', 'Print']
                  .map(
                    (value) => AgriChip(
                      label: value,
                      selected: _format == value,
                      onTap: () => setState(() => _format = value),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          AgriPrimaryButton(
            label: _generating
                ? 'Creating report...'
                : 'Create & Share $_format Report',
            icon: Icons.file_download_rounded,
            onPressed: _generating ? null : _generate,
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'PDF is printable. Excel creates a CSV file that opens in spreadsheet apps.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
