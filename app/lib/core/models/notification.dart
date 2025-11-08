class AppNotification {
  final int? id;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final String? type; // 'due_vocabulary', 'study_reminder', etc.
  final int? vocabularyId;
  final int? deckId;

  AppNotification({
    this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.type,
    this.vocabularyId,
    this.deckId,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      time: DateTime.parse(map['time']),
      isRead: map['is_read'] == 1,
      type: map['type'],
      vocabularyId: map['vocabulary_id'],
      deckId: map['deck_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': time.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'type': type,
      'vocabulary_id': vocabularyId,
      'deck_id': deckId,
    };
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? message,
    DateTime? time,
    bool? isRead,
    String? type,
    int? vocabularyId,
    int? deckId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      deckId: deckId ?? this.deckId,
    );
  }
}




