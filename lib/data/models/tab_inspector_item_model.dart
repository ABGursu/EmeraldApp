class TabInspectorItem {
  final String id;
  final String title;
  final String url;
  final bool isDone;
  final String? previewImageUrl;
  final DateTime createdAt;

  const TabInspectorItem({
    required this.id,
    required this.title,
    required this.url,
    this.isDone = false,
    this.previewImageUrl,
    required this.createdAt,
  });

  TabInspectorItem copyWith({
    String? id,
    String? title,
    String? url,
    bool? isDone,
    String? previewImageUrl,
    DateTime? createdAt,
  }) {
    return TabInspectorItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      isDone: isDone ?? this.isDone,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'is_done': isDone ? 1 : 0,
        'preview_image_url': previewImageUrl,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory TabInspectorItem.fromMap(Map<String, dynamic> map) {
    return TabInspectorItem(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      isDone: (map['is_done'] as int? ?? 0) == 1,
      previewImageUrl: map['preview_image_url'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
