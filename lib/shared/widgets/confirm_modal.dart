import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConfirmModal extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final bool danger;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmModal({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.danger = false,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text, fontFamily: AppTheme.fontFamily),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSub, fontFamily: AppTheme.fontFamily),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text("Cancel", style: TextStyle(color: AppTheme.textSub, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: danger ? AppTheme.danger : AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
