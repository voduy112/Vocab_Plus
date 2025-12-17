// features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/api/api_client.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/deck.dart';
import '../../../core/services/sync_service.dart';
import '../../decks/services/deck_service.dart';
import '../../decks/services/deck_preload_cache.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSyncing = false;
  String? _syncProgressMessage;
  SyncStats? _lastSyncStats;
  DateTime? _lastSyncTime;
  String? _lastSyncMessage;
  bool? _lastSyncSucceeded;
  final SyncService _syncService = SyncService();

  Future<void> _resetDatabase() async {
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

    if (confirmed != true || !mounted) return;

    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteDatabase();

      // Làm mới cache decks nếu có
      DeckPreloadCache().clearCache();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa toàn bộ dữ liệu.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi reset dữ liệu: $e'),
        ),
      );
    }
  }

  Future<void> _createDefaultDeck() async {
    try {
      // Đảm bảo database đã được khởi tạo (nếu trước đó đã xóa)
      final dbHelper = DatabaseHelper();
      await dbHelper.database;

      final deckService = DeckService();
      final now = DateTime.now();
      await deckService.createDeck(
        Deck(
          name: 'Từ vựng của tôi',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Làm mới cache decks nếu có
      DeckPreloadCache().clearCache();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo deck từ vựng mặc định.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo deck mặc định: $e'),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await context.read<AuthController>().signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng xuất khỏi tài khoản.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
      );
    }
  }

  Future<void> _syncDataToCloud() async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập Google trước khi đồng bộ.'),
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncProgressMessage = 'Đang bắt đầu đồng bộ...';
    });

    try {
      const apiBaseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://192.168.2.167:3000',
      );

      // Clear cache trước khi sync
      DeckPreloadCache().clearCache();

      // Sử dụng syncFull để đồng bộ hai chiều (tải về + upload lên)
      final result = await _syncService.syncFull(
        apiBaseUrl: apiBaseUrl,
        onProgress: (message, progress) {
          if (mounted) {
            setState(() {
              _syncProgressMessage = message;
            });
          }
        },
      );

      if (!mounted) return;

      final stats = result.stats;
      final summaryMessage = stats != null
          ? 'Đồng bộ hai chiều thành công!\n'
              '• ${stats.decks} decks\n'
              '• ${stats.vocabularies} từ vựng\n'
              '• ${stats.vocabularySrs} SRS records\n'
              '• ${stats.imagesUploaded} ảnh đã upload'
          : result.message;

      setState(() {
        _isSyncing = false;
        _syncProgressMessage = null;
        _lastSyncStats = stats;
        _lastSyncTime = DateTime.now();
        _lastSyncMessage = summaryMessage;
        _lastSyncSucceeded = result.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _syncProgressMessage = null;
        _lastSyncStats = null;
        _lastSyncTime = DateTime.now();
        _lastSyncMessage = 'Lỗi khi đồng bộ: $e';
        _lastSyncSucceeded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đồng bộ: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileTopBar(onBack: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 24),
              _ProfileHeaderCard(
                auth: auth,
                onSignIn: () async {
                  await context.read<AuthController>().signInWithGoogle();
                  final api = ApiClient('http://192.168.2.167:3000');
                  await api.dio.post('/users/me/upsert');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đăng nhập & upsert'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 28),
              if (context.watch<AuthController>().isLoggedIn)
                _ProfileOptionTile(
                  icon: Icons.sync,
                  label: 'Đồng bộ',
                  onTap: _isSyncing ? null : _syncDataToCloud,
                  trailing: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              if (context.watch<AuthController>().isLoggedIn &&
                  _syncProgressMessage != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    _syncProgressMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              if (_lastSyncMessage != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _SyncStatusCard(
                    message: _lastSyncMessage!,
                    success: _lastSyncSucceeded ?? false,
                    stats: _lastSyncStats,
                    syncTime: _lastSyncTime,
                  ),
                ),
              _ProfileOptionTile(
                icon: Icons.delete_forever_outlined,
                label: 'Xóa toàn bộ dữ liệu',
                onTap: _resetDatabase,
              ),
              _ProfileOptionTile(
                icon: Icons.inventory_2_outlined,
                label: 'Tạo deck từ vựng mặc định',
                onTap: _createDefaultDeck,
              ),
              if (auth.isLoggedIn)
                _ProfileOptionTile(
                  icon: Icons.logout,
                  label: 'Đăng xuất',
                  onTap: _signOut,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final bool success;
  final String message;
  final SyncStats? stats;
  final DateTime? syncTime;

  const _SyncStatusCard({
    required this.success,
    required this.message,
    required this.stats,
    required this.syncTime,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return 'Thời gian không xác định';
    final local = time.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.hour)}:${twoDigits(local.minute)} '
        '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        success ? Colors.green : theme.colorScheme.error.withOpacity(0.9);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lần cuối: ${_formatTime(syncTime)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          if (stats != null) ...[
            const SizedBox(height: 8),
            _StatRow(label: 'Decks', value: stats!.decks),
            _StatRow(label: 'Từ vựng', value: stats!.vocabularies),
            _StatRow(label: 'SRS records', value: stats!.vocabularySrs),
            _StatRow(label: 'Phiên học', value: stats!.studySessions),
            _StatRow(label: 'Ảnh upload', value: stats!.imagesUploaded),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            value.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _ProfileTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _roundButton(
          context,
          icon: Icons.arrow_back,
          onTap: onBack,
        ),
        Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 48), // Placeholder để giữ căn giữa
      ],
    );
  }

  Widget _roundButton(BuildContext context,
      {required IconData icon, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final AuthController auth;
  final VoidCallback onSignIn;
  const _ProfileHeaderCard({
    required this.auth,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLoggedIn = auth.isLoggedIn;
    final String displayName = isLoggedIn &&
            auth.displayName.trim().isNotEmpty &&
            auth.displayName.toLowerCase() != 'guest'
        ? auth.displayName
        : 'Khách';
    final String subtitle =
        isLoggedIn && (auth.email != null && auth.email!.trim().isNotEmpty)
            ? auth.email!.trim()
            : 'Chưa đăng nhập';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage:
                    auth.photoURL != null ? NetworkImage(auth.photoURL!) : null,
                backgroundColor: Colors.yellow.shade400,
                child: auth.photoURL == null
                    ? const Icon(Icons.sentiment_satisfied_alt,
                        size: 32, color: Colors.black87)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLoggedIn) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Đăng nhập Google'),
                onPressed: onSignIn,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileOptionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      enabled: onTap != null,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
