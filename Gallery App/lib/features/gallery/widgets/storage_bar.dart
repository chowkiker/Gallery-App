import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/photo.dart';

class StorageBar extends StatelessWidget {
  final List<Photo> photos;

  const StorageBar({super.key, required this.photos});

  String _fmtGB(double mb) {
    if (mb >= 1024) {
      return "${(mb / 1024).toStringAsFixed(1)} GB";
    }
    return "${mb.round()} MB";
  }

  @override
  Widget build(BuildContext context) {
    const double totalMB = 32 * 1024;
    const double otherMB = 2048;

    double photosMB = 0;
    double videosMB = 0;
    for (var p in photos) {
      if (p.type == 'video') {
        videosMB += p.sizeMB;
      } else {
        photosMB += p.sizeMB;
      }
    }

    double freeMB = totalMB - photosMB - videosMB - otherMB;
    if (freeMB < 0) freeMB = 0;

    final usedPct = (((photosMB + videosMB + otherMB) / totalMB) * 100).clamp(0, 100).toStringAsFixed(0);

    final segs = [
      {'label': 'Photos', 'pct': (photosMB / totalMB * 100).clamp(0.2, 100.0), 'color': const Color(0xFF4A7BF7), 'mb': photosMB},
      {'label': 'Videos', 'pct': (videosMB / totalMB * 100).clamp(0.2, 100.0), 'color': const Color(0xFF38BDF8), 'mb': videosMB},
      {'label': 'Other', 'pct': (otherMB / totalMB * 100).clamp(0.2, 100.0), 'color': const Color(0xFFF59E0B), 'mb': otherMB},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.shadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    "Storage",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.text, fontFamily: AppTheme.fontFamily),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "$usedPct% used",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary, fontFamily: AppTheme.fontFamily),
                    ),
                  ),
                ],
              ),
              Text(
                "${_fmtGB(freeMB)} free · ${_fmtGB(totalMB)}",
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: AppTheme.fontFamily),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            height: 9,
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(
                children: segs.map((s) {
                  return Expanded(
                    flex: ((s['pct'] as num) * 100).toInt(),
                    child: Container(color: s['color'] as Color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              ...segs.map((s) => Row(
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: s['color'] as Color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 5),
                  Text(s['label'] as String, style: const TextStyle(fontSize: 10, color: AppTheme.textSub, fontFamily: AppTheme.fontFamily)),
                  const SizedBox(width: 3),
                  Text(_fmtGB(s['mb'] as double), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: AppTheme.fontFamily)),
                  const SizedBox(width: 12),
                ],
              )),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 7, height: 7, 
                    decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(2), border: Border.all(color: AppTheme.border)),
                  ),
                  const SizedBox(width: 5),
                  Text("Free ${_fmtGB(freeMB)}", style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: AppTheme.fontFamily)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
