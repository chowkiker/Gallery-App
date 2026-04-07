import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../shared/models/photo.dart';
import '../shared/models/app_folder.dart';
import 'package:intl/intl.dart';

class MediaScannerService {
  // ─── Permission ────────────────────────────────────────────────────────────

  /// Requests device media permissions via photo_manager.
  /// Returns true when the app has read access to the gallery.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  // ─── Album API (primary) ────────────────────────────────────────────────────

  /// Returns all image/video albums found on the device.
  ///
  /// The list is sorted so the Camera roll is first.  If no album whose name
  /// contains "camera" (case-insensitive) is found the first album in the list
  /// returned by the OS is kept at position 0.
  static Future<List<AssetPathEntity>> getAlbums() async {
    if (kIsWeb) return [];

    final hasPerm = await requestPermission();
    if (!hasPerm) return [];

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: false,
      onlyAll: false,
    );

    if (albums.isEmpty) return albums;

    // Find a Camera album by a case-insensitive name match.
    final cameraIndex = albums.indexWhere(
      (a) => a.name.toLowerCase().contains('camera'),
    );

    if (cameraIndex > 0) {
      // Move it to the front without mutating the original list.
      final sorted = List<AssetPathEntity>.from(albums);
      final cameraAlbum = sorted.removeAt(cameraIndex);
      sorted.insert(0, cameraAlbum);
      return sorted;
    }

    return albums;
  }

  /// Returns ALL assets from [album] without limit.
  static Future<List<AssetEntity>> getPhotos(AssetPathEntity album) async {
    if (kIsWeb) return [];
    
    final int assetCount = await album.assetCountAsync;
    final List<AssetEntity> images = await album.getAssetListPaged(
        page: 0,
        size: assetCount, // full load
    );

    print("TOTAL IMAGES: ${images.length}");

    return images;
  }

  // ─── Legacy AppFolder API (kept for backwards-compat) ──────────────────────

  /// Wraps [getAlbums] and converts results into [AppFolder] objects that the
  /// rest of the app currently uses.
  static Future<List<AppFolder>> getFolders() async {
    if (kIsWeb) return [];

    final albums = await getAlbums();
    final List<AppFolder> dynamicFolders = [];

    for (var album in albums) {
      final count = await album.assetCountAsync;
      if (count > 0) {
        dynamicFolders.add(AppFolder(
          id: album.id,
          name: album.name.isNotEmpty ? album.name : 'Folder',
          system: album.isAll,
          path: album,
        ));
      }
    }

    return dynamicFolders;
  }

  /// Loads ALL [Photo] objects from [folder].
  static Future<List<Photo>> loadAll(AppFolder folder) async {
    if (kIsWeb) return _generateWebMocks();
    if (folder.path == null) return [];

    final List<AssetEntity> assets = await getPhotos(folder.path!);

    return _assetEntitiesToPhotos(assets, folder.name);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static List<Photo> _assetEntitiesToPhotos(
    List<AssetEntity> assets,
    String defaultFolderName,
  ) {
    final List<Photo> photos = [];

    for (final asset in assets) {
      final DateTime dt = asset.createDateTime;
      double estimatedMB = (asset.width * asset.height) / 2_000_000.0;
      if (estimatedMB < 0.1) estimatedMB = 0.5;

      String fName = defaultFolderName;
      if (asset.relativePath != null) {
        final parts = asset.relativePath!
            .split('/')
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) fName = parts.last;
      }

      photos.add(Photo(
        id: asset.id,
        asset: asset,
        label: asset.title ?? 'Photo ${asset.id}',
        date: DateFormat('MMM dd yyyy').format(dt),
        time: DateFormat('hh:mm a').format(dt),
        size: _formatSize(estimatedMB),
        sizeMB: estimatedMB,
        type: asset.type == AssetType.video ? 'video' : 'photo',
        rating: null,
        folder: fName,
      ));
    }

    return photos;
  }

  static String _formatSize(double estimatedMB) {
    if (estimatedMB >= 1024) {
      return '${(estimatedMB / 1024).toStringAsFixed(1)} GB';
    }
    return '${estimatedMB.toStringAsFixed(1)} MB';
  }

  // ─── Web mock data (development only) ──────────────────────────────────────

  static List<Photo> _generateWebMocks() {
    final rnd = Random(0);
    final List<Photo> list = [];
    final now = DateTime.now();

    for (int i = 0; i < 120; i++) {
      final int id = i;
      final dt = now.subtract(
        Duration(days: rnd.nextInt(60), hours: rnd.nextInt(24)),
      );
      final sizeMB = rnd.nextDouble() * 5 + 1.2;

      list.add(Photo(
        id: 'mock_$id',
        asset: null,
        label: 'IMG_$id.jpg',
        date: DateFormat('MMM dd yyyy').format(dt),
        time: DateFormat('hh:mm a').format(dt),
        size: _formatSize(sizeMB),
        sizeMB: sizeMB,
        type: 'photo',
        rating: rnd.nextBool() ? 5 : null,
        folder: 'WebMock',
      ));
    }
    return list;
  }
}
