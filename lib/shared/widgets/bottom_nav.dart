import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onChange;

  const BottomNav({super.key, required this.activeTab, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      {'id': 'organize', 'label': 'Photos',  'icon': Icons.image_outlined,        'activeIcon': Icons.image_rounded},
      {'id': 'albums',   'label': 'Albums',  'icon': Icons.photo_album_outlined,   'activeIcon': Icons.photo_album_rounded},
      {'id': 'manage',   'label': 'Manage',  'icon': Icons.tune_outlined,          'activeIcon': Icons.tune_rounded},
    ];

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.navBg.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [BoxShadow(color: AppTheme.shadowDeep, blurRadius: 28, offset: Offset(0, 10))],
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tabs.map((t) {
                  final active = activeTab == t['id'];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChange(t['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            active ? t['activeIcon'] as IconData : t['icon'] as IconData,
                            color: active ? Colors.white : AppTheme.textMuted,
                            size: 22,
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: active
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      t['label'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
