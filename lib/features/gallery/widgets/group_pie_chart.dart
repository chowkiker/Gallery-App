import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/photo.dart';
import 'dart:math' as math;

class GroupPieChart extends StatelessWidget {
  final Map<String, List<Photo>> groupedPhotos;
  final String groupBy;

  const GroupPieChart({
    super.key,
    required this.groupedPhotos,
    required this.groupBy,
  });

  @override
  Widget build(BuildContext context) {
    if (groupedPhotos.isEmpty) return const SizedBox.shrink();

    final keys = groupedPhotos.keys.toList();
    final total = groupedPhotos.values.fold(0, (sum, list) => sum + list.length);
    if (total == 0) return const SizedBox.shrink();

    final colors = [
      AppTheme.primary,
      AppTheme.accent,
      AppTheme.success,
      AppTheme.warn,
      const Color(0xFF8B5CF6),
      const Color(0xFFF43F5E),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];

    List<PieSegment> segments = [];
    for (int i = 0; i < keys.length; i++) {
      final k = keys[i];
      final count = groupedPhotos[k]!.length;
      segments.add(PieSegment(
        label: k,
        count: count,
        color: colors[i % colors.length],
        pct: count / total,
      ));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: AppTheme.shadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Distribution by $groupBy", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.text)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 80, height: 80,
                child: CustomPaint(
                  painter: _PieChartPainter(segments),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: segments.map((s) => Expanded(
                          flex: (s.pct * 1000).toInt(),
                          child: Container(color: s.color),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: segments.take(6).map((s) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text("${s.label} (${s.count})", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSub)),
                        ],
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PieSegment {
  final String label;
  final int count;
  final Color color;
  final double pct;

  PieSegment({required this.label, required this.count, required this.color, required this.pct});
}

class _PieChartPainter extends CustomPainter {
  final List<PieSegment> segments;
  _PieChartPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double startAngle = -math.pi / 2;

    for (var s in segments) {
      final sweepAngle = s.pct * 2 * math.pi;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
