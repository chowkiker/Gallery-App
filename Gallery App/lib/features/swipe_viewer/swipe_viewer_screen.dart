import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/photo.dart';
import '../../shared/models/app_folder.dart';
import '../../shared/widgets/move_copy_tray.dart';
import '../../shared/widgets/confirm_modal.dart';
import '../../shared/widgets/rating_bar.dart';

class SwipeViewerScreen extends StatefulWidget {
  final List<Photo> photos;
  final String title;
  final int startIndex;
  final VoidCallback onBack;
  final VoidCallback onGrid;
  final Function(String) onDeletePhoto;
  final Function(String, String) onMovePhoto;
  final Function(String, int?) onRatePhoto;
  final List<AppFolder> folders;
  final ValueChanged<AppFolder> onAddFolder;
  final Function(Set<String>) addToDeleteQueue;
  final Function(Set<String>, String) addToMoveQueue;
  final Function(Set<String>, String) addToCopyQueue;
  final int pendingDeleteCount;
  final VoidCallback doUndo;
  final VoidCallback applyPendingActions;

  const SwipeViewerScreen({
    super.key,
    required this.photos,
    required this.title,
    required this.startIndex,
    required this.onBack,
    required this.onGrid,
    required this.onDeletePhoto,
    required this.onMovePhoto,
    required this.onRatePhoto,
    required this.folders,
    required this.onAddFolder,
    required this.addToDeleteQueue,
    required this.addToMoveQueue,
    required this.addToCopyQueue,
    required this.pendingDeleteCount,
    required this.doUndo,
    required this.applyPendingActions,
  });

  @override
  State<SwipeViewerScreen> createState() => _SwipeViewerScreenState();
}

class _SwipeViewerScreenState extends State<SwipeViewerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageCtrl;
  int _currentIndex = 0;
  bool _filterOpen = false;
  String _filter = "UNSORTED";
  bool _showConfirm = false;

  final Set<String> _sessionDel = {};
  final List<String> _localTrashIds = [];

  // Swipe animation state
  Offset _dragDelta = Offset.zero;
  bool _isDragging = false;
  String? _swipeAnim;

  List<Photo> get _visiblePhotos => widget.photos.where((p) => !_sessionDel.contains(p.id)).toList();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    int maxIdx = _visiblePhotos.isNotEmpty ? _visiblePhotos.length - 1 : 0;
    if (_currentIndex > maxIdx) _currentIndex = maxIdx;
    
    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _doTrash(Photo photo) {
    setState(() => _swipeAnim = 'up');
    Future.delayed(const Duration(milliseconds: 290), () {
      if (!mounted) return;
      setState(() {
        _swipeAnim = null;
        _sessionDel.add(photo.id);
        _localTrashIds.add(photo.id);
        _dragDelta = Offset.zero;
      });
      widget.addToDeleteQueue({photo.id});
      
      int maxIdx = _visiblePhotos.isEmpty ? 0 : _visiblePhotos.length - 1;
      int nextIdx = min(_currentIndex, maxIdx);
      _pageCtrl.jumpToPage(nextIdx);
      setState(() => _currentIndex = nextIdx);
    });
  }

  void _localUndo() {
    if (_localTrashIds.isEmpty) return;
    final lastId = _localTrashIds.removeLast();
    setState(() {
      _sessionDel.remove(lastId);
    });
    widget.doUndo(); // removes from queue
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visiblePhotos;
    if (visible.isEmpty) return _buildEmptyState();

    final photo = visible[_currentIndex];

    // Build the matrix for swipe transformations
    Matrix4 transform = Matrix4.identity();
    if (_swipeAnim == 'up') {
      transform.multiply(Matrix4.translationValues(0.0, -MediaQuery.of(context).size.height, 0.0));
      transform.rotateZ(8 * pi / 180);
      transform.multiply(Matrix4.diagonal3Values(0.8, 0.8, 1.0));
    } else if (_isDragging) {
      transform.multiply(Matrix4.translationValues(_dragDelta.dx, _dragDelta.dy, 0.0));
      transform.rotateZ(_dragDelta.dx * 0.0005);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(photo),
              Expanded(
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _isDragging = true;
                      _dragDelta = Offset.zero;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _dragDelta += details.delta;
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _isDragging = false;
                    });
                    if (_dragDelta.dy < -100 && _dragDelta.dy.abs() > _dragDelta.dx.abs()) {
                      // Swipe UP to trash
                      _doTrash(photo);
                    } else if (_dragDelta.dx > 60) {
                      // Swipe Right to previous
                      if (_currentIndex > 0) {
                        _pageCtrl.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.ease);
                      }
                    } else if (_dragDelta.dx < -60) {
                      // Swipe Left to next
                      if (_currentIndex < visible.length - 1) {
                        _pageCtrl.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.ease);
                      }
                    }
                    setState(() => _dragDelta = Offset.zero);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PageView.builder(
                          physics: const NeverScrollableScrollPhysics(), // Handle swipes manually for full custom behavior
                          controller: _pageCtrl,
                          onPageChanged: (idx) => setState(() => _currentIndex = idx),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            if (index != _currentIndex) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: visible[index].asset != null ? FutureBuilder<Uint8List?>(
                                    future: visible[index].asset!.thumbnailDataWithSize(const ThumbnailSize(800, 800)),
                                    builder: (context, snapshot) {
                                       if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                                          );
                                       }
                                       return const Center(child: Icon(Icons.photo, color: AppTheme.textMuted));
                                    }
                                  ) : const Center(child: Icon(Icons.photo, color: AppTheme.textMuted)),
                                ),
                              );
                            }
                            // Current item is overlaid on top so it can perform custom transforms
                            return const SizedBox.shrink(); 
                          },
                        ),
                        // Draggable Current Card
                        AnimatedContainer(
                          duration: Duration(milliseconds: _isDragging || _swipeAnim != null ? 0 : 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(8),
                          transform: transform,
                          alignment: Alignment.center,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: AppTheme.card,
                              boxShadow: const [BoxShadow(color: AppTheme.shadowDeep, blurRadius: 32, offset: Offset(0, 8))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  photo.asset != null ? FutureBuilder<Uint8List?>(
                                      future: photo.asset!.thumbnailDataWithSize(const ThumbnailSize(800, 800)),
                                      builder: (context, snapshot) {
                                          return snapshot.connectionState == ConnectionState.done && snapshot.data != null ? Image.memory(snapshot.data!, fit: BoxFit.cover) : const Center(child: Icon(Icons.photo, color: AppTheme.textMuted));
                                      }
                                  ) : const Center(child: Icon(Icons.photo, color: AppTheme.textMuted)),
                                  Positioned(
                                    bottom: 0, left: 0, right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(colors: [Colors.black54, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                                      ),
                                      child: Text(
                                        photo.label,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: AppTheme.fontFamily),
                                      ),
                                    ),
                                  ),
                                  if (_isDragging && _dragDelta.dy < -48)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0x2EEF4444),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                        decoration: BoxDecoration(color: const Color(0xE6EF4444), borderRadius: BorderRadius.circular(14)),
                                        child: const Text("🗑 Release to trash", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Left/Right Nav Overlays
                        if (!_isDragging && _currentIndex > 0)
                          Positioned(
                            left: 0,
                            child: IconButton(
                              icon: const Text("‹", style: TextStyle(fontSize: 28, color: Color(0x554A7BF7))),
                              onPressed: () => _pageCtrl.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.ease),
                            ),
                          ),
                        if (!_isDragging && _currentIndex < visible.length - 1)
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: const Text("›", style: TextStyle(fontSize: 28, color: Color(0x554A7BF7))),
                              onPressed: () => _pageCtrl.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.ease),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              MoveCopyTray(
                selectedPhotos: [photo],
                hideBanner: true,
                onMove: (f) {
                  widget.addToMoveQueue({photo.id}, f);
                },
                onCopy: (f) {
                  widget.addToCopyQueue({photo.id}, f);
                },
                onDelete: () {
                  widget.addToDeleteQueue({photo.id});
                },
                folders: widget.folders,
                onAddFolder: widget.onAddFolder,
                pendingCount: widget.pendingDeleteCount,
                onApplyPending: widget.applyPendingActions,
                onCancelPending: () {},
              ),
              _buildRatingSection(photo),
            ],
          ),
          if (_filterOpen) _buildFilterOverlay(),
          if (_showConfirm)
            ConfirmModal(
              title: "Delete ${widget.pendingDeleteCount} photo${widget.pendingDeleteCount != 1 ? 's' : ''}?",
              body: "Photos go to Android Trash. Recoverable within 30 days.",
              confirmLabel: "Delete ${widget.pendingDeleteCount} Photo${widget.pendingDeleteCount != 1 ? 's' : ''}",
              danger: true,
              onConfirm: () {
                widget.applyPendingActions();
                setState(() {
                  _localTrashIds.clear();
                  _showConfirm = false;
                });
              },
              onCancel: () => setState(() => _showConfirm = false),
            )
        ],
      ),
    );
  }

  Widget _buildAppBar(Photo photo) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 8, 8),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(photo.date, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text("${photo.time}  •  ${photo.size}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          if (_localTrashIds.isNotEmpty || widget.pendingDeleteCount > 0)
            IconButton(
              icon: const Icon(Icons.undo, color: AppTheme.primary),
              onPressed: _localUndo,
            ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
            onPressed: widget.onGrid,
          ),
          IconButton(
            icon: Icon(photo.rating != null && photo.rating! >= 4 ? Icons.star : Icons.star_border, color: photo.rating != null && photo.rating! >= 4 ? AppTheme.warn : Colors.white, size: 24),
            onPressed: () {
               widget.onRatePhoto(photo.id, photo.rating == 5 ? 0 : 5);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
            onPressed: () {
              if (widget.pendingDeleteCount > 0) {
                setState(() => _showConfirm = true);
              } else {
                _doTrash(photo);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoInfoBar(Photo photo, int total) {
    Color? rgColor;
    Color? rgBg;
    String? rgLabel;
    if (photo.rating != null) {
      switch (photo.rating) {
        case 5: rgColor = AppTheme.success; rgBg = AppTheme.successBg; rgLabel = "Excellent"; break;
        case 4: rgColor = AppTheme.primary; rgBg = AppTheme.primaryBg; rgLabel = "Good"; break;
        case 3: rgColor = AppTheme.warn; rgBg = AppTheme.warnBg; rgLabel = "OK"; break;
        case 2: rgColor = const Color(0xFFF97316); rgBg = const Color(0xFFFFF7ED); rgLabel = "Average"; break;
        case 1: rgColor = AppTheme.danger; rgBg = AppTheme.dangerBg; rgLabel = "Poor"; break;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 6),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(7)),
            child: Text("${_currentIndex + 1} / $total", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ),
          const SizedBox(width: 8),
          Text("${photo.date} – ${photo.time}", style: const TextStyle(fontSize: 10, color: AppTheme.textSub)),
          const Spacer(),
          Text(photo.size, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          if (photo.rating != null && rgColor != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: rgBg!, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: rgColor, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(rgLabel!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: rgColor)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildRatingSection(Photo photo) {
    return Container(
      color: AppTheme.bg,
      padding: const EdgeInsets.only(bottom: 12),
      child: RatingBar(
        rating: photo.rating,
        onRate: (r) => widget.onRatePhoto(photo.id, r ?? 0),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("🎉", style: TextStyle(fontSize: 52)),
        const SizedBox(height: 14),
        const Text("All cleaned up!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text)),
        const SizedBox(height: 10),
        Text("${widget.pendingDeleteCount} photo${widget.pendingDeleteCount != 1 ? 's' : ''} queued for deletion", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: widget.onBack,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          child: const Text("← Back", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        )
      ],
    );
  }

  Widget _buildFilterOverlay() {
    final opts = ["UNSORTED", "BY DATE ↓", "BY DATE ↑", "BY SIZE", "VIDEOS ONLY", "EXCELLENT", "GOOD", "OK", "AVERAGE", "POOR"];
    return GestureDetector(
      onTap: () => setState(() => _filterOpen = false),
      child: Container(
        color: const Color(0x661A2340),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            decoration: const BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
                const Text("Filter & Sort", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.text, fontFamily: AppTheme.fontFamily)),
                const SizedBox(height: 12),
                ...opts.map((f) => InkWell(
                  onTap: () => setState(() { _filter = f; _filterOpen = false; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(f, style: TextStyle(fontSize: 13, color: _filter == f ? AppTheme.primary : AppTheme.textSub, fontWeight: _filter == f ? FontWeight.w700 : FontWeight.w400)),
                        if (_filter == f) const Text("✓", style: TextStyle(color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
