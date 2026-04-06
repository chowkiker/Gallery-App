import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RatingBar extends StatelessWidget {
  final int? rating;
  final ValueChanged<int?> onRate;

  const RatingBar({super.key, required this.rating, required this.onRate});

  @override
  Widget build(BuildContext context) {
    final ratings = [
      {'n': 1, 'label': 'Poor', 'color': AppTheme.danger, 'bg': AppTheme.dangerBg},
      {'n': 2, 'label': 'Average', 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'n': 3, 'label': 'OK', 'color': AppTheme.warn, 'bg': AppTheme.warnBg},
      {'n': 4, 'label': 'Good', 'color': AppTheme.primary, 'bg': AppTheme.primaryBg},
      {'n': 5, 'label': 'Excellent', 'color': AppTheme.success, 'bg': AppTheme.successBg},
    ];

    return Container(
      color: AppTheme.bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: ratings.map((r) {
          final n = r['n'] as int;
          final active = rating == n;
          final color = r['color'] as Color;
          final bg = r['bg'] as Color;
          
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: n < 5 ? 5 : 0),
              child: InkWell(
                onTap: () => onRate(active ? null : n),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  decoration: BoxDecoration(
                    color: active ? bg : AppTheme.card,
                    border: Border.all(color: active ? color : AppTheme.border, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$n★",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: active ? color : AppTheme.textMuted,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      Text(
                        r['label'] as String,
                        style: TextStyle(
                          fontSize: 7,
                          color: active ? color : AppTheme.textMuted,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
