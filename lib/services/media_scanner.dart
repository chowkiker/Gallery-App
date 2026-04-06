import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../shared/models/photo.dart';
import '../shared/models/app_folder.dart';
import 'package:intl/intl.dart';

class MediaScannerService {
  static Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  static Future<List<AppFolder>> getFolders() async {
    if (kIsWeb) {
      return [
        AppFolder(id: 'cam', name: 'Camera', system: false, path: null),
        AppFolder(id: 'wa', name: 'WhatsApp', system: false, path: null),
      ];
    }

    final hasPerm = await requestPermission();
    if (!hasPerm) return [];

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: false,
      onlyAll: false,
    );

    final List<AppFolder> folders = [];
    for (var path in paths) {
      folders.add(AppFolder(
        id: path.id,
        name: path.name.isNotEmpty ? path.name : "Folder",
        system: path.isAll,
        path: path,
      ));
    }
    return folders;
  }

  static Future<List<Photo>> loadPage(AppFolder folder, int start, int count) async {
    if (kIsWeb) {
      return _generateWebMocks(start, count);
    }

    if (folder.path == null) return [];

    final List<AssetEntity> assets = await folder.path!.getAssetListRange(start: start, end: start + count);
    final List<Photo> photos = [];

    for (var asset in assets) {
      final DateTime dt = asset.createDateTime;
      double estimatedMB = (asset.width * asset.height) / 2000000.0;
      if (estimatedMB < 0.1) estimatedMB = 0.5;
      
      String fName = folder.name;
      if (asset.relativePath != null) {
        final parts = asset.relativePath!.split('/').where((s) => s.isNotEmpty).toList();
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
      return "${(estimatedMB / 1024).toStringAsFixed(1)} GB";
    }
    return "${estimatedMB.toStringAsFixed(1)} MB";
  }

  static List<Photo> _generateWebMocks(int start, int count) {
    final rnd = Random(start);
    final List<Photo> list = [];
    final now = DateTime.now();
    
    // limit max mock photos to 120
    if (start >= 120) return [];
    int limit = min(count, 120 - start);

    for (int i = 0; i < limit; i++) {
      int id = start + i;
      final dt = now.subtract(Duration(days: rnd.nextInt(60), hours: rnd.nextInt(24)));
      final sizeMB = rnd.nextDouble() * 5 + 1.2;
      final folder = rnd.nextBool() ? "Camera" : "WhatsApp";
      list.add(Photo(
        id: "mock_$id",
        asset: null,
        label: "IMG_$id.jpg",
        date: DateFormat('MMM dd yyyy').format(dt),
        time: DateFormat('hh:mm a').format(dt),
        size: _formatSize(sizeMB),
        sizeMB: sizeMB,
        type: 'photo',
        rating: rnd.nextBool() ? 5 : null,
        folder: folder,
      ));
    }
    return list;
  }
}
