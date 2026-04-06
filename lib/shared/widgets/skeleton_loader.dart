import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final shimmer = Color.lerp(AppTheme.shimmerBase, AppTheme.shimmerHighlight, _anim.value)!;
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _bar(shimmer, 140, 28, 10),
                  const SizedBox(height: 16),
                  _bar(shimmer, double.infinity, 44, 24),
                  const SizedBox(height: 16),
                  _bar(shimmer, double.infinity, 80, 16),
                  const SizedBox(height: 20),
                  _bar(shimmer, 120, 20, 8),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
                    ),
                    itemCount: 18,
                    itemBuilder: (_, __) => Container(
                      decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _bar(Color color, double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
    );
  }
}
