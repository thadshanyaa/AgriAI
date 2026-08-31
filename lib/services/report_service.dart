import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'firebase_backend.dart';

class FarmReportSummary {
  const FarmReportSummary({
    required this.farmerName,
    required this.district,
    required this.farms,
    required this.recommendations,
    required this.diseaseScans,
    required this.profitPlans,
    required this.totalExpectedProfit,
    required this.latestCrop,
    required this.latestDiseaseResult,
  });

  final String farmerName;
  final String district;
  final int farms;
  final int recommendations;
  final int diseaseScans;
  final int profitPlans;
  final double totalExpectedProfit;
  final String latestCrop;
  final String latestDiseaseResult;
}

abstract final class ReportService {
  static Future<FarmReportSummary> loadSummary() async {
    final user = FirebaseBackend.currentUser;
    if (user == null) throw StateError('Please login again.');
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final results = await Future.wait([
      userRef.get(),
      userRef.collection('farms').get(),
      userRef.collection('recommendations').get(),
      userRef.collection('diseaseScans').get(),
      userRef.collection('profitPlans').get(),
    ]);
    final profile = (results[0] as DocumentSnapshot<Map<String, dynamic>>)
        .data();
    final farms = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final recommendations = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final diseaseScans = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final profitPlans = results[4] as QuerySnapshot<Map<String, dynamic>>;

    final totalProfit = profitPlans.docs.fold<double>(
      0,
      (total, doc) =>
          total + ((doc.data()['expectedProfit'] as num?)?.toDouble() ?? 0),
    );
    return FarmReportSummary(
      farmerName:
          profile?['fullName']?.toString() ?? user.displayName ?? 'Farmer',
      district: profile?['district']?.toString() ?? '-',
      farms: farms.size,
      recommendations: recommendations.size,
      diseaseScans: diseaseScans.size,
      profitPlans: profitPlans.size,
      totalExpectedProfit: totalProfit,
      latestCrop: _latestValue(recommendations.docs, 'recommendedCrop'),
      latestDiseaseResult: _latestValue(diseaseScans.docs, 'result'),
    );
  }

  static String _latestValue(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    String field,
  ) {
    if (documents.isEmpty) return 'No data';
    final sorted = documents.toList()
      ..sort((a, b) {
        final first = a.data()['createdAt'] as Timestamp?;
        final second = b.data()['createdAt'] as Timestamp?;
        return (second?.millisecondsSinceEpoch ?? 0).compareTo(
          first?.millisecondsSinceEpoch ?? 0,
        );
      });
    return sorted.first.data()[field]?.toString() ?? 'No data';
  }

  static Future<String> generateAndShare({
    required String format,
    required String scope,
  }) async {
    final summary = await loadSummary();
    final directory = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    late final File file;
    if (format == 'Excel') {
      file = File('${directory.path}/AgriAI_${scope}_$stamp.csv');
      await file.writeAsString(_csv(summary, scope), flush: true);
    } else {
      file = File('${directory.path}/AgriAI_${scope}_$stamp.pdf');
      await file.writeAsBytes(await _pdf(summary, scope), flush: true);
    }
    await SharePlus.instance.share(
      ShareParams(
        subject: 'AgriAI $scope Report',
        text:
            'AgriAI farm report generated ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
        files: [XFile(file.path)],
      ),
    );
    return file.path;
  }

  static String _csv(FarmReportSummary summary, String scope) {
    final rows = <List<Object>>[
      ['AgriAI Professional Farm Report', scope],
      ['Generated', DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())],
      ['Farmer', summary.farmerName],
      ['District', summary.district],
      ['Active farms', summary.farms],
      ['Crop recommendations', summary.recommendations],
      ['Disease scans', summary.diseaseScans],
      ['Profit plans', summary.profitPlans],
      ['Latest recommended crop', summary.latestCrop],
      ['Latest disease result', summary.latestDiseaseResult],
      [
        'Total expected profit (LKR)',
        summary.totalExpectedProfit.toStringAsFixed(0),
      ],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  static String _csvCell(Object value) =>
      '"${value.toString().replaceAll('"', '""')}"';

  static Future<List<int>> _pdf(FarmReportSummary summary, String scope) async {
    final document = pw.Document(
      title: 'AgriAI $scope Report',
      author: 'AgriAI Smart Farming',
    );
    final green = PdfColor.fromHex('#17823B');
    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: green, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'AgriAI SMART FARMING',
                style: pw.TextStyle(
                  color: green,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('$scope REPORT'),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 24),
          pw.Text(
            '$scope Farm Report',
            style: pw.TextStyle(
              fontSize: 26,
              color: green,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            color: PdfColor.fromHex('#EDF8EF'),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Farmer',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(summary.farmerName),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'District',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(summary.district),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Activity Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Result'],
            data: [
              ['Active farms', '${summary.farms}'],
              ['Crop recommendations', '${summary.recommendations}'],
              ['Disease scans', '${summary.diseaseScans}'],
              ['Profit plans', '${summary.profitPlans}'],
              ['Latest recommended crop', summary.latestCrop],
              ['Latest disease result', summary.latestDiseaseResult],
              [
                'Total expected profit',
                'LKR ${NumberFormat('#,##0').format(summary.totalExpectedProfit)}',
              ],
            ],
            headerDecoration: pw.BoxDecoration(color: green),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellPadding: const pw.EdgeInsets.all(9),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Important note',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Predictions, yield, prices and profit are planning estimates. Confirm current market prices, soil tests and treatment decisions with official sources or the Sri Lanka agriculture advisory service 1920.',
          ),
        ],
      ),
    );
    return document.save();
  }
}
