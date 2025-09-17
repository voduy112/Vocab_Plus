enum SessionType { learn, review, test }

enum SessionResult { correct, incorrect, skipped }

class StudySession {
  final int? id;
  final int deskId;
  final int vocabularyId;
  final SessionType sessionType;
  final SessionResult result;
  final int timeSpent; // thời gian tính bằng giây
  final DateTime createdAt;

  StudySession({
    this.id,
    required this.deskId,
    required this.vocabularyId,
    required this.sessionType,
    required this.result,
    this.timeSpent = 0,
    required this.createdAt,
  });

  // Chuyển đổi từ Map (từ database) sang StudySession object
  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'],
      deskId: map['desk_id'],
      vocabularyId: map['vocabulary_id'],
      sessionType: SessionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['session_type'],
      ),
      result: SessionResult.values.firstWhere(
        (e) => e.toString().split('.').last == map['result'],
      ),
      timeSpent: map['time_spent'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Chuyển đổi từ StudySession object sang Map (để lưu vào database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'desk_id': deskId,
      'vocabulary_id': vocabularyId,
      'session_type': sessionType.toString().split('.').last,
      'result': result.toString().split('.').last,
      'time_spent': timeSpent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Tạo bản copy với các thay đổi
  StudySession copyWith({
    int? id,
    int? deskId,
    int? vocabularyId,
    SessionType? sessionType,
    SessionResult? result,
    int? timeSpent,
    DateTime? createdAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      deskId: deskId ?? this.deskId,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      sessionType: sessionType ?? this.sessionType,
      result: result ?? this.result,
      timeSpent: timeSpent ?? this.timeSpent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Chuyển đổi thời gian từ giây sang định dạng dễ đọc
  String get formattedTimeSpent {
    if (timeSpent < 60) {
      return '${timeSpent}s';
    } else if (timeSpent < 3600) {
      final minutes = timeSpent ~/ 60;
      final seconds = timeSpent % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = timeSpent ~/ 3600;
      final minutes = (timeSpent % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  @override
  String toString() {
    return 'StudySession(id: $id, deskId: $deskId, vocabularyId: $vocabularyId, sessionType: $sessionType, result: $result, timeSpent: $timeSpent, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudySession &&
        other.id == id &&
        other.deskId == deskId &&
        other.vocabularyId == vocabularyId &&
        other.sessionType == sessionType &&
        other.result == result &&
        other.timeSpent == timeSpent &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        deskId.hashCode ^
        vocabularyId.hashCode ^
        sessionType.hashCode ^
        result.hashCode ^
        timeSpent.hashCode ^
        createdAt.hashCode;
  }
}
