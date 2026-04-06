class QueueAction {
  final String type; // 'delete', 'move', 'copy'
  final Set<String> photoIds;
  final String? targetFolder;

  const QueueAction._({
    required this.type,
    required this.photoIds,
    this.targetFolder,
  });

  factory QueueAction.delete(Set<String> ids) => QueueAction._(type: 'delete', photoIds: ids);
  factory QueueAction.move(Set<String> ids, String folder) => QueueAction._(type: 'move', photoIds: ids, targetFolder: folder);
  factory QueueAction.copy(Set<String> ids, String folder) => QueueAction._(type: 'copy', photoIds: ids, targetFolder: folder);
}
