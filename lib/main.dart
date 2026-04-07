import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers.dart';
import 'features/gallery/organize_screen.dart';
import 'features/gallery/grid_view.dart';
import 'features/swipe_viewer/swipe_viewer_screen.dart';
import 'features/albums/albums_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/trash/queue_panel.dart';
import 'features/onboarding/permission_screen.dart';
import 'shared/widgets/bottom_nav.dart';
import 'shared/widgets/skeleton_loader.dart';
import 'shared/models/app_folder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: GalleryApp()));
}

class GalleryApp extends ConsumerWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Gallery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const _AppInit(),
    );
  }
}

/// Handles app initialization and routes between loading/permission/shell.
class _AppInit extends ConsumerStatefulWidget {
  const _AppInit();
  @override
  ConsumerState<_AppInit> createState() => _AppInitState();
}

class _AppInitState extends ConsumerState<_AppInit> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(initProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(initProvider);

    if (status.isLoading) return const SkeletonLoader();
    if (status.permissionDenied) return const PermissionScreen();
    return const AppShell();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends HookConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navTab     = ref.watch(_navTabProvider);
    final activeView = ref.watch(_activeViewProvider);
    final filtered   = ref.watch(filteredPhotosProvider);
    final allPhotos  = ref.watch(photosProvider);
    final folders    = ref.watch(foldersProvider);
    final queues     = ref.watch(queueProvider);
    final gridCols   = ref.watch(_gridColsProvider);
    final filter     = ref.watch(filterStateProvider);
    final activeFolder  = filter.activeFolder;
    final ratingFilter  = filter.ratingFilter;

    final pendingDeleteCount = queues.deleteQueue.length;
    final totalPendingCount  = queues.totalCount;

    // ── Helpers ──────────────────────────────────────────────────────────────

    void showQueuedSnack(String msg) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () => ref.read(queueProvider.notifier).cancelQueues(),
          ),
        ),
      );
    }

    void openFilter(dynamic filter, String label) {
      final kind = filter['kind'] as String;
      final id   = filter['id'] as String?;
      if (kind == 'timeline') {
        ref.read(filterStateProvider.notifier).setFilter(
          folder: activeFolder,
          rating: ratingFilter,
          timelineFilter: id,
          timelineMode: filter['mode'] as String,
        );
      } else {
        ref.read(filterStateProvider.notifier).setFilter(
          folder: kind == 'folder' ? id : null,
          rating: kind == 'rating' ? filter['value'] as int : null,
        );
      }
      ref.read(_activeViewProvider.notifier).state = ActiveView(
        filter: kind, title: label, type: 'grid', startIdx: 0,
      );
    }

    void toSwipe(int idx) {
      final cur = ref.read(_activeViewProvider);
      ref.read(_activeViewProvider.notifier).state =
          cur?.copyWith(type: 'swipe', startIdx: idx) ??
          ActiveView(filter: 'all', title: 'Photos', type: 'swipe', startIdx: idx);
    }

    void toGrid() {
      final cur = ref.read(_activeViewProvider);
      ref.read(_activeViewProvider.notifier).state = cur?.copyWith(type: 'grid');
    }

    void closeAll() {
      ref.read(filterStateProvider.notifier).clearTimeline();
      ref.read(_activeViewProvider.notifier).state = null;
    }

    Future<void> applyPending() async {
      await ref.read(queueProvider.notifier).applyPendingActions(ref, context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Changes applied ✓'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    void cancelPending() => ref.read(queueProvider.notifier).cancelQueues();

    void onAddFolder(AppFolder folder) => ref.read(foldersProvider.notifier).addFolder(folder);

    void addToDeleteQueue(Set<String> ids) {
      ref.read(queueProvider.notifier).addToDeleteQueue(ids);
      showQueuedSnack('🗑 ${ids.length} photo${ids.length > 1 ? 's' : ''} added to delete queue');
    }

    void addToMoveQueue(Set<String> ids, String folder) {
      ref.read(queueProvider.notifier).addToMoveQueue(ids, folder);
      showQueuedSnack('↗ ${ids.length} photo${ids.length > 1 ? 's' : ''} queued to move to $folder');
    }

    void addToCopyQueue(Set<String> ids, String folder) {
      ref.read(queueProvider.notifier).addToCopyQueue(ids, folder);
      showQueuedSnack('📋 ${ids.length} photo${ids.length > 1 ? 's' : ''} queued to copy to $folder');
    }

    // ── View Router ───────────────────────────────────────────────────────────

    Widget buildBody() {
      if (activeView == null) {
        if (navTab == 'organize') {
          return OrganizeScreen(
            photos: filtered,
            folders: folders,
            activeFolder: activeFolder,
            onSelectFolder: (f) {
              ref.read(filterStateProvider.notifier).setFilter(folder: f);
            },
            gridCols: gridCols,
            setGridCols: (n) => ref.read(_gridColsProvider.notifier).state = n,
            onSwipe: toSwipe,
            addToDeleteQueue: addToDeleteQueue,
            addToMoveQueue: addToMoveQueue,
            addToCopyQueue: addToCopyQueue,
            pendingDeleteCount: pendingDeleteCount,
            totalPendingCount: totalPendingCount,
            cancelQueues: cancelPending,
            applyPendingActions: applyPending,
            onAddFolder: onAddFolder,
            onRatePhoto: (id, rating) => ref.read(photosProvider.notifier).ratePhoto(id, rating),
            onOpenTimeline: (key, mode) =>
                openFilter({'kind': 'timeline', 'id': key, 'mode': mode}, key),
          );
        } else if (navTab == 'albums') {
          return AlbumsScreen(
            photos: allPhotos,
            folders: folders,
            onOpenFilter: openFilter,
          );
        } else {
          return SettingsScreen(
            photos: allPhotos,
            gridCols: gridCols,
            setGridCols: (n) => ref.read(_gridColsProvider.notifier).state = n,
            deleteQueue: queues.deleteQueue,
            moveQueue: queues.moveQueue,
            copyQueue: queues.copyQueue,
          );
        }
      } else if (activeView.type == 'grid') {
        return GridViewScreen(
          photos: filtered,
          title: activeView.title,
          onBack: closeAll,
          onSwipe: toSwipe,
          folders: folders.where((f) => !f.system).toList(),
          onAddFolder: onAddFolder,
          gridCols: gridCols,
          setGridCols: (n) => ref.read(_gridColsProvider.notifier).state = n,
          addToDeleteQueue: addToDeleteQueue,
          addToMoveQueue: addToMoveQueue,
          addToCopyQueue: addToCopyQueue,
          pendingDeleteCount: pendingDeleteCount,
          totalPendingCount: totalPendingCount,
          cancelQueues: cancelPending,
          applyPendingActions: applyPending,
          ratingFilter: ratingFilter,
          setRatingFilter: (r) =>
              ref.read(filterStateProvider.notifier).setFilter(folder: activeFolder, rating: r),
          onRatePhoto: (id, rating) => ref.read(photosProvider.notifier).ratePhoto(id, rating ?? 0),
        );
      } else {
        return SwipeViewerScreen(
          photos: filtered,
          title: activeView.title,
          startIndex: activeView.startIdx,
          onBack: closeAll,
          onGrid: toGrid,
          onDeletePhoto: (id) => addToDeleteQueue({id}),
          onMovePhoto: (id, folder) => addToMoveQueue({id}, folder),
          onRatePhoto: (id, rating) => ref.read(photosProvider.notifier).ratePhoto(id, rating ?? 0),
          folders: folders.where((f) => !f.system).toList(),
          onAddFolder: onAddFolder,
          addToDeleteQueue: addToDeleteQueue,
          addToMoveQueue: addToMoveQueue,
          addToCopyQueue: addToCopyQueue,
          pendingDeleteCount: pendingDeleteCount,
          doUndo: () => ref.read(queueProvider.notifier).doUndo(),
          applyPendingActions: applyPending,
        );
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(child: ClipRRect(child: buildBody())),
            if (activeView == null && totalPendingCount > 0)
              Positioned(
                left: 0, right: 0, bottom: 100,
                child: QueuePanel(
                  deleteQueue: queues.deleteQueue,
                  moveQueue: queues.moveQueue,
                  copyQueue: queues.copyQueue,
                  onCancel: cancelPending,
                  onApply: applyPending,
                ),
              ),
            if (activeView == null)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: BottomNav(
                  activeTab: navTab,
                  onChange: (t) {
                    ref.read(_navTabProvider.notifier).state = t;
                    // Reset selection on tab switch
                    ref.read(filterStateProvider.notifier).clearTimeline();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

}

// ── Local UI providers ────────────────────────────────────────────────────────
final _navTabProvider   = StateProvider<String>((ref) => 'organize');
final _gridColsProvider = StateProvider<int>((ref) => 3);

class ActiveView {
  final String filter;
  final String title;
  final String type;
  final int startIdx;

  const ActiveView({
    required this.filter,
    required this.title,
    required this.type,
    required this.startIdx,
  });

  ActiveView copyWith({String? filter, String? title, String? type, int? startIdx}) =>
      ActiveView(
        filter: filter ?? this.filter,
        title: title ?? this.title,
        type: type ?? this.type,
        startIdx: startIdx ?? this.startIdx,
      );
}

final _activeViewProvider = StateProvider<ActiveView?>((ref) => null);
