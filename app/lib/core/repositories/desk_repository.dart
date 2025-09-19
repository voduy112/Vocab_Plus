import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/desk.dart';

class DeskRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Tạo desk mới
  Future<int> createDesk(Desk desk) async {
    final db = await _databaseHelper.database;
    return await db.insert('desks', desk.toMap());
  }

  // Lấy tất cả desks
  Future<List<Desk>> getAllDesks() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'desks',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Desk.fromMap(maps[i]);
    });
  }

  // Lấy desk theo ID
  Future<Desk?> getDeskById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'desks',
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
    );

    if (maps.isNotEmpty) {
      return Desk.fromMap(maps.first);
    }
    return null;
  }

  // Cập nhật desk
  Future<int> updateDesk(Desk desk) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'desks',
      desk.toMap(),
      where: 'id = ?',
      whereArgs: [desk.id],
    );
  }

  // Xóa desk (soft delete)
  Future<int> deleteDesk(int id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'desks',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Xóa desk vĩnh viễn (hard delete)
  Future<int> permanentlyDeleteDesk(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'desks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tìm kiếm desks theo tên
  Future<List<Desk>> searchDesks(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'desks',
      where: 'name LIKE ? AND is_active = ?',
      whereArgs: ['%$query%', 1],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Desk.fromMap(maps[i]);
    });
  }

  // Lấy số lượng từ vựng trong desk
  Future<int> getVocabularyCount(int deskId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM vocabularies WHERE desk_id = ? AND is_active = ?',
      [deskId, 1],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Lấy thống kê desk
  Future<Map<String, dynamic>> getDeskStats(int deskId) async {
    final db = await _databaseHelper.database;

    // Tổng số từ vựng
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM vocabularies WHERE desk_id = ? AND is_active = ?',
      [deskId, 1],
    );
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    // Số từ đã học (mastery_level > 0)
    final learnedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM vocabularies WHERE desk_id = ? AND mastery_level > 0 AND is_active = ?',
      [deskId, 1],
    );
    final learned = Sqflite.firstIntValue(learnedResult) ?? 0;

    // Số từ đã thành thạo (mastery_level >= 3)
    final masteredResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM vocabularies WHERE desk_id = ? AND mastery_level >= 0 AND is_active = ?',
      [deskId, 1],
    );
    final mastered = Sqflite.firstIntValue(masteredResult) ?? 0;

    // Số từ cần ôn tập
    final reviewResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM vocabularies WHERE desk_id = ? AND (next_review IS NULL OR next_review <= ?) AND is_active = ?',
      [deskId, DateTime.now().toIso8601String(), 1],
    );
    final needReview = Sqflite.firstIntValue(reviewResult) ?? 0;

    // Mức độ thành thạo trung bình
    final avgMasteryResult = await db.rawQuery(
      'SELECT AVG(mastery_level) as avg FROM vocabularies WHERE desk_id = ? AND is_active = ?',
      [deskId, 1],
    );
    final avgMastery = avgMasteryResult.isNotEmpty
        ? (avgMasteryResult.first['avg'] as double? ?? 0.0).round()
        : 0;

    // Tính progress dựa trên số từ vựng đã học
    double progress = 0.0;
    if (total > 0) {
      progress = learned / total;
    }

    return {
      'total': total,
      'learned': learned,
      'mastered': mastered,
      'needReview': needReview,
      'avgMastery': avgMastery,
      'progress': progress,
    };
  }
}
