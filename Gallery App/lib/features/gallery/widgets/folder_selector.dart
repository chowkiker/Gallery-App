import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_folder.dart';

class FolderSelector extends StatelessWidget {
  final List<AppFolder> folders;
  final String? activeFolder;
  final ValueChanged<String> onSelectFolder;

  const FolderSelector({
    super.key,
    required this.folders,
    this.activeFolder,
    required this.onSelectFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...folders.map((f) {
              final isActive = activeFolder == f.name;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelectFolder(f.name),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary : AppTheme.primaryBg,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      f.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                        color: isActive ? Colors.white : AppTheme.textSub,
                      ),
                    ),
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  // TODO: Browse logic
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: AppTheme.primary),
                      SizedBox(width: 4),
                      Text(
                        "Browse",
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
