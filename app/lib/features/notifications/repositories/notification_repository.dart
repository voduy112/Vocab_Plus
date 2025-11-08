import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/notification.dart';

class NotificationRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Tạo thông báo mới
  Future<int> createNotification(AppNotification notification) async {
    final db = await _databaseHelper.database;
    final map = notification.toMap();
    map['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('notifications', map);
  }

  // Lấy tất cả thông báo
  Future<List<AppNotification>> getAllNotifications({
    int? limit,
    bool? unreadOnly,
  }) async {
    final db = await _databaseHelper.database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (unreadOnly == true) {
      whereClause += ' AND is_read = ?';
      whereArgs.add(0);
    }

    String query = 'SELECT * FROM notifications WHERE $whereClause ORDER BY time DESC';
    if (limit != null) {
      query += ' LIMIT $limit';
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);

    return List.generate(maps.length, (i) {
      return AppNotification.fromMap(maps[i]);
    });
  }

  // Lấy thông báo theo ID
  Future<AppNotification?> getNotificationById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return AppNotification.fromMap(maps.first);
    }
    return null;
  }

  // Đánh dấu thông báo đã đọc
  Future<int> markAsRead(int id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Đánh dấu tất cả thông báo đã đọc
  Future<int> markAllAsRead() async {
    final db = await _databaseHelper.database;
    return await db.update(
      'notifications',
      {'is_read': 1},
    );
  }

  // Xóa thông báo
  Future<int> deleteNotification(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Xóa tất cả thông báo đã đọc
  Future<int> deleteAllRead() async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'notifications',
      where: 'is_read = ?',
      whereArgs: [1],
    );
  }

  // Đếm số thông báo chưa đọc
  Future<int> getUnreadCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Xóa thông báo cũ hơn một số ngày
  Future<int> deleteOldNotifications(int daysOld) async {
    final db = await _databaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return await db.delete(
      'notifications',
      where: 'time < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }
}




