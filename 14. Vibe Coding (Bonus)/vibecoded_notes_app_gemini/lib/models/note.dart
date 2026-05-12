class Note {
  final int? id;
  final String title;
  final String content;
  final String timestamp;
  final int color;
  final bool isPinned;
  final bool isArchived; // Added archived field

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.color = 0xFFFFFFFF,
    this.isPinned = false,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'color': color,
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0, // Store as integer
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      timestamp: map['timestamp'],
      color: map['color'] ?? 0xFFFFFFFF,
      isPinned: (map['is_pinned'] ?? 0) == 1,
      isArchived: (map['is_archived'] ?? 0) == 1,
    );
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? timestamp,
    int? color,
    bool? isPinned,
    bool? isArchived,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
