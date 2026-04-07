import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/photo.dart';

class SettingsScreen extends StatefulWidget {
  final List<Photo> photos;
  final int gridCols;
  final ValueChanged<int> setGridCols;
  /// Photo IDs queued for deletion.
  final Set<String> deleteQueue;
  /// Maps photoId → target folder name for move operations.
  final Map<String, String> moveQueue;
  /// Maps photoId → target folder name for copy operations.
  final Map<String, String> copyQueue;

  const SettingsScreen({
    super.key,
    required this.photos,
    required this.gridCols,
    required this.setGridCols,
    required this.deleteQueue,
    required this.moveQueue,
    required this.copyQueue,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _swipeEnabled = true;
  String _hintMode = "first3";

  String _fmtGB(double mb) {
    if (mb >= 1024) return "${(mb / 1024).toStringAsFixed(1)} GB";
    return "${mb.toStringAsFixed(1)} MB";
  }

  void _cycleHints() {
    setState(() {
      if (_hintMode == "first3") {
        _hintMode = "always";
      } else if (_hintMode == "always") {
        _hintMode = "off";
      } else {
        _hintMode = "first3";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMB = widget.photos.fold(0.0, (s, p) => s + p.sizeMB);
    final rated = widget.photos.where((p) => p.rating != null).length;

    final sections = [
      {
        'section': 'Display',
        'items': [
          {
            'label': 'Grid columns',
            'desc': 'Currently ${widget.gridCols} columns',
            'right': Row(
              children: [2, 3, 4, 5].map((n) => Padding(
                padding: const EdgeInsets.only(left: 5),
                child: InkWell(
                  onTap: () => widget.setGridCols(n),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: widget.gridCols == n ? AppTheme.primary : AppTheme.bg, borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text("$n", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.gridCols == n ? Colors.white : AppTheme.textSub, fontFamily: AppTheme.fontFamily)),
                  ),
                ),
              )).toList(),
            ),
          }
        ]
      },
      {
        'section': 'Storage',
        'items': [
          {
            'label': 'Total Photos & Videos',
            'desc': '${widget.photos.length} items · ${_fmtGB(totalMB)}',
            'right': Text(_fmtGB(totalMB), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: AppTheme.fontFamily)),
          },
          {
            'label': 'Rated Photos',
            'desc': '$rated of ${widget.photos.length} photos rated',
            'right': Text("$rated", style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily)),
          },
          {
            'label': 'Trash',
            'desc': 'Manage deleted photos',
            'right': InkWell(
              onTap: () {
                // simple alert
                showDialog(context: context, builder: (c) => AlertDialog(
                  title: const Text("Pending Actions"),
                  content: Text("${widget.deleteQueue.length} to delete · ${widget.moveQueue.length} to move · ${widget.copyQueue.length} to copy"),
                  actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: AppTheme.dangerBg, borderRadius: BorderRadius.circular(8)),
                child: const Text("View Trash", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.danger, fontFamily: AppTheme.fontFamily)),
              ),
            ),
          }
        ]
      },
      {
        'section': 'App',
        'items': [
          {
            'label': 'Swipe gesture',
            'desc': 'Swipe up to trash in viewer',
            'right': Switch(
              value: _swipeEnabled,
              onChanged: (v) => setState(() => _swipeEnabled = v),
              activeThumbColor: AppTheme.primary,
            ),
          },
          {
            'label': 'Hints',
            'desc': 'Show gesture hints',
            'right': InkWell(
              onTap: _cycleHints,
              child: Text(
                _hintMode == 'first3' ? "First 3" : _hintMode.replaceFirst(_hintMode[0], _hintMode[0].toUpperCase()),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary, fontFamily: AppTheme.fontFamily),
              ),
            ),
          }
        ]
      },
      {
        'section': 'About',
        'items': [
          {
            'label': 'Antigravity',
            'desc': 'Photo & Video Manager',
            'right': const Text("v2.0", style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: AppTheme.fontFamily)),
          }
        ]
      }
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text("Settings", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.text, fontFamily: AppTheme.fontFamily, letterSpacing: -0.8)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              itemCount: sections.length,
              itemBuilder: (context, idx) {
                final sec = sections[idx];
                final items = sec['items'] as List<Map<String, dynamic>>;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(sec['section'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary, fontFamily: AppTheme.fontFamily, letterSpacing: 0.8)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: const [BoxShadow(color: AppTheme.shadow, blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          children: items.asMap().entries.map((entry) {
                            final i = entry.key;
                            final item = entry.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                              decoration: BoxDecoration(
                                border: i < items.length - 1 ? const Border(bottom: BorderSide(color: AppTheme.border)) : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['label'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.text, fontFamily: AppTheme.fontFamily)),
                                        const SizedBox(height: 1),
                                        Text(item['desc'], style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: AppTheme.fontFamily)),
                                      ],
                                    ),
                                  ),
                                  if (item['right'] != null) item['right'] as Widget,
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
