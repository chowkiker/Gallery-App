import 'package:photo_manager/photo_manager.dart';

class AppFolder {
  final String id;
  final String name;
  final bool system;
  final AssetPathEntity? path;

  const AppFolder({
    required this.id,
    required this.name,
    this.system = false,
    this.path,
  });
}
