import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

class SearchHistoryService {
  static const int maxItems = 10;

  Future<void> addQuery(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) return;
    final db = await DatabaseHelper().database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'search_history',
      {'query': q, 'created_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Trim to maxItems
    await db.execute('''
      DELETE FROM search_history WHERE id IN (
        SELECT id FROM search_history ORDER BY created_at DESC LIMIT -1 OFFSET ?
      )
    ''', [maxItems]);
  }

  Future<List<String>> getRecent({int limit = maxItems}) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query(
      'search_history',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map((r) => (r['query'] as String)).toList();
  }

  Future<void> remove(String query) async {
    final db = await DatabaseHelper().database;
    await db.delete('search_history', where: 'query = ?', whereArgs: [query]);
  }

  Future<void> clearAll() async {
    final db = await DatabaseHelper().database;
    await db.delete('search_history');
  }
}

