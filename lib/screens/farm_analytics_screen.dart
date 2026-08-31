import 'package:flutter/material.dart';
import '../localization/app_language.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class FarmAnalyticsScreen extends StatelessWidget {
  const FarmAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: 'Farm Analytics',
      subtitle: 'AI insights for your farm performance',
      child: Column(
        children: [
          const AgriHeroCard(
            eyebrow: 'Farm Health Score',
            title: '92%',
            subtitle: 'Excellent crop condition',
            trailing: Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Yield',
                  value: '4.8 T',
                  icon: Icons.grass_rounded,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Profit',
                  value: 'Rs.185K',
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
          AgriSection(
            title: 'Monthly Performance',
            child: SizedBox(
              height: 145,
              width: double.infinity,
              child: CustomPaint(painter: _PerformanceChartPainter()),
            ),
          ),
          AgriSection(
            title: 'AI Insights',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('• Yield increased by 12% this month.')),
                const SizedBox(height: 7),
                Text(tr('• Water usage reduced by 18%.')),
                const SizedBox(height: 7),
                Text(tr('• Harvest expected in 12 days.')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AgriPrimaryButton(
            label: 'Refresh Analytics',
            icon: Icons.refresh_rounded,
            onPressed: () =>
                showDemoMessage(context, 'Farm analytics refreshed'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 11),
          Text(
            tr(label),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE5EFE6)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final values = [0.78, 0.62, 0.68, 0.39, 0.48, 0.27, 0.18];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(
        size.width * i / (values.length - 1),
        size.height * values[i],
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
