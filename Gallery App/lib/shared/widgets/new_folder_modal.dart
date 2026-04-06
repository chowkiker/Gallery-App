import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_folder.dart';

class NewFolderModal extends StatefulWidget {
  final ValueChanged<AppFolder> onCreate;

  const NewFolderModal({super.key, required this.onCreate});

  @override
  State<NewFolderModal> createState() => _NewFolderModalState();
}

class _NewFolderModalState extends State<NewFolderModal> {
  final _nameController = TextEditingController();
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bottom padding to ensure it fits above keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(18, 20, 18, 32 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text("Create Folder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.text, fontFamily: AppTheme.fontFamily)),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Folder name…",
              filled: true,
              fillColor: AppTheme.bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
            style: const TextStyle(fontSize: 14, fontFamily: AppTheme.fontFamily, color: AppTheme.text),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primaryBg,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nameController.text.trim().isEmpty ? null : () {
                    widget.onCreate(AppFolder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim(),
                      system: false,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily),
                  ),
                  child: const Text("Create"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

void showNewFolderModal(BuildContext context, ValueChanged<AppFolder> onCreate) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => NewFolderModal(
      onCreate: (folder) {
        onCreate(folder);
        Navigator.of(context).pop();
      },
    ),
  );
}
