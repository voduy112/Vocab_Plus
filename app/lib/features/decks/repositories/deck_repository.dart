import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/deck.dart';

class DeckRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Tạo deck mới
  Future<int> createDeck(Deck desk) async {
    final db = await _databaseHelper.database;
    return await db.insert('decks', desk.toMap());
  }

  // Lấy tất cả decks
  Future<List<Deck>> getAllDecks() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'decks',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Deck.fromMap(maps[i]);
    });
  }

  // Lấy deck theo ID
  Future<Deck?> getDeckById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'decks',
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
    );

    if (maps.isNotEmpty) {
      return Deck.fromMap(maps.first);
    }
    return null;
  }

  // Cập nhật deck
  Future<int> updateDeck(Deck desk) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'decks',
      desk.toMap(),
      where: 'id = ?',
      whereArgs: [desk.id],
    );
  }

  // Xóa deck (soft delete)
  Future<int> deleteDeck(int id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'decks',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Xóa deck vĩnh viễn (hard delete) - xóa tất cả dữ liệu liên quan
  Future<int> permanentlyDeleteDeck(int id) async {
    final db = await _databaseHelper.database;

    // Sử dụng transaction để đảm bảo tất cả dữ liệu được xóa hoặc không xóa gì cả
    return await db.transaction((txn) async {
      // 1. Xóa tất cả notifications liên quan đến deck
      await txn.delete(
        'notifications',
        where: 'deck_id = ?',
        whereArgs: [id],
      );

      // 2. Xóa tất cả study_sessions liên quan đến deck
      await txn.delete(
        'study_sessions',
        where: 'deck_id = ?',
        whereArgs: [id],
      );

      // 3. Lấy tất cả vocabulary IDs trong deck để xóa dữ liệu liên quan
      final vocabIds = await txn.query(
        'vocabularies',
        columns: ['id'],
        where: 'deck_id = ?',
        whereArgs: [id],
      );

      if (vocabIds.isNotEmpty) {
        final List<int> ids = vocabIds.map((map) => map['id'] as int).toList();
        final placeholders = List.filled(ids.length, '?').join(',');

        // 4. Xóa tất cả vocabulary_srs liên quan
        await txn.rawDelete(
          'DELETE FROM vocabulary_srs WHERE vocabulary_id IN ($placeholders)',
          ids,
        );

        // 5. Xóa tất cả notifications liên quan đến vocabularies
        await txn.rawDelete(
          'DELETE FROM notifications WHERE vocabulary_id IN ($placeholders)',
          ids,
        );

        // 6. Xóa tất cả study_sessions liên quan đến vocabularies
        await txn.rawDelete(
          'DELETE FROM study_sessions WHERE vocabulary_id IN ($placeholders)',
          ids,
        );

        // 7. Xóa tất cả vocabularies trong deck
        await txn.delete(
          'vocabularies',
          where: 'deck_id = ?',
          whereArgs: [id],
        );
      }

      // 8. Cuối cùng xóa deck
      return await txn.delete(
        'decks',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Tìm kiếm decks theo tên
  Future<List<Deck>> searchDecks(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'decks',
      where: 'name LIKE ? AND is_active = ?',
      whereArgs: ['%$query%', 1],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Deck.fromMap(maps[i]);
    });
  }

  // Toggle favorite status
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'decks',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Lấy thống kê deck
  Future<Map<String, dynamic>> getDeckStats(int deskId) async {
    final db = await _databaseHelper.database;

    // Tổng số từ vựng
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM vocabularies WHERE deck_id = ? AND is_active = ?',
      [deskId, 1],
    );
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    // Số từ vựng mới
    final newVocabulariesResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM vocabularies v
      JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ? AND v.is_active = ? AND s.srs_type = 0
      ''',
      [deskId, 1],
    );
    final newVocabularies = Sqflite.firstIntValue(newVocabulariesResult) ?? 0;

    // Số từ đã học (mastery_level > 0)
    final learnedResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM vocabularies v
      JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ? AND s.mastery_level > 0 AND v.is_active = ?
      ''',
      [deskId, 1],
    );
    final learned = Sqflite.firstIntValue(learnedResult) ?? 0;

    // Số từ đã thành thạo (mastery_level >= 3)
    final masteredResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM vocabularies v
      JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ? AND s.mastery_level >= 3 AND v.is_active = ?
      ''',
      [deskId, 1],
    );
    final mastered = Sqflite.firstIntValue(masteredResult) ?? 0;

    // Số từ tới hạn ôn (chỉ tính từ đã có lịch ôn tập)
    final reviewResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM vocabularies v
      JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ? AND v.is_active = 1 
        AND (
              (s.srs_due IS NOT NULL AND s.srs_due <= ?)
           OR (s.srs_due IS NULL AND s.next_review IS NOT NULL AND s.next_review <= ?)
        )
      ''',
      [
        deskId,
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
      ],
    );
    final needReview = Sqflite.firstIntValue(reviewResult) ?? 0;

    // Mức độ thành thạo trung bình
    final avgMasteryResult = await db.rawQuery(
      '''
      SELECT AVG(s.mastery_level) as avg 
      FROM vocabularies v
      JOIN vocabulary_srs s ON s.vocabulary_id = v.id
      WHERE v.deck_id = ? AND v.is_active = ?
      ''',
      [deskId, 1],
    );
    final avgMastery = avgMasteryResult.isNotEmpty
        ? (avgMasteryResult.first['avg'] as double? ?? 0.0).round()
        : 0;

    return {
      'total': total,
      'newVocabularies': newVocabularies,
      'learned': learned,
      'mastered': mastered,
      'needReview': needReview,
      'avgMastery': avgMastery,
    };
  }
}
