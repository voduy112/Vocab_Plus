import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/deck.dart';
import '../../../core/services/sync_service.dart';
import '../../decks/services/deck_preload_cache.dart';
import '../../decks/services/deck_service.dart';

class ProfileController extends ChangeNotifier {
  final SyncService _syncService;
  final DatabaseHelper _dbHelper;
  final DeckService _deckService;
  final DeckPreloadCache _deckPreloadCache;

  bool isSyncing = false;
  String? syncProgressMessage;
  SyncStats? lastSyncStats;
  DateTime? lastSyncTime;
  String? lastSyncMessage;
  bool? lastSyncSucceeded;

  ProfileController({
    SyncService? syncService,
    DatabaseHelper? dbHelper,
    DeckService? deckService,
    DeckPreloadCache? deckPreloadCache,
  })  : _syncService = syncService ?? SyncService(),
        _dbHelper = dbHelper ?? DatabaseHelper(),
        _deckService = deckService ?? DeckService(),
        _deckPreloadCache = deckPreloadCache ?? DeckPreloadCache();

  Future<void> resetDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Xóa toàn bộ dữ liệu?'),
          content: const Text(
            'Thao tác này sẽ xóa toàn bộ từ vựng, deck và lịch sử học trong ứng dụng.\n\n'
            'Bạn có chắc chắn muốn tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa tất cả'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _dbHelper.deleteDatabase();
      _deckPreloadCache.clearCache();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa toàn bộ dữ liệu.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi reset dữ liệu: $e'),
        ),
      );
    }
  }

  Future<void> createDefaultDeck(BuildContext context) async {
    try {
      await _dbHelper.database;

      final now = DateTime.now();
      await _deckService.createDeck(
        Deck(
          name: 'Từ vựng của tôi',
          createdAt: now,
          updatedAt: now,
        ),
      );

      _deckPreloadCache.clearCache();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo deck từ vựng mặc định.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo deck mặc định: $e'),
        ),
      );
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await context.read<AuthController>().signOut();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng xuất khỏi tài khoản.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
      );
    }
  }

  Future<void> syncDataToCloud(BuildContext context) async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập Google trước khi đồng bộ.'),
        ),
      );
      return;
    }

    isSyncing = true;
    syncProgressMessage = 'Đang bắt đầu đồng bộ...';
    notifyListeners();

    try {
      const apiBaseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://172.20.10.2:3000',
      );

      _deckPreloadCache.clearCache();

      final result = await _syncService.syncFull(
        apiBaseUrl: apiBaseUrl,
        onProgress: (message, progress) {
          syncProgressMessage = message;
          notifyListeners();
        },
      );

      final stats = result.stats;
      final summaryMessage = stats != null
          ? 'Đồng bộ hai chiều thành công!\n'
              '• ${stats.decks} decks\n'
              '• ${stats.vocabularies} từ vựng\n'
              '• ${stats.vocabularySrs} SRS records\n'
              '• ${stats.imagesUploaded} ảnh đã upload'
          : result.message;

      isSyncing = false;
      syncProgressMessage = null;
      lastSyncStats = stats;
      lastSyncTime = DateTime.now();
      lastSyncMessage = summaryMessage;
      lastSyncSucceeded = result.success;
      notifyListeners();
    } catch (e) {
      if (!context.mounted) return;
      isSyncing = false;
      syncProgressMessage = null;
      lastSyncStats = null;
      lastSyncTime = DateTime.now();
      lastSyncMessage = 'Lỗi khi đồng bộ: $e';
      lastSyncSucceeded = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đồng bộ: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> ensureUserUpserted(BuildContext context) async {
    final api = ApiClient('http://172.20.10.2:3000');
    await api.dio.post('/users/me/upsert');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đăng nhập & upsert'),
      ),
    );
  }
}
