import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/vocabulary.dart';

String? _toUtcIso(DateTime? dateTime) {
  if (dateTime == null) return null;
  return dateTime.isUtc
      ? dateTime.toIso8601String()
      : dateTime.toUtc().toIso8601String();
}

class VocabularyRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Tạo từ vựng mới
  Future<int> createVocabulary(Vocabulary vocabulary) async {
    final db = await _databaseHelper.database;
    // Chia dữ liệu thành 2 bảng: vocabularies (thông tin cơ bản) + vocabulary_srs (trạng thái SRS)
    final int vocabId = await db.insert('vocabularies', {
      'deck_id': vocabulary.deskId,
      'front': vocabulary.front,
      'back': vocabulary.back,
      'front_image_url': vocabulary.frontImageUrl,
      'front_image_path': vocabulary.frontImagePath,
      'back_image_url': vocabulary.backImageUrl,
      'back_image_path': vocabulary.backImagePath,
      'front_extra_json': vocabulary.frontExtra == null
          ? null
          : vocabulary.frontExtra!.entries
              .map((e) => '${e.key}=${e.value}')
              .join('||'),
      'back_extra_json': vocabulary.backExtra == null
          ? null
          : vocabulary.backExtra!.entries
              .map((e) => '${e.key}=${e.value}')
              .join('||'),
      'created_at': _toUtcIso(vocabulary.createdAt) ??
          vocabulary.createdAt.toUtc().toIso8601String(),
      'updated_at': _toUtcIso(vocabulary.updatedAt) ??
          vocabulary.updatedAt.toUtc().toIso8601String(),
      'is_active': vocabulary.isActive ? 1 : 0,
      'card_type': vocabulary.cardType.toString().split('.').last,
    });

    await db.insert('vocabulary_srs', {
      'vocabulary_id': vocabId,
      'mastery_level': vocabulary.masteryLevel,
      'review_count': vocabulary.reviewCount,
      'last_reviewed': _toUtcIso(vocabulary.lastReviewed),
      'next_review': _toUtcIso(vocabulary.nextReview),
      'srs_ease_factor': vocabulary.srsEaseFactor,
      'srs_interval': vocabulary.srsIntervalDays,
      'srs_repetitions': vocabulary.srsRepetitions,
      'srs_due': _toUtcIso(vocabulary.srsDue),
      'srs_type': vocabulary.srsType,
      'srs_queue': vocabulary.srsQueue,
      'srs_lapses': vocabulary.srsLapses,
      'srs_left': vocabulary.srsLeft,
    });

    return vocabId;
  }

  // Lấy tất cả từ vựng trong một deck
  Future<List<Vocabulary>> getVocabulariesByDeskId(int deskId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        v.*, 
        s.mastery_level,
        s.review_count,
        s.last_reviewed,
        s.next_review,
        s.srs_ease_factor,
        s.srs_interval,
        s.srs_repetitions,
        s.srs_due,
        s.srs_type,
        s.srs_queue,
        s.srs_lapses,
        s.srs_left
      FROM vocabularies v
      LEFT JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ? AND v.is_active = 1
      ORDER BY v.created_at DESC
    ''', [deskId]);

    return List.generate(maps.length, (i) {
      return Vocabulary.fromMap(maps[i]);
    });
  }

  // Lấy từ vựng theo ID
  Future<Vocabulary?> getVocabularyById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        v.*, 
        s.mastery_level,
        s.review_count,
        s.last_reviewed,
        s.next_review,
        s.srs_ease_factor,
        s.srs_interval,
        s.srs_repetitions,
        s.srs_due,
        s.srs_type,
        s.srs_queue,
        s.srs_lapses,
        s.srs_left
      FROM vocabularies v
      LEFT JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.id = ? AND v.is_active = 1
    ''', [id]);

    if (maps.isNotEmpty) {
      return Vocabulary.fromMap(maps.first);
    }
    return null;
  }

  // Cập nhật từ vựng
  Future<int> updateVocabulary(Vocabulary vocabulary) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();

    // Cập nhật bảng vocabularies (thông tin cơ bản)
    batch.update(
      'vocabularies',
      {
        'deck_id': vocabulary.deskId,
        'front': vocabulary.front,
        'back': vocabulary.back,
        'front_image_url': vocabulary.frontImageUrl,
        'front_image_path': vocabulary.frontImagePath,
        'back_image_url': vocabulary.backImageUrl,
        'back_image_path': vocabulary.backImagePath,
        'front_extra_json': vocabulary.frontExtra == null
            ? null
            : vocabulary.frontExtra!.entries
                .map((e) => '${e.key}=${e.value}')
                .join('||'),
        'back_extra_json': vocabulary.backExtra == null
            ? null
            : vocabulary.backExtra!.entries
                .map((e) => '${e.key}=${e.value}')
                .join('||'),
        'updated_at': _toUtcIso(vocabulary.updatedAt),
        'is_active': vocabulary.isActive ? 1 : 0,
        'card_type': vocabulary.cardType.toString().split('.').last,
      },
      where: 'id = ?',
      whereArgs: [vocabulary.id],
    );

    // Cập nhật bảng vocabulary_srs (trạng thái SRS)
    batch.update(
      'vocabulary_srs',
      {
        'mastery_level': vocabulary.masteryLevel,
        'review_count': vocabulary.reviewCount,
        'last_reviewed': _toUtcIso(vocabulary.lastReviewed),
        'next_review': _toUtcIso(vocabulary.nextReview),
        'srs_ease_factor': vocabulary.srsEaseFactor,
        'srs_interval': vocabulary.srsIntervalDays,
        'srs_repetitions': vocabulary.srsRepetitions,
        'srs_due': _toUtcIso(vocabulary.srsDue),
        'srs_type': vocabulary.srsType,
        'srs_queue': vocabulary.srsQueue,
        'srs_lapses': vocabulary.srsLapses,
        'srs_left': vocabulary.srsLeft,
      },
      where: 'vocabulary_id = ?',
      whereArgs: [vocabulary.id],
    );

    final results = await batch.commit(noResult: false);
    // Trả về tổng số row bị ảnh hưởng (ước lượng)
    return results.fold<int>(0, (prev, element) {
      if (element is int) return prev + element;
      return prev;
    });
  }

  // Xóa từ vựng (hard delete - xóa hẳn khỏi database)
  Future<int> deleteVocabulary(int id) async {
    final db = await _databaseHelper.database;
    // Nhờ FOREIGN KEY ... ON DELETE CASCADE mà bản ghi liên quan
    // trong `vocabulary_srs`, `study_sessions`, ... sẽ tự động bị xoá theo.
    return await db.delete(
      'vocabularies',
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
      SELECT 
        v.*, 
        s.mastery_level,
        s.review_count,
        s.last_reviewed,
        s.next_review,
        s.srs_ease_factor,
        s.srs_interval,
        s.srs_repetitions,
        s.srs_due,
        s.srs_type,
        s.srs_queue,
        s.srs_lapses,
        s.srs_left
      FROM vocabularies v
      JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ? AND v.is_active = 1 AND (
        (s.srs_due IS NOT NULL AND s.srs_due <= ?)
        OR (s.srs_due IS NULL AND (s.next_review IS NULL OR s.next_review <= ?))
      )
      ORDER BY 
        CASE WHEN s.srs_due IS NULL THEN 1 ELSE 0 END,
        s.srs_due ASC,
        s.next_review ASC,
        v.created_at ASC
    ''' +
        (limit != null ? ' LIMIT $limit' : '');

    final List<Map<String, dynamic>> maps =
        await db.rawQuery(sql, [deskId, nowIso, nowIso]);

    return List.generate(maps.length, (i) {
      return Vocabulary.fromMap(maps[i]);
    });
  }

  // Lấy từ vựng đến hạn ôn tập (chỉ review)
  Future<List<Vocabulary>> getDueReviewVocabularies(int deckId,
      {int? limit}) async {
    final db = await _databaseHelper.database;
    final nowIso = DateTime.now().toIso8601String();
    final String sql = '''
      SELECT 
        v.*, 
        s.mastery_level,
        s.review_count,
        s.last_reviewed,
        s.next_review,
        s.srs_ease_factor,
        s.srs_interval,
        s.srs_repetitions,
        s.srs_due,
        s.srs_type,
        s.srs_queue,
        s.srs_lapses,
        s.srs_left
      FROM vocabularies v
      JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ?
        AND v.is_active = 1
        AND s.srs_due IS NOT NULL
        AND s.srs_due <= ?
      ORDER BY s.srs_due ASC, v.updated_at ASC
    ''' +
        (limit != null ? ' LIMIT $limit' : '');

    final List<Map<String, dynamic>> maps =
        await db.rawQuery(sql, [deckId, nowIso]);

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
    };
    if (srsType != null) updateData['srs_type'] = srsType;
    if (srsQueue != null) updateData['srs_queue'] = srsQueue;
    if (srsLapses != null) updateData['srs_lapses'] = srsLapses;
    if (srsLeft != null) updateData['srs_left'] = srsLeft;
    return await db.update(
      'vocabulary_srs',
      updateData,
      where: 'vocabulary_id = ?',
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
    };

    if (nextReview != null) {
      updateData['next_review'] = nextReview.toIso8601String();
    }

    return await db.update(
      'vocabulary_srs',
      updateData,
      where: 'vocabulary_id = ?',
      whereArgs: [vocabularyId],
    );
  }

  // Đếm số từ đang ở trạng thái học lại theo phút (minute-learning)
  Future<int> countMinuteLearning(int deskId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM vocabularies v
      JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ? AND v.is_active = 1 AND s.srs_queue = 1 AND s.srs_left >= 1000
      ''',
      [deskId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Đếm số từ vựng mới (chưa học lần nào: srs_repetitions = 0)
  Future<int> countNewVocabularies(int deskId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM vocabularies v
      JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ? AND v.is_active = 1 AND (s.srs_repetitions IS NULL OR s.srs_repetitions = 0)
      ''',
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
      SELECT DATE(COALESCE(s.srs_due, s.next_review)) AS day, COUNT(*) AS count
      FROM vocabulary_srs s
      JOIN vocabularies v ON v.id = s.vocabulary_id
      WHERE v.is_active = 1
        AND (
              (s.srs_due IS NOT NULL AND DATE(s.srs_due) BETWEEN DATE(?) AND DATE(?))
           OR (s.srs_due IS NULL AND s.next_review IS NOT NULL AND DATE(s.next_review) BETWEEN DATE(?) AND DATE(?))
        )
        ${deskId != null ? 'AND v.deck_id = ?' : ''}
      GROUP BY DATE(COALESCE(s.srs_due, s.next_review))
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
