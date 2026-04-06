import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/photo.dart';
import '../../shared/models/app_folder.dart';
import '../../shared/widgets/move_copy_tray.dart';
import '../../shared/widgets/rating_bar.dart';
import '../../shared/widgets/confirm_modal.dart';
import '../../providers.dart';


class GridViewScreen extends StatefulWidget {
  final List<Photo> photos;
  final String title;
  final VoidCallback onBack;
  final ValueChanged<int> onSwipe;
  final List<AppFolder> folders;
  final ValueChanged<AppFolder> onAddFolder;
  final int gridCols;
  final ValueChanged<int> setGridCols;
  final Function(Set<String>) addToDeleteQueue;
  final Function(Set<String>, String) addToMoveQueue;
  final Function(Set<String>, String) addToCopyQueue;
  final int pendingDeleteCount;
  final int totalPendingCount;
  final VoidCallback cancelQueues;
  final VoidCallback applyPendingActions;
  final int? ratingFilter;
  final ValueChanged<int?> setRatingFilter;
  final Function(String, int?) onRatePhoto;

  const GridViewScreen({
    super.key,
    required this.photos,
    required this.title,
    required this.onBack,
    required this.onSwipe,
    required this.folders,
    required this.onAddFolder,
    required this.gridCols,
    required this.setGridCols,
    required this.addToDeleteQueue,
    required this.addToMoveQueue,
    required this.addToCopyQueue,
    required this.pendingDeleteCount,
    required this.totalPendingCount,
    required this.cancelQueues,
    required this.applyPendingActions,
    this.ratingFilter,
    required this.setRatingFilter,
    required this.onRatePhoto,
  });

  @override
  State<GridViewScreen> createState() => _GridViewScreenState();
}

class _GridViewScreenState extends State<GridViewScreen> {
  final Set<String> _selected = {};
  bool _selMode = false;
  bool _showRateBar = false;
  String? _queueToast;

  @override
  void initState() {
    super.initState();
    // Reset selection on screen open (requirement 4)
    _selected.clear();
    _selMode = false;
  }

  void _toggleItem(String id) {
    if (!_selMode) return;
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      if (_selected.isEmpty) _selMode = false;
    });
  }

  void _startTimer(String id) {
    setState(() {
      _selMode = true;
      _selected.add(id);
    });
  }

  void _cancelSelection() {
    setState(() {
      _selMode = false;
      _selected.clear();
      _showRateBar = false;
    });
  }

  void _selectAll() {
    setState(() {
      _selected.addAll(widget.photos.map((p) => p.id));
    });
  }

  void _showToast(String msg) {
    setState(() => _queueToast = msg);
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted && _queueToast == msg) {
        setState(() => _queueToast = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trayPhotos = _selMode && _selected.isNotEmpty
        ? widget.photos.where((p) => _selected.contains(p.id)).toList()
        : <Photo>[];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Stack(
              children: [
                _buildGrid(),
                if (_queueToast != null)
                  Positioned(
                    bottom: 250, left: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.text,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: const [BoxShadow(color: Color(0x401A2340), blurRadius: 20, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_queueToast!, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: AppTheme.fontFamily)),
                          TextButton(
                            onPressed: () {
                              widget.cancelQueues();
                              setState(() => _queueToast = null);
                            },
                            child: const Text("UNDO", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 11)),
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selMode && _selected.isNotEmpty) _buildActionBanner(),
          if (_selMode && _selected.isNotEmpty && _showRateBar)
            Container(
              color: AppTheme.bg,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
              child: Column(
                children: [
                  Text("Rate ${_selected.length} selected photo${_selected.length > 1 ? 's' : ''}", style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  RatingBar(
                    rating: null,
                    onRate: (r) {
                      for (var id in _selected) {
                        widget.onRatePhoto(id, r ?? 0);
                      }
                      setState(() => _showRateBar = false);
                      _cancelSelection();
                    },
                  ),
                ],
              ),
            ),
          MoveCopyTray(
            selectedPhotos: trayPhotos,
            hideBanner: !_selMode || _selected.isEmpty,
            onMove: (f) {
              widget.addToMoveQueue(Set.from(_selected), f);
              _cancelSelection();
            },
            onCopy: (f) {
              widget.addToCopyQueue(Set.from(_selected), f);
              _cancelSelection();
            },
            onDelete: () {
              widget.addToDeleteQueue(Set.from(_selected));
              _cancelSelection();
            },
            folders: widget.folders,
            onAddFolder: widget.onAddFolder,
            pendingCount: widget.totalPendingCount,
            onApplyPending: widget.applyPendingActions,
            onCancelPending: widget.cancelQueues,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: widget.onBack,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AppTheme.primaryBg, shape: BoxShape.circle),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.arrow_back, color: AppTheme.primary, size: 20),
                    if (widget.pendingDeleteCount > 0)
                      Positioned(
                        top: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle, border: Border.all(color: AppTheme.bg, width: 2)),
                          child: Text("${widget.pendingDeleteCount}", style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.text, overflow: TextOverflow.ellipsis)),
                  Row(
                    children: [
                      Text(
                        _selMode ? "${_selected.length} of ${widget.photos.length} selected" : "${widget.photos.length} photos",
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      if (widget.ratingFilter != null && !_selMode)
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: InkWell(
                            onTap: () => widget.setRatingFilter(null),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(5)),
                              child: Text("${widget.ratingFilter}★ ✕", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_selMode)
              Container(
                decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(9)),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [2, 3, 4].map((n) {
                    final active = widget.gridCols == n;
                    return GestureDetector(
                      onTap: () => widget.setGridCols(n),
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(color: active ? AppTheme.primary : AppTheme.bg, borderRadius: BorderRadius.circular(7)),
                        alignment: Alignment.center,
                        child: Text("$n", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : AppTheme.textMuted)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (!_selMode)
              Row(
                children: [
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => widget.pendingDeleteCount > 0 ? widget.applyPendingActions() : null,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: widget.pendingDeleteCount > 0 ? AppTheme.dangerBg : AppTheme.bg, shape: BoxShape.circle),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text("🗑", style: TextStyle(fontSize: 16)),
                          if (widget.pendingDeleteCount > 0)
                            Positioned(
                              top: -2, right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle, border: Border.all(color: AppTheme.bg, width: 2)),
                                child: Text("${widget.pendingDeleteCount}", style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => widget.onSwipe(0),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        children: [
                          Text("▶", style: TextStyle(fontSize: 13, color: AppTheme.primary)),
                          SizedBox(width: 5),
                          Text("Swipe", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: const Text("🗑", style: TextStyle(fontSize: 14)),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.dangerBg, foregroundColor: AppTheme.danger),
                    onPressed: () {
                      if (_selected.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (ctx) => ConfirmModal(
                            title: "Delete ${_selected.length} photo${_selected.length > 1 ? 's' : ''}?",
                            body: "Photos will be queued for deletion. Review in Pending Actions before applying.",
                            confirmLabel: "Queue ${_selected.length} for Delete",
                            danger: true,
                            onConfirm: () {
                              widget.addToDeleteQueue(Set.from(_selected));
                              Navigator.of(ctx).pop();
                              _cancelSelection();
                              _showToast("🗑 ${_selected.length} queued for deletion");
                            },
                            onCancel: () => Navigator.of(ctx).pop(),
                          ),
                        );
                      }
                    },
                  ),
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text("All", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  ),
                  IconButton(
                    icon: const Text("✕", style: TextStyle(fontSize: 14)),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.primaryBg, foregroundColor: AppTheme.textSub),
                    onPressed: _cancelSelection,
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (widget.photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🎉", style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            const Text("All clean here!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.text)),
            const Text("No photos in this view.", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            if (widget.pendingDeleteCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: AppTheme.dangerBg, borderRadius: BorderRadius.circular(8)),
                child: Text("🗑 ${widget.pendingDeleteCount} pending — tap Done ✓ to apply", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.danger)),
              )
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Support pinch gesture here wrapping the grid
      return GestureDetector(
        onScaleUpdate: (details) {
          if (details.scale > 1.2 && widget.gridCols > 2) {
            widget.setGridCols(max(2, widget.gridCols - 1));
          } else if (details.scale < 0.8 && widget.gridCols < 5) {
            widget.setGridCols(min(5, widget.gridCols + 1));
          }
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.gridCols,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: widget.photos.length,
          itemBuilder: (context, index) {
            final p = widget.photos[index];
            final isSel = _selected.contains(p.id);
            // Read queued IDs via Riverpod without causing full rebuild
            final isQueued = context.mounted
              ? ProviderScope.containerOf(context).read(queuedPhotoIdsProvider).contains(p.id)
              : false;

            return RepaintBoundary(
              child: GestureDetector(
                onLongPress: () => _startTimer(p.id),
                onTap: () => _selMode ? _toggleItem(p.id) : widget.onSwipe(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    border: isSel ? Border.all(color: AppTheme.primary, width: 3) : null,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (p.asset != null)
                        AssetEntityImage(
                          p.asset!,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize(300, 300),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      else
                        _mockThumb(p.label),
                      if (_selMode && !isSel)
                        Container(color: Colors.black26),
                      if (p.type == 'video' && !_selMode)
                        const Positioned(
                          top: 3, right: 3,
                          child: Icon(Icons.play_circle_fill, size: 18, color: Colors.white70),
                        ),
                      if (_selMode)
                        Positioned(
                          top: 4, left: 4,
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.primary : Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: isSel ? null : Border.all(color: Colors.white60, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: isSel
                                ? const Text('✓', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w900))
                                : null,
                          ),
                        ),
                      if (isQueued && !_selMode)
                        Positioned(
                          bottom: 3, right: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(6)),
                            child: const Text('🗑', style: TextStyle(fontSize: 9)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildActionBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _actionBtn("🗑", "Delete", AppTheme.danger, AppTheme.dangerBg, () {
            showDialog(
              context: context,
              builder: (ctx) => ConfirmModal(
                title: "Delete ${_selected.length} photo${_selected.length > 1 ? 's' : ''}?",
                body: "Photos will be queued for deletion. Review in Pending Actions before applying.",
                confirmLabel: "Queue ${_selected.length} for Delete",
                danger: true,
                onConfirm: () {
                  widget.addToDeleteQueue(Set.from(_selected));
                  Navigator.of(ctx).pop();
                  _cancelSelection();
                  _showToast("🗑 ${_selected.length} queued for deletion");
                },
                onCancel: () => Navigator.of(ctx).pop(),
              ),
            );
          }),
          const SizedBox(width: 6),
          _actionBtn("⭐", "Rate", AppTheme.warn, AppTheme.warnBg, () {
            setState(() => _showRateBar = !_showRateBar);
          }),
          const SizedBox(width: 6),
          _actionBtn("↗", "Share", const Color(0xFF9C27B0), const Color(0xFFF3E5F5), () {}),
        ],
      ),
    );
  }

  Widget _actionBtn(String icon, String label, Color color, Color bg, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mockThumb(String label) {
    const colors = [Color(0xFFE8EEFF), Color(0xFFFFF5F5), Color(0xFFF0FFF4), Color(0xFFFFFAF0)];
    final idx = (label.isEmpty ? 0 : label.codeUnitAt(0)) % colors.length;
    return Container(
      color: colors[idx],
      alignment: Alignment.center,
      child: Text(
        label.isNotEmpty ? label[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF4A5568)),
      ),
    );
  }
}
