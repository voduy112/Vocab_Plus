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

  // Lấy tất cả từ vựng trong một desk
  Future<List<Vocabulary>> getVocabulariesByDeskId(int deskId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vocabularies',
      where: 'desk_id = ? AND is_active = ?',
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

  // Tìm kiếm từ vựng
  Future<List<Vocabulary>> searchVocabularies(int deskId, String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vocabularies',
      where:
          'desk_id = ? AND (word LIKE ? OR meaning LIKE ?) AND is_active = ?',
      whereArgs: [deskId, '%$query%', '%$query%', 1],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Vocabulary.fromMap(maps[i]);
    });
  }

  // Lấy từ vựng cần ôn tập
  Future<List<Vocabulary>> getVocabulariesForStudy(int deskId,
      {int? limit}) async {
    final db = await _databaseHelper.database;
    final nowIso = DateTime.now().toIso8601String();
    final String sql = '''
      SELECT * FROM vocabularies
      WHERE desk_id = ? AND is_active = 1 AND (
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
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'vocabularies',
      {
        'srs_ease_factor': easeFactor,
        'srs_interval': intervalDays,
        'srs_repetitions': repetitions,
        'srs_due': due?.toIso8601String(),
        'last_reviewed': now,
        'updated_at': now,
        'review_count': (await _getReviewCount(vocabularyId)) + 1,
      },
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
      'review_count': await _getReviewCount(vocabularyId) + 1,
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

  // Lấy số lần ôn tập
  Future<int> _getReviewCount(int vocabularyId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'vocabularies',
      columns: ['review_count'],
      where: 'id = ?',
      whereArgs: [vocabularyId],
    );
    return result.isNotEmpty ? result.first['review_count'] as int : 0;
  }

  // Lấy thống kê từ vựng trong desk
  Future<Map<String, dynamic>> getVocabularyStats(int deskId) async {
    final db = await _databaseHelper.database;

    // Tổng số từ vựng
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM vocabularies WHERE desk_id = ? AND is_active = ?',
      [deskId, 1],
    );
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    // Số từ theo mức độ thành thạo
    final masteryStats = await db.rawQuery('''
      SELECT 
        CASE 
          WHEN mastery_level = 0 THEN 'not_learned'
          WHEN mastery_level < 30 THEN 'beginner'
          WHEN mastery_level < 60 THEN 'intermediate'
          WHEN mastery_level < 80 THEN 'advanced'
          ELSE 'mastered'
        END as level,
        COUNT(*) as count
      FROM vocabularies 
      WHERE desk_id = ? AND is_active = ?
      GROUP BY level
    ''', [deskId, 1]);

    final stats = <String, int>{
      'not_learned': 0,
      'beginner': 0,
      'intermediate': 0,
      'advanced': 0,
      'mastered': 0,
    };

    for (final row in masteryStats) {
      stats[row['level'] as String] = row['count'] as int;
    }

    return {
      'total': total,
      'by_mastery': stats,
    };
  }
}
