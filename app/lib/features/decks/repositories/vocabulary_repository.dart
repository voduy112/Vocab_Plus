import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/vocabulary.dart';

class VocabularyRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Tạo từ vựng mới
  Future<int> createVocabulary(Vocabulary vocabulary) async {
    final db = await _databaseHelper.database;
    return await db.insert('vocabularies', vocabulary.toMap());
  }

  // Lấy tất cả từ vựng trong một deck
  Future<List<Vocabulary>> getVocabulariesByDeskId(int deskId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vocabularies',
      where: 'deck_id = ? AND is_active = ?',
      whereArgs: [deskId, 1],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Vocabulary.fromMap(maps[i]);
    });
  }

  // Lấy từ vựng theo ID
  Future<Vocabulary?> getVocabularyById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vocabularies',
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
    );

    if (maps.isNotEmpty) {
      return Vocabulary.fromMap(maps.first);
    }
    return null;
  }

  // Cập nhật từ vựng
  Future<int> updateVocabulary(Vocabulary vocabulary) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'vocabularies',
      vocabulary.toMap(),
      where: 'id = ?',
      whereArgs: [vocabulary.id],
    );
  }

  // Xóa từ vựng (soft delete)
  Future<int> deleteVocabulary(int id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'vocabularies',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Lấy từ vựng cần ôn tập
  Future<List<Vocabulary>> getVocabulariesForStudy(int deskId,
      {int? limit}) async {
    final db = await _databaseHelper.database;
    final nowIso = DateTime.now().toIso8601String();
    final String sql = '''
      SELECT * FROM vocabularies
      WHERE deck_id = ? AND is_active = 1 AND (
        (srs_due IS NOT NULL AND srs_due <= ?)
        OR (srs_due IS NULL AND (next_review IS NULL OR next_review <= ?))
      )
      ORDER BY 
        CASE WHEN srs_due IS NULL THEN 1 ELSE 0 END,
        srs_due ASC,
        next_review ASC,
        created_at ASC
    ''' +
        (limit != null ? ' LIMIT $limit' : '');

    final List<Map<String, dynamic>> maps =
        await db.rawQuery(sql, [deskId, nowIso, nowIso]);

    return List.generate(maps.length, (i) {
      return Vocabulary.fromMap(maps[i]);
    });
  }

  // Cập nhật lịch SRS cho một từ vựng
  Future<int> updateSrsSchedule({
    required int vocabularyId,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime? due,
    int? srsType,
    int? srsQueue,
    int? srsLapses,
    int? srsLeft,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final updateData = {
      'srs_ease_factor': easeFactor,
      'srs_interval': intervalDays,
      'srs_repetitions': repetitions,
      'srs_due': due?.toIso8601String(),
      'last_reviewed': now,
      'updated_at': now,
    };
    if (srsType != null) updateData['srs_type'] = srsType;
    if (srsQueue != null) updateData['srs_queue'] = srsQueue;
    if (srsLapses != null) updateData['srs_lapses'] = srsLapses;
    if (srsLeft != null) updateData['srs_left'] = srsLeft;
    return await db.update(
      'vocabularies',
      updateData,
      where: 'id = ?',
      whereArgs: [vocabularyId],
    );
  }

  // Cập nhật mức độ thành thạo sau khi học
  Future<int> updateMasteryLevel(int vocabularyId, int newMasteryLevel,
      {DateTime? nextReview}) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();

    final updateData = {
      'mastery_level': newMasteryLevel,
      'last_reviewed': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    if (nextReview != null) {
      updateData['next_review'] = nextReview.toIso8601String();
    }

    return await db.update(
      'vocabularies',
      updateData,
      where: 'id = ?',
      whereArgs: [vocabularyId],
    );
  }

  // Đếm số từ đang ở trạng thái học lại theo phút (minute-learning)
  Future<int> countMinuteLearning(int deskId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM vocabularies WHERE deck_id = ? AND is_active = 1 AND srs_queue = 1 AND srs_left >= 1000',
      [deskId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Đếm số từ vựng mới (chưa học lần nào: srs_repetitions = 0)
  Future<int> countNewVocabularies(int deskId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM vocabularies WHERE deck_id = ? AND is_active = 1 AND (srs_repetitions IS NULL OR srs_repetitions = 0)',
      [deskId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Đếm số từ đến hạn theo ngày trong khoảng thời gian (gộp theo ngày)
  Future<Map<DateTime, int>> getDueCountsByDateRange({
    required DateTime start,
    required DateTime end,
    int? deskId,
  }) async {
    final db = await _databaseHelper.database;
    // Dùng COALESCE(srs_due, next_review) để tương thích với cả review và day-learning
    final String baseSql = '''
      SELECT DATE(COALESCE(srs_due, next_review)) AS day, COUNT(*) AS count
      FROM vocabularies
      WHERE is_active = 1
        AND (
              (srs_due IS NOT NULL AND DATE(srs_due) BETWEEN DATE(?) AND DATE(?))
           OR (srs_due IS NULL AND next_review IS NOT NULL AND DATE(next_review) BETWEEN DATE(?) AND DATE(?))
        )
        ${deskId != null ? 'AND deck_id = ?' : ''}
      GROUP BY DATE(COALESCE(srs_due, next_review))
      ORDER BY day ASC
    ''';

    final List<Object?> args = [
      start.toIso8601String(),
      end.toIso8601String(),
      start.toIso8601String(),
      end.toIso8601String(),
      if (deskId != null) deskId,
    ];

    final List<Map<String, dynamic>> rows = await db.rawQuery(baseSql, args);
    final Map<DateTime, int> result = {};
    for (final row in rows) {
      final String dayStr = row['day'] as String; // yyyy-MM-dd
      final parts = dayStr.split('-');
      if (parts.length == 3) {
        final int year = int.parse(parts[0]);
        final int month = int.parse(parts[1]);
        final int day = int.parse(parts[2]);
        result[DateTime(year, month, day)] = (row['count'] as int? ?? 0);
      }
    }
    return result;
  }
}
