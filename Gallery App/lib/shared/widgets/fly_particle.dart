import 'package:flutter/material.dart';

class FlyParticle extends StatefulWidget {
  final String emoji;
  final GlobalKey? targetKey;
  final VoidCallback onDone;

  const FlyParticle({
    super.key,
    required this.emoji,
    this.targetKey,
    required this.onDone,
  });

  @override
  State<FlyParticle> createState() => _FlyParticleState();
}

class _FlyParticleState extends State<FlyParticle> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 540));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0, curve: Curves.ease)));

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A proper implementation would use an Overlay and calculate target positions.
    // For now, it just scales down and fades out in the center of its container.
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Opacity(
                opacity: _opAnim.value,
                child: Container(
                  decoration: const BoxDecoration(
                    boxShadow: [BoxShadow(color: Color(0x594A7BF7), blurRadius: 18, offset: Offset(0, 6))],
                  ),
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 68)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
