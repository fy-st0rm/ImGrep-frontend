class DbImage {
  final String id;
  final String path;
  final DateTime modifiedAt;
  final bool isSynced;
  final int? faissId;

  DbImage({
    required this.id,
    required this.path,
    required this.modifiedAt,
    this.isSynced = false,
    this.faissId = null,
  });

  // Convert Image to a map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'modified_at': modifiedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'faiss_id': faissId,
    };
  }

  // Create DbImage from a database map
  static DbImage fromMap(Map<String, dynamic> map) {
    return DbImage(
      id: map['id'] as String,
      path: map['path'] as String,
      modifiedAt: DateTime.parse(map['modified_at'] as String),
      isSynced: (map['is_synced'] as int) == 1,
      faissId: map['faiss_id'],
    );
  }
}
