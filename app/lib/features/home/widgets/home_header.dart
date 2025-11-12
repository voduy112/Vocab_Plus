import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/widgets/search_field.dart';
import '../../../data/dictionary/dictionary_repository.dart';
import '../../../data/dictionary/models.dart';
import '../../notifications/widgets/notification_dialog.dart';
import '../../notifications/repositories/notification_repository.dart';

// Widget Header với gradient
class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final TextEditingController _searchController = TextEditingController();
  final DictionaryRepository _dictionaryRepository = DictionaryRepository();
  List<WordEntry> _searchResults = [];
  Timer? _debounce;
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _dictionaryRepository.loadAll();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _dictionaryRepository.search(query, limit: 10);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthController>().displayName;
    final photoURL = context.watch<AuthController>().photoURL;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text và Avatar/Notification row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome text bên trái
              Expanded(
                child: WelcomeText(name: name),
              ),
              // Avatar và Notification icon
              Row(
                children: [
                  UserAvatar(photoURL: photoURL),
                  const SizedBox(width: 12),
                  NotificationIcon(),
                ],
              ),
            ],
          ),
          // Search field
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: Search(
              controller: _searchController,
              hintText: 'Search...',
            ),
          ),
          // Search results
          if (_showResults) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('No results found'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final word = _searchResults[index];
                            final subtitle = word.wordVi ??
                                (word.senses.isNotEmpty
                                    ? (word.senses.first.glossesVi.isNotEmpty
                                        ? word.senses.first.glossesVi.first
                                        : (word.senses.first.glosses.isNotEmpty
                                            ? word.senses.first.glosses.first
                                            : null))
                                    : null);
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: SizedBox(
                                width: 50,
                                child: word.pos != null && word.pos!.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.blueGrey.shade100,
                                          ),
                                        ),
                                        child: Text(
                                          word.pos!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blueGrey.shade700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                word.word,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: subtitle != null
                                  ? Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () {
                                context.push('/word', extra: word);
                                _searchController.clear();
                              },
                            );
                          },
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget Welcome Text
class WelcomeText extends StatelessWidget {
  final String name;

  const WelcomeText({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Widget User Avatar
class UserAvatar extends StatelessWidget {
  final String? photoURL;

  const UserAvatar({
    super.key,
    this.photoURL,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: photoURL != null
          ? ClipOval(
              child: Image.network(
                photoURL!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _defaultAvatar();
                },
              ),
            )
          : _defaultAvatar(),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.yellow.shade400,
      ),
      child: Icon(
        Icons.sentiment_satisfied_alt,
        color: Colors.black87,
        size: 24,
      ),
    );
  }
}

// Widget Notification Icon
class NotificationIcon extends StatefulWidget {
  const NotificationIcon({super.key});

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await _notificationRepository.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await NotificationDialog.show(context);
        _loadUnreadCount(); // Reload count after dialog closes
      },
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade100,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.blue.shade800,
                size: 20,
              ),
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
