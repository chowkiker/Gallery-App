import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import 'shared/models/photo.dart';
import 'shared/models/app_folder.dart';
import 'shared/models/queue_action.dart';
import 'services/media_scanner.dart';

// ─── INIT / PERMISSION STATE ──────────────────────────────────────────────────

class InitStatus {
  final bool isLoading;
  final bool permissionDenied;
  final bool isReady;
  const InitStatus({this.isLoading = true, this.permissionDenied = false, this.isReady = false});
}

class InitNotifier extends Notifier<InitStatus> {
  @override
  InitStatus build() => const InitStatus();

  Future<void> initialize() async {
    state = const InitStatus(isLoading: true);

    if (!kIsWeb) {
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.isAuth && !perm.hasAccess) {
        state = const InitStatus(isLoading: false, permissionDenied: true);
        return;
      }
    }

    final folders = await MediaScannerService.getFolders();
    ref.read(foldersProvider.notifier).setFolders(folders);

    if (folders.isEmpty) {
      state = const InitStatus(isLoading: false, isReady: true);
      return;
    }

    // Detect Camera: prefer isAll OR name contains "camera"
    final root = folders.firstWhere(
      (f) => f.system,
      orElse: () => folders.first,
    );
    final camera = folders.firstWhere(
      (f) => f.name.toLowerCase().contains('camera') || f.system,
      orElse: () => root,
    );
    ref.read(filterStateProvider.notifier).setFilter(folder: camera.name);

    state = const InitStatus(isLoading: false, isReady: true);

    // Progressive background load from the root (all-photos) path
    ref.read(photosProvider.notifier).progressiveLoad(root);
  }
}

final initProvider = NotifierProvider<InitNotifier, InitStatus>(() => InitNotifier());

// ─── PHOTOS ───────────────────────────────────────────────────────────────────

class PhotosNotifier extends Notifier<List<Photo>> {
  @override
  List<Photo> build() => [];

  Future<void> progressiveLoad(AppFolder root) async {
    bool disposed = false;
    ref.onDispose(() => disposed = true);
    int total = kIsWeb ? 120 : await root.path!.assetCountAsync;
    const batchSize = 80;

    for (int i = 0; i < total; i += batchSize) {
      if (disposed) return;
      final chunk = await MediaScannerService.loadPage(root, i, batchSize);
      if (chunk.isEmpty) break;
      state = [...state, ...chunk];
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  void deleteFromState(Set<String> ids) {
    state = state.where((p) => !ids.contains(p.id)).toList();
  }

  void moveInState(Set<String> ids, String targetFolder) {
    state = state.map((p) => ids.contains(p.id) ? p.copyWith(folder: targetFolder) : p).toList();
  }

  void copyInState(Set<String> ids, String targetFolder) {
    final copies = state
        .where((p) => ids.contains(p.id))
        .map((p) => p.copyWith(
              id: '${p.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
              folder: targetFolder,
            ))
        .toList();
    state = [...state, ...copies];
  }

  void ratePhoto(String id, int rating) {
    state = state.map((p) => p.id == id ? p.copyWith(rating: rating) : p).toList();
  }
}

final photosProvider = NotifierProvider<PhotosNotifier, List<Photo>>(() => PhotosNotifier());

// ─── FOLDERS ─────────────────────────────────────────────────────────────────

class FoldersNotifier extends Notifier<List<AppFolder>> {
  @override
  List<AppFolder> build() => [];

  void setFolders(List<AppFolder> folders) => state = folders;
  void addFolder(AppFolder folder) => state = [...state, folder];
}

final foldersProvider = NotifierProvider<FoldersNotifier, List<AppFolder>>(() => FoldersNotifier());

// ─── QUEUES ───────────────────────────────────────────────────────────────────

class QueuesState {
  final List<QueueAction> deleteQueue;
  final List<QueueAction> moveQueue;
  final List<QueueAction> copyQueue;
  const QueuesState({
    this.deleteQueue = const [],
    this.moveQueue = const [],
    this.copyQueue = const [],
  });

  int get totalCount =>
      deleteQueue.fold(0, (s, a) => s + a.photoIds.length) +
      moveQueue.length +
      copyQueue.length;

  QueuesState copyWith({
    List<QueueAction>? deleteQueue,
    List<QueueAction>? moveQueue,
    List<QueueAction>? copyQueue,
  }) =>
      QueuesState(
        deleteQueue: deleteQueue ?? this.deleteQueue,
        moveQueue: moveQueue ?? this.moveQueue,
        copyQueue: copyQueue ?? this.copyQueue,
      );
}

class QueueNotifier extends Notifier<QueuesState> {
  @override
  QueuesState build() => const QueuesState();

  void addToDeleteQueue(Set<String> ids) {
    HapticFeedback.lightImpact();
    state = state.copyWith(deleteQueue: [...state.deleteQueue, QueueAction.delete(ids)]);
  }

  void addToMoveQueue(Set<String> ids, String folder) {
    HapticFeedback.lightImpact();
    state = state.copyWith(moveQueue: [...state.moveQueue, QueueAction.move(ids, folder)]);
  }

  void addToCopyQueue(Set<String> ids, String folder) {
    HapticFeedback.lightImpact();
    state = state.copyWith(copyQueue: [...state.copyQueue, QueueAction.copy(ids, folder)]);
  }

  void cancelQueues() => state = const QueuesState();

  void undoLast() => cancelQueues();
  void doUndo() => undoLast();

  /// Apply all queued actions with real PhotoManager.editor ops.
  /// Falls back to in-memory updates if editor is unavailable (web/unsupported).
  Future<void> applyPendingActions(WidgetRef ref, BuildContext context) async {
    final photos = ref.read(photosProvider.notifier);

    // ── Delete ──
    for (final act in state.deleteQueue) {
      try {
        if (!kIsWeb) {
          final perm = await PhotoManager.requestPermissionExtend();
          if (!perm.isAuth) throw Exception('Permission denied');
          await PhotoManager.editor.deleteWithIds(act.photoIds.toList());
        }
        photos.deleteFromState(act.photoIds);
      } catch (e) {
        debugPrint('Delete failed: $e');
        if (context.mounted) {
          _showError(context, 'Failed to delete some photos. They may have already been removed.');
        }
      }
    }

    // ── Move ──
    for (final act in state.moveQueue) {
      if (act.targetFolder == null) continue;
      try {
        if (!kIsWeb) {
          // Find AssetPathEntity for target folder
          final folders = ref.read(foldersProvider);
          final targetPath = folders
              .where((f) => f.name == act.targetFolder && f.path != null)
              .map((f) => f.path!)
              .firstOrNull;
          if (targetPath != null) {
            final assets = ref
                .read(photosProvider)
                .where((p) => act.photoIds.contains(p.id) && p.asset != null)
                .map((p) => p.asset!)
                .toList();
            // photo_manager 3.x: move = copy to destination + delete original
            final movedIds = <String>[];
            for (final asset in assets) {
              try {
                await PhotoManager.editor.copyAssetToPath(
                  asset: asset, pathEntity: targetPath);
                movedIds.add(asset.id);
              } catch (_) {}
            }
            if (movedIds.isNotEmpty) {
              await PhotoManager.editor.deleteWithIds(movedIds);
            }
          }
        }
        photos.moveInState(act.photoIds, act.targetFolder!);
      } catch (e) {
        debugPrint('Move failed: $e');
        if (context.mounted) {
          _showError(context, 'Failed to move some photos.');
        }
      }
    }

    // ── Copy ──
    for (final act in state.copyQueue) {
      if (act.targetFolder == null) continue;
      try {
        if (!kIsWeb) {
          final folders = ref.read(foldersProvider);
          final targetPath = folders
              .where((f) => f.name == act.targetFolder && f.path != null)
              .map((f) => f.path!)
              .firstOrNull;
          if (targetPath != null) {
            final assets = ref
                .read(photosProvider)
                .where((p) => act.photoIds.contains(p.id) && p.asset != null)
                .map((p) => p.asset!)
                .toList();
            for (final asset in assets) {
              await PhotoManager.editor.copyAssetToPath(asset: asset, pathEntity: targetPath);
            }
          }
        }
        photos.copyInState(act.photoIds, act.targetFolder!);
      } catch (e) {
        debugPrint('Copy failed: $e');
        if (context.mounted) {
          _showError(context, 'Failed to copy some photos.');
        }
      }
    }

    state = const QueuesState();
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE53E3E)),
    );
  }
}

final queueProvider = NotifierProvider<QueueNotifier, QueuesState>(() => QueueNotifier());

// ─── FILTER STATE ─────────────────────────────────────────────────────────────

class FilterStateData {
  final String? activeFolder;
  final int? ratingFilter;
  final String? timelineFilter; // e.g. "March 2024"
  final String? timelineMode;  // 'Date' | 'Month' | 'Year'

  const FilterStateData({
    this.activeFolder,
    this.ratingFilter,
    this.timelineFilter,
    this.timelineMode,
  });
}

class FilterStateNotifier extends Notifier<FilterStateData> {
  @override
  FilterStateData build() => const FilterStateData();

  void setFilter({
    String? folder,
    int? rating,
    String? timelineFilter,
    String? timelineMode,
  }) {
    state = FilterStateData(
      activeFolder: folder,
      ratingFilter: rating,
      timelineFilter: timelineFilter,
      timelineMode: timelineMode,
    );
  }

  void clearTimeline() {
    state = FilterStateData(
      activeFolder: state.activeFolder,
      ratingFilter: state.ratingFilter,
    );
  }
}

final filterStateProvider =
    NotifierProvider<FilterStateNotifier, FilterStateData>(() => FilterStateNotifier());

// ─── FILTERED PHOTOS ─────────────────────────────────────────────────────────

final filteredPhotosProvider = Provider<List<Photo>>((ref) {
  final photos = ref.watch(photosProvider);
  final filter = ref.watch(filterStateProvider);

  if (photos.isEmpty) return [];

  final monthFormat = DateFormat('MMMM yyyy');
  final yearFormat = DateFormat('yyyy');
  final parseFmt = DateFormat('MMM dd yyyy');

  return photos.where((photo) {
    // Folder filter
    if (filter.activeFolder != null && filter.activeFolder!.isNotEmpty) {
      if ((photo.folder ?? '') != filter.activeFolder) return false;
    }

    // Rating filter
    if (filter.ratingFilter != null && photo.rating != filter.ratingFilter) return false;

    // Timeline filter — STRICT: only show photos in this exact timeline bucket
    if (filter.timelineFilter != null && filter.timelineMode != null) {
      String key = photo.date;
      DateTime? dt;
      if (photo.asset != null) {
        dt = photo.asset!.createDateTime;
      } else {
        try {
          dt = parseFmt.parse(photo.date);
        } catch (_) {}
      }

      if (dt != null) {
        key = switch (filter.timelineMode) {
          'Month' => monthFormat.format(dt),
          'Year' => yearFormat.format(dt),
          _ => photo.date,
        };
      }

      if (key != filter.timelineFilter) return false;
    }

    return true;
  }).toList();
});

// ─── QUEUED IDS (for badge display) ─────────────────────────────────────────

final queuedPhotoIdsProvider = Provider<Set<String>>((ref) {
  final q = ref.watch(queueProvider);
  final ids = <String>{};
  for (final a in q.deleteQueue) ids.addAll(a.photoIds);
  for (final a in q.moveQueue) ids.addAll(a.photoIds);
  for (final a in q.copyQueue) ids.addAll(a.photoIds);
  return ids;
});
