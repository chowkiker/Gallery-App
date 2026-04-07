import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class QueuePanel extends StatelessWidget {
  /// Photo IDs queued for deletion.
  final Set<String> deleteQueue;

  /// Maps photoId → targetFolder for pending moves.
  final Map<String, String> moveQueue;

  /// Maps photoId → targetFolder for pending copies.
  final Map<String, String> copyQueue;

  final VoidCallback onCancel;
  final VoidCallback onApply;

  const QueuePanel({
    super.key,
    required this.deleteQueue,
    required this.moveQueue,
    required this.copyQueue,
    required this.onCancel,
    required this.onApply,
  });

  void _showReview(BuildContext context) {
    // Group move/copy entries by target folder for a readable summary.
    final moveByFolder = <String, int>{};
    for (final folder in moveQueue.values) {
      moveByFolder[folder] = (moveByFolder[folder] ?? 0) + 1;
    }
    final copyByFolder = <String, int>{};
    for (final folder in copyQueue.values) {
      copyByFolder[folder] = (copyByFolder[folder] ?? 0) + 1;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: const BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48, height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2.5)),
                ),
              ),
              const Center(
                child: Text("Review Changes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.text, fontFamily: AppTheme.fontFamily)),
              ),
              const SizedBox(height: 24),
              if (deleteQueue.isNotEmpty) ...[
                _buildActionRow("🗑", "${deleteQueue.length} items to Delete", AppTheme.dangerBg, AppTheme.danger),
                const SizedBox(height: 12),
              ],
              ...moveByFolder.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActionRow("📁", "${e.value} items to Move → ${e.key}", AppTheme.primaryBg, AppTheme.primary),
              )),
              ...copyByFolder.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActionRow("📋", "${e.value} items to Copy → ${e.key}", AppTheme.successBg, AppTheme.success),
              )),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onApply();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Confirm Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: AppTheme.fontFamily)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSub,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Cancel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily)),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildActionRow(String icon, String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, fontFamily: AppTheme.fontFamily)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (deleteQueue.isEmpty && moveQueue.isEmpty && copyQueue.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          const Text("⏳", style: TextStyle(fontSize: 14)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Pending Actions", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.text, fontFamily: AppTheme.fontFamily)),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 7, runSpacing: 4,
                  children: [
                    if (deleteQueue.isNotEmpty)
                      Text("🗑 ${deleteQueue.length} delete", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.danger, fontFamily: AppTheme.fontFamily)),
                    if (moveQueue.isNotEmpty)
                      Text("📁 ${moveQueue.length} move", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary, fontFamily: AppTheme.fontFamily)),
                    if (copyQueue.isNotEmpty)
                      Text("📋 ${copyQueue.length} copy", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.success, fontFamily: AppTheme.fontFamily)),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.bg,
              foregroundColor: AppTheme.textSub,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
            child: const Text("Cancel", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _showReview(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              elevation: 0,
            ),
            child: const Text("Done ✓", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, fontFamily: AppTheme.fontFamily)),
          ),
        ],
      ),
    );
  }
}
