import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'history_tab.dart';
import '../../../core/models/deck.dart';
import '../../decks/services/deck_preload_cache.dart';
import '../../decks/services/deck_service.dart';

class PronunciationSelectDeckScreen extends StatefulWidget {
  const PronunciationSelectDeckScreen({super.key});

  @override
  State<PronunciationSelectDeckScreen> createState() =>
      _PronunciationSelectDeckScreenState();
}

class _PronunciationSelectDeckScreenState
    extends State<PronunciationSelectDeckScreen> {
  final DeckPreloadCache _cache = DeckPreloadCache();
  final DeckService _deckService = DeckService();

  bool _isLoading = true;
  List<Deck> _decks = const [];
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = _cache.getCachedDecks();
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _decks = cached;
        _isLoading = false;
      });
      return;
    }

    try {
      final decks = await _deckService.getAllDecks();
      setState(() {
        _decks = decks;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Deck> get _filteredDecks {
    if (_query.trim().isEmpty) return _decks;
    final lower = _query.trim().toLowerCase();
    return _decks.where((d) => d.name.toLowerCase().contains(lower)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              context.go('/tabs/main');
            },
          ),
          title: const Text('Chọn bộ từ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bộ từ'),
              Tab(text: 'Lịch sử học'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_decks.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() => _isLoading = true);
                          await _cache.reload();
                          final reloaded = _cache.getCachedDecks() ??
                              await _deckService.getAllDecks();
                          if (!mounted) return;
                          setState(() {
                            _decks = reloaded;
                            _isLoading = false;
                          });
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            // Search bar
                            TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm bộ từ...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                filled: true,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant
                                    .withOpacity(0.4),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Deck list
                            ..._filteredDecks.map((deck) {
                              final stats = DeckPreloadCache().getCachedStats();
                              final deckStats =
                                  (deck.id != null && stats != null)
                                      ? stats[deck.id!]
                                      : null;
                              final total = deckStats != null
                                  ? (deckStats['total'] as int? ?? 0)
                                  : 0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Chọn bộ: ${deck.name}')),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .dividerColor
                                            .withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey[200],
                                            ),
                                            child: Icon(
                                                Icons.library_books_rounded,
                                                color: Colors.grey[700]),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  deck.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (total > 0)
                                            Chip(
                                              label: Text('$total từ'),
                                              backgroundColor: Colors.grey[200],
                                              labelStyle: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                          const SizedBox(width: 6),
                                          Icon(Icons.chevron_right_rounded,
                                              color: Colors.grey[700]),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            if (_filteredDecks.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 48),
                                child: Column(
                                  children: [
                                    const Icon(Icons.search_off_rounded,
                                        size: 40, color: Colors.grey),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Không tìm thấy bộ từ phù hợp',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )),
            const PronunciationHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Chưa có bộ từ nào',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy tạo một bộ từ để bắt đầu luyện phát âm',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
