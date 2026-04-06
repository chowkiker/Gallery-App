import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../models/photo.dart';
import '../models/app_folder.dart';

class MoveCopyTray extends StatefulWidget {
  final List<Photo> selectedPhotos;
  final bool hideBanner;
  final ValueChanged<String> onMove;
  final ValueChanged<String> onCopy;
  final VoidCallback onDelete;
  final List<AppFolder> folders;
  final ValueChanged<AppFolder> onAddFolder;
  final int pendingCount;
  final VoidCallback onApplyPending;
  final VoidCallback onCancelPending;

  const MoveCopyTray({
    super.key,
    required this.selectedPhotos,
    required this.hideBanner,
    required this.onMove,
    required this.onCopy,
    required this.onDelete,
    required this.folders,
    required this.onAddFolder,
    required this.pendingCount,
    required this.onApplyPending,
    required this.onCancelPending,
  });

  @override
  State<MoveCopyTray> createState() => _MoveCopyTrayState();
}

class _MoveCopyTrayState extends State<MoveCopyTray> {
  String _mode = 'move';
  String? _selectedAction; // 'delete' or folder.name
  bool _busy = false;

  void _handleApply() async {
    if (_selectedAction == null || _busy) return;
    setState(() => _busy = true);

    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_selectedAction == 'delete') {
      widget.onDelete();
    } else {
      if (_mode == 'move') {
        widget.onMove(_selectedAction!);
      } else {
        widget.onCopy(_selectedAction!);
      }
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.selectedPhotos.length;
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [BoxShadow(color: AppTheme.shadowDeep, blurRadius: 24, offset: Offset(0, -6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48, height: 4,
              margin: const EdgeInsets.only(top: 14, bottom: 20),
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _modeButton('move', 'Move Mode', Icons.drive_file_move_outline),
                const SizedBox(width: 16),
                _modeButton('copy', 'Copy Mode', Icons.copy_rounded),
              ],
            ),
          ),
            
          const SizedBox(height: 16),
          
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildActionBlock(
                  id: 'delete',
                  label: 'DELETE',
                  icon: Icons.delete_outline,
                  isDestructive: true,
                ),
                ...widget.folders.map((f) => _buildActionBlock(
                  id: f.name,
                  label: f.name.toUpperCase(),
                  icon: Icons.folder_outlined,
                  isDestructive: false,
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  "$count photo${count > 1 ? 's' : ''} selected",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.text, fontFamily: AppTheme.fontFamily),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selectedAction != null && !_busy ? _handleApply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.border,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _busy 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Apply Changes", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String id, String label, IconData icon) {
    final active = _mode == id;
    final color = active ? AppTheme.primary : AppTheme.textMuted;
    final bgColor = active ? AppTheme.primaryBg : Colors.transparent;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? AppTheme.primary : AppTheme.border, width: active ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBlock({required String id, required String label, required IconData icon, required bool isDestructive}) {
    final isSelected = _selectedAction == id;
    
    Color baseColor = isDestructive ? AppTheme.danger : AppTheme.textSub;
    Color activeColor = isDestructive ? AppTheme.danger : AppTheme.primary;
    Color bgColor = isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent;
    Color borderColor = isSelected ? activeColor : AppTheme.border;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedAction = id),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: isSelected ? 3 : 1),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: isSelected ? activeColor : baseColor, size: 28),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 64,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : baseColor,
                  fontFamily: AppTheme.fontFamily,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
