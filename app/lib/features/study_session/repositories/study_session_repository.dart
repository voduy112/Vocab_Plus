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
}
