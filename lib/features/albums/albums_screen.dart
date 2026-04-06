import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/photo.dart';
import '../../shared/models/app_folder.dart';

class AlbumsScreen extends StatelessWidget {
  final List<Photo> photos;
  final List<AppFolder> folders;
  final Function(dynamic filter, String title) onOpenFilter;

  const AlbumsScreen({
    super.key,
    required this.photos,
    required this.folders,
    required this.onOpenFilter,
  });

  int _getCount(String name) {
    if (name == "Camera") return photos.where((p) => p.folder == null || p.folder == "Camera").length;
    if (name == "Screenshots") return photos.where((p) => p.type == "screenshot" || p.folder == "Screenshots").length;
    return photos.where((p) => p.folder == name).length;
  }

  int _getRatingCount(int rating) {
    return photos.where((p) => p.rating == rating).length;
  }

  double _getSizeMB(String name) {
    Iterable<Photo> arr;
    if (name == "Camera") {
      arr = photos.where((p) => p.folder == null || p.folder == "Camera");
    } else {
      arr = photos.where((p) => p.folder == name);
    }
    return arr.fold(0.0, (s, p) => s + p.sizeMB);
  }

  String _fmtGB(double mb) {
    if (mb >= 1024) return "${(mb / 1024).toStringAsFixed(1)} GB";
    return "${mb.toStringAsFixed(1)} MB";
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text("Albums", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.text, fontFamily: AppTheme.fontFamily, letterSpacing: -0.8)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              children: [
                const Text("SMART FILTERS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSub, fontFamily: AppTheme.fontFamily, letterSpacing: 0.5)),
                const SizedBox(height: 9),
                _buildSmartFilters(),
                const SizedBox(height: 24),
                const Text("MY FOLDERS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSub, fontFamily: AppTheme.fontFamily, letterSpacing: 0.5)),
                const SizedBox(height: 9),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: folders.length,
                  itemBuilder: (context, i) {
                    final f = folders[i];
                    final cnt = _getCount(f.name);
                    final sz = _getSizeMB(f.name);

                    return InkWell(
                      onTap: () => onOpenFilter({'kind': 'folder', 'id': f.name}, f.name),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: const [BoxShadow(color: AppTheme.shadow, blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: -10, right: -10,
                              child: Opacity(
                                opacity: 0.12,
                                child: const Icon(Icons.folder, size: 80, color: AppTheme.primary),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(11)),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.folder_outlined, color: AppTheme.primary, size: 22),
                                ),
                                const Spacer(),
                                Text(f.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.text, fontFamily: AppTheme.fontFamily), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text("$cnt photos", style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: AppTheme.fontFamily)),
                                const SizedBox(height: 1),
                                Text(_fmtGB(sz), style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontFamily: AppTheme.fontFamily)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartFilters() {
    final filters = [
      {'val': 5, 'label': 'Excellent', 'color': AppTheme.success, 'emoji': '🤩'},
      {'val': 4, 'label': 'Good', 'color': AppTheme.primary, 'emoji': '🙂'},
      {'val': 3, 'label': 'OK', 'color': AppTheme.warn, 'emoji': '😐'},
      {'val': 2, 'label': 'Average', 'color': const Color(0xFFF97316), 'emoji': '😕'},
      {'val': 1, 'label': 'Poor', 'color': AppTheme.danger, 'emoji': '🗑️'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: filters.length,
      itemBuilder: (context, i) {
        final f = filters[i];
        final val = f['val'] as int;
        final label = f['label'] as String;
        final color = f['color'] as Color;
        final emoji = f['emoji'] as String;
        final cnt = _getRatingCount(val);

        return InkWell(
          onTap: () => onOpenFilter({'kind': 'rating', 'value': val}, label),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color, fontFamily: AppTheme.fontFamily)),
                      const SizedBox(height: 2),
                      Text("$cnt items", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7), fontFamily: AppTheme.fontFamily)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
