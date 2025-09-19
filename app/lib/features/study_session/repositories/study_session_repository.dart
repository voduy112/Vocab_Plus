import '../../../core/database/database_helper.dart';
import '../../../core/models/study_session.dart';

class StudySessionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Tạo session học mới
  Future<int> createStudySession(StudySession session) async {
    final db = await _databaseHelper.database;
    return await db.insert('study_sessions', session.toMap());
  }

  // Lấy tất cả sessions của một desk
  Future<List<StudySession>> getSessionsByDeskId(int deskId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'desk_id = ?',
      whereArgs: [deskId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return StudySession.fromMap(maps[i]);
    });
  }

  // Lấy sessions của một từ vựng
  Future<List<StudySession>> getSessionsByVocabularyId(int vocabularyId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'vocabulary_id = ?',
      whereArgs: [vocabularyId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return StudySession.fromMap(maps[i]);
    });
  }

  // Lấy sessions theo loại
  Future<List<StudySession>> getSessionsByType(
      int deskId, SessionType sessionType) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'desk_id = ? AND session_type = ?',
      whereArgs: [deskId, sessionType.toString().split('.').last],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return StudySession.fromMap(maps[i]);
    });
  }

  // Lấy sessions trong khoảng thời gian
  Future<List<StudySession>> getSessionsByDateRange(
    int deskId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'desk_id = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [
        deskId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return StudySession.fromMap(maps[i]);
    });
  }

  // Lấy thống kê học tập
  Future<Map<String, dynamic>> getStudyStats(int deskId,
      {DateTime? startDate, DateTime? endDate}) async {
    final db = await _databaseHelper.database;

    String whereClause = 'desk_id = ?';
    List<dynamic> whereArgs = [deskId];

    if (startDate != null && endDate != null) {
      whereClause += ' AND created_at >= ? AND created_at <= ?';
      whereArgs
          .addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    // Tổng số sessions
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM study_sessions WHERE $whereClause',
      whereArgs,
    );
    final totalSessions =
        totalResult.isNotEmpty ? (totalResult.first['count'] as int? ?? 0) : 0;

    // Số sessions đúng
    final correctResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM study_sessions WHERE $whereClause AND result = ?',
      [...whereArgs, 'correct'],
    );
    final correctSessions = correctResult.isNotEmpty
        ? (correctResult.first['count'] as int? ?? 0)
        : 0;

    // Số sessions sai
    final incorrectResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM study_sessions WHERE $whereClause AND result = ?',
      [...whereArgs, 'incorrect'],
    );
    final incorrectSessions = incorrectResult.isNotEmpty
        ? (incorrectResult.first['count'] as int? ?? 0)
        : 0;

    // Số sessions bỏ qua
    final skippedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM study_sessions WHERE $whereClause AND result = ?',
      [...whereArgs, 'skipped'],
    );
    final skippedSessions = skippedResult.isNotEmpty
        ? (skippedResult.first['count'] as int? ?? 0)
        : 0;

    // Tổng thời gian học
    final timeResult = await db.rawQuery(
      'SELECT SUM(time_spent) as total FROM study_sessions WHERE $whereClause',
      whereArgs,
    );
    final totalTimeSpent =
        timeResult.isNotEmpty ? (timeResult.first['total'] as int? ?? 0) : 0;

    // Thống kê theo loại session
    final typeStats = await db.rawQuery('''
      SELECT session_type, COUNT(*) as count, AVG(time_spent) as avg_time
      FROM study_sessions 
      WHERE $whereClause
      GROUP BY session_type
    ''', whereArgs);

    final typeStatsMap = <String, Map<String, dynamic>>{};
    for (final row in typeStats) {
      typeStatsMap[row['session_type'] as String] = {
        'count': row['count'] as int,
        'avg_time': (row['avg_time'] as double?)?.round() ?? 0,
      };
    }

    // Tính tỷ lệ chính xác
    final accuracy =
        totalSessions > 0 ? (correctSessions / totalSessions) : 0.0;

    return {
      'total_sessions': totalSessions,
      'correct_sessions': correctSessions,
      'incorrect_sessions': incorrectSessions,
      'skipped_sessions': skippedSessions,
      'total_time_spent': totalTimeSpent,
      'accuracy': accuracy,
      'by_type': typeStatsMap,
    };
  }

  // Lấy streak học tập (số ngày học liên tiếp)
  Future<int> getStudyStreak(int deskId) async {
    final db = await _databaseHelper.database;

    // Lấy tất cả ngày có session học
    final result = await db.rawQuery('''
      SELECT DISTINCT DATE(created_at) as study_date
      FROM study_sessions 
      WHERE desk_id = ?
      ORDER BY study_date DESC
    ''', [deskId]);

    if (result.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();

    for (final row in result) {
      final studyDate = DateTime.parse(row['study_date'] as String);
      final daysDifference = currentDate.difference(studyDate).inDays;

      if (daysDifference == streak) {
        streak++;
        currentDate = studyDate;
      } else if (daysDifference == streak + 1) {
        // Cho phép gap 1 ngày
        streak++;
        currentDate = studyDate;
      } else {
        break;
      }
    }

    return streak;
  }

  // Xóa sessions cũ (dọn dẹp database)
  Future<int> deleteOldSessions(int daysToKeep) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    return await db.delete(
      'study_sessions',
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Lấy từ vựng được học nhiều nhất
  Future<List<Map<String, dynamic>>> getMostStudiedVocabularies(
      int deskId, int limit) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        v.id,
        v.word,
        v.meaning,
        COUNT(s.id) as session_count,
        AVG(CASE WHEN s.result = 'correct' THEN 1.0 ELSE 0.0 END) as accuracy
      FROM vocabularies v
      LEFT JOIN study_sessions s ON v.id = s.vocabulary_id
      WHERE v.desk_id = ? AND v.is_active = 1
      GROUP BY v.id, v.word, v.meaning
      ORDER BY session_count DESC, accuracy DESC
      LIMIT ?
    ''', [deskId, limit]);

    return result
        .map((row) => {
              'vocabulary_id': row['id'] as int,
              'word': row['word'] as String,
              'meaning': row['meaning'] as String,
              'session_count': row['session_count'] as int,
              'accuracy': (row['accuracy'] as double?) ?? 0.0,
            })
        .toList();
  }
}
