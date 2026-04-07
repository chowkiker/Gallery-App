import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/photo.dart';
import '../../shared/models/app_folder.dart';
import '../../shared/widgets/move_copy_tray.dart';
import '../../shared/widgets/rating_bar.dart';
import 'widgets/storage_bar.dart';
import 'widgets/folder_selector.dart';
import 'widgets/group_pie_chart.dart';

class OrganizeScreen extends StatefulWidget {
  final List<Photo> photos;
  final List<AppFolder> folders;
  final String? activeFolder;
  final ValueChanged<String> onSelectFolder;
  final int gridCols;
  final ValueChanged<int> setGridCols;
  final ValueChanged<int> onSwipe;
  final Function(Set<String>) addToDeleteQueue;
  final Function(Set<String>, String) addToMoveQueue;
  final Function(Set<String>, String) addToCopyQueue;
  final int pendingDeleteCount;
  final int totalPendingCount;
  final VoidCallback cancelQueues;
  final VoidCallback applyPendingActions;
  final ValueChanged<AppFolder> onAddFolder;
  final Function(String, int) onRatePhoto;
  final Function(String, String) onOpenTimeline;

  const OrganizeScreen({
    super.key,
    required this.photos,
    required this.folders,
    this.activeFolder,
    required this.onSelectFolder,
    required this.gridCols,
    required this.setGridCols,
    required this.onSwipe,
    required this.addToDeleteQueue,
    required this.addToMoveQueue,
    required this.addToCopyQueue,
    required this.pendingDeleteCount,
    required this.totalPendingCount,
    required this.cancelQueues,
    required this.applyPendingActions,
    required this.onAddFolder,
    required this.onRatePhoto,
    required this.onOpenTimeline,
  });

  @override
  State<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _OrganizeScreenState extends State<OrganizeScreen> {
  final Set<String> _selected = {};
  bool _selMode = false;
  final ValueNotifier<String> _groupByNotifier = ValueNotifier('Month');

  @override
  void dispose() {
    _groupByNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(OrganizeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selection on folder change
    if (oldWidget.activeFolder != widget.activeFolder) {
      _selected.clear();
      _selMode = false;
    }
  }

  Future<AppFolder?> pickFolderAndLoadImages() async {
    // Placeholder to allow integration of file_picker or native directory picker.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Folder picker not yet implemented')),
    );
    return null;
  }

  void _cancelSelection() =>
      setState(() { _selMode = false; _selected.clear(); });

  /// Groups [widget.photos] by the current mode.
  Map<String, List<Photo>> _groupAssets(String groupByMode) {
    final monthFmt = DateFormat('MMMM yyyy');
    final yearFmt  = DateFormat('yyyy');
    final dayFmt   = DateFormat('MMM dd yyyy');
    final grouped  = <String, List<Photo>>{};

    for (final photo in widget.photos) {
      DateTime dt;
      if (photo.asset != null) {
        dt = photo.asset!.createDateTime;
      } else {
        try {
          dt = dayFmt.parse(photo.date);
        } catch (_) {
          dt = DateTime.now();
        }
      }

      final String key = groupByMode == 'Month'
          ? monthFmt.format(dt)
          : groupByMode == 'Year'
              ? yearFmt.format(dt)
              : dayFmt.format(dt);
      (grouped[key] ??= []).add(photo);
    }
    
    print("Grouped months: ${grouped.keys}");
    return grouped;
  }

  void _showBulkRateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rate ${_selected.length} photos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
            const SizedBox(height: 20),
            RatingBar(
              rating: null,
              onRate: (r) {
                for (final id in _selected) widget.onRatePhoto(id, r ?? 0);
                Navigator.pop(ctx);
                _cancelSelection();
              },
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final trayPhotos = _selMode && _selected.isNotEmpty
        ? widget.photos.where((p) => _selected.contains(p.id)).toList()
        : <Photo>[];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Organize', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -1)),
                  if (_selMode)
                    Row(children: [
                      TextButton(onPressed: _showBulkRateMenu, child: const Text('Rate ⭐', style: TextStyle(color: AppTheme.warn, fontWeight: FontWeight.w800))),
                      TextButton(onPressed: _cancelSelection,  child: const Text('Cancel', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
                    ]),
                ],
              ),
            ),
            // ── Folder selector ────────────────────────────────────────────
            FolderSelector(
              folders: widget.folders,
              activeFolder: widget.activeFolder ?? 'Camera',
              onSelectFolder: widget.onSelectFolder,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: GestureDetector(
                onTap: () async {
                  final folder = await pickFolderAndLoadImages();
                  if (folder != null) {
                    widget.onAddFolder(folder); // add to provider
                  }
                },
                child: const Chip(
                  label: Text("+ Browse 📁", style: TextStyle(fontWeight: FontWeight.w700)),
                  backgroundColor: AppTheme.primaryBg,
                  side: BorderSide.none,
                ),
              ),
            ),
            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _groupByNotifier,
                builder: (context, groupByMode, child) {
                  final grouped = _groupAssets(groupByMode);
                  final sortedKeys = grouped.keys.toList();

                  return ListView.builder(
                    itemCount: widget.photos.isEmpty ? 2 : sortedKeys.length + 2,
                    itemBuilder: (context, idx) {
                      if (idx == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StorageBar(photos: widget.photos),
                              GroupPieChart(
                                groupedPhotos: grouped.map((k, v) => MapEntry(k, v.length)),
                                groupBy: groupByMode,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBg, 
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: const ['Date', 'Month', 'Year'].map((mode) {
                                      final active = groupByMode == mode;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () => _groupByNotifier.value = mode,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(vertical: 9),
                                            decoration: BoxDecoration(
                                              color: active ? AppTheme.primary : Colors.transparent,
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              mode, 
                                              style: TextStyle(
                                                fontSize: 12, 
                                                fontWeight: active ? FontWeight.w800 : FontWeight.w600, 
                                                color: active ? Colors.white : AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (widget.photos.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library_outlined, size: 64, color: AppTheme.textMuted),
                                SizedBox(height: 16),
                                Text('No photos found in this folder', style: TextStyle(fontSize: 15, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                        );
                      }

                      if (idx == sortedKeys.length + 1) {
                        return const SizedBox(height: 120);
                      }

                      final mapIdx = idx - 1;
                      final key = sortedKeys[mapIdx];
                      final groupAssets = grouped[key]!;

                      const colors = [
                        AppTheme.primary,
                        AppTheme.accent,
                        AppTheme.success,
                        AppTheme.warn,
                        Color(0xFF8B5CF6),
                        Color(0xFFF43F5E),
                        Color(0xFF14B8A6),
                        Color(0xFFF97316),
                      ];
                      final dotColor = colors[mapIdx % colors.length];
                      final thumbPhoto = groupAssets.firstOrNull;

                      return InkWell(
                        onTap: () => widget.onOpenTimeline(key, groupByMode),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: thumbPhoto?.asset != null
                                      ? AssetEntityImage(
                                          thumbPhoto!.asset!,
                                          isOriginal: false,
                                          thumbnailSize: const ThumbnailSize(200, 200),
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        )
                                      : _mockThumb('?'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  key,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.text),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${groupAssets.length} photos',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomSheet: (_selMode && _selected.isNotEmpty)
          ? MoveCopyTray(
              selectedPhotos: trayPhotos,
              hideBanner: false,
              onMove: (f) { widget.addToMoveQueue(Set.from(_selected), f); _cancelSelection(); },
              onCopy: (f) { widget.addToCopyQueue(Set.from(_selected), f); _cancelSelection(); },
              onDelete: () { widget.addToDeleteQueue(Set.from(_selected)); _cancelSelection(); },
              folders: widget.folders,
              onAddFolder: widget.onAddFolder,
              pendingCount: widget.totalPendingCount,
              onApplyPending: widget.applyPendingActions,
              onCancelPending: widget.cancelQueues,
            )
          : null,
    );
  }

  Widget _mockThumb(String label) {
    // Deterministic color from label for web/mock items
    final colors = [AppTheme.primaryBg, AppTheme.dangerBg, AppTheme.successBg, AppTheme.warnBg];
    final idx = label.length % colors.length;
    return Container(
      color: colors[idx],
      alignment: Alignment.center,
      child: Text(label.isNotEmpty ? label[0].toUpperCase() : '?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textSub)),
    );
  }
}
