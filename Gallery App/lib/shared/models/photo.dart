import 'package:photo_manager/photo_manager.dart';

class Photo {
  final String id;
  final AssetEntity? asset;
  final String label;
  final String date;
  final String time;
  final String size;
  final double sizeMB;
  final String type;
  final int? rating;
  final String? folder;

  const Photo({
    required this.id,
    this.asset,
    required this.label,
    required this.date,
    required this.time,
    required this.size,
    required this.sizeMB,
    required this.type,
    this.rating,
    this.folder,
  });

  Photo copyWith({
    String? id,
    AssetEntity? asset,
    String? label,
    String? date,
    String? time,
    String? size,
    double? sizeMB,
    String? type,
    int? rating,
    String? folder,
    bool clearRating = false,
    bool clearFolder = false,
  }) {
    return Photo(
      id: id ?? this.id,
      asset: asset ?? this.asset,
      label: label ?? this.label,
      date: date ?? this.date,
      time: time ?? this.time,
      size: size ?? this.size,
      sizeMB: sizeMB ?? this.sizeMB,
      type: type ?? this.type,
      rating: clearRating ? null : (rating ?? this.rating),
      folder: clearFolder ? null : (folder ?? this.folder),
    );
  }
}
