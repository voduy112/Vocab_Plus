// features/decks/deck_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/deck.dart';
import '../services/deck_service.dart';
import '../services/deck_preload_cache.dart';
// import 'deck_detail_screen.dart';
import 'deck_overview_screen.dart';
import '../widgets/create_deck_dialog.dart';
import '../widgets/featured_card.dart';
import '../widgets/deck_table.dart';
import '../widgets/deck_context_menu.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen>
    with AutomaticKeepAliveClientMixin {
  final DeckService _deckService = DeckService();
  final TextEditingController _searchController = TextEditingController();

  List<Deck> _decks = [];
  List<Deck> _filteredDecks = [];
  Map<int, Map<String, dynamic>> _deckStats = {};
  bool _isLoading = true;
  bool _hasLoadedData = false;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  DeskSortOption _sortOption = DeskSortOption.nameAsc;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDecks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks({bool forceReload = false}) async {
    if (_hasLoadedData && !forceReload) {
      return;
    }

    // Kiểm tra cache từ splash screen
    final deckPreloadCache = DeckPreloadCache();
    if (!forceReload && deckPreloadCache.hasData) {
      final cachedDecks = deckPreloadCache.getCachedDecks();
      final cachedStats = deckPreloadCache.getCachedStats();

      if (cachedDecks != null && cachedStats != null) {
        setState(() {
          _decks = cachedDecks;
          _filteredDecks = cachedDecks;
          _deckStats = cachedStats;
          _isLoading = false;
          _hasLoadedData = true;
        });
        _sortDecks();
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final decks = await _deckService.getAllDecks();
      if (mounted) {
        final Map<int, Map<String, dynamic>> statsMap = {};
        for (final deck in decks) {
          if (deck.id != null) {
            try {
              final stats = await _deckService.getDeckStats(deck.id!);
              statsMap[deck.id!] = stats;
            } catch (e) {
              statsMap[deck.id!] = {
                'total': 0,
                'learned': 0,
                'mastered': 0,
                'needReview': 0,
                'avgMastery': 0.0,
                'progress': 0.0,
              };
            }
          }
        }

        setState(() {
          _decks = decks;
          _filteredDecks = decks;
          _deckStats = statsMap;
          _isLoading = false;
          _hasLoadedData = true;
        });
        _sortDecks();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading decks: $e')),
        );
      }
    }
  }

  void _sortDecks() {
    setState(() {
      _filteredDecks.sort((a, b) {
        switch (_sortOption) {
          case DeskSortOption.nameAsc:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case DeskSortOption.nameDesc:
            return b.name.toLowerCase().compareTo(a.name.toLowerCase());
          case DeskSortOption.dateAsc:
            return a.createdAt.compareTo(b.createdAt);
          case DeskSortOption.dateDesc:
            return b.createdAt.compareTo(a.createdAt);
        }
      });
    });
  }

  void _toggleNameSort() {
    setState(() {
      if (_sortOption == DeskSortOption.nameAsc) {
        _sortOption = DeskSortOption.nameDesc;
      } else {
        _sortOption = DeskSortOption.nameAsc;
      }
    });
    _sortDecks();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
        _filteredDecks = _decks;
        _sortDecks();
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      if (_searchQuery.isEmpty) {
        _filteredDecks = _decks;
      } else {
        _filteredDecks = _decks
            .where((deck) =>
                deck.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
      _sortDecks();
    });
  }

  Future<void> _createNewDeck() async {
    final result = await showModalBottomSheet<Deck?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateDeckDialog(),
    );
    if (result != null) {
      // Clear cache khi có deck mới
      DeckPreloadCache().clearCache();
      await _loadDecks(forceReload: true);
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DECKS',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: _createNewDeck,
                      borderRadius: BorderRadius.circular(8),
                      child:
                          const Icon(Icons.add, size: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isSearchVisible
                          ? Colors.blue[100]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: _toggleSearch,
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        _isSearchVisible ? Icons.close : Icons.search,
                        size: 20,
                        color: _isSearchVisible
                            ? Colors.blue[600]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isSearchVisible) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 48,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturedCards() {
    int totalWords = 0;
    int totalLearned = 0;
    int totalDue = 0;

    for (final deck in _decks) {
      if (deck.id != null && _deckStats.containsKey(deck.id)) {
        final stats = _deckStats[deck.id!]!;
        totalWords += stats['total'] as int;
        totalLearned += stats['learned'] as int;
        totalDue += stats['needReview'] as int;
      }
    }

    final totalNewWords = totalWords - totalLearned;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: FeaturedCard(
        totalWords: totalWords,
        totalLearned: totalLearned,
        totalNewWords: totalNewWords,
        totalDue: totalDue,
      ),
    );
  }

  Widget _buildDeckTable() {
    return DeckTable(
      desks: _filteredDecks,
      deskStats: _deckStats,
      isLoading: _isLoading,
      searchQuery: _searchQuery,
      sortOption: _sortOption,
      onNameSortToggle: _toggleNameSort,
      onDeckTap: _navigateToDeckDetail,
      onDeckLongPress: _showDeckContextMenu,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadDecks(forceReload: true),
                child: ListView(
                  children: [
                    _buildFeaturedCards(),
                    _buildDeckTable(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDeckDetail(Deck deck) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final stats = (deck.id != null) ? _deckStats[deck.id!] : null;
          final int? initialNewCount = (stats != null)
              ? ((stats['total'] as int? ?? 0) -
                  (stats['learned'] as int? ?? 0))
              : null;
          return DeckOverviewScreen(
            deck: deck,
            initialStats: stats,
            initialNewCount: initialNewCount,
          );
        },
      ),
    );
  }

  void _showDeckContextMenu(Deck deck) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DeckContextMenu(
        deck: deck,
        onDelete: () => _deleteDeck(deck),
      ),
    );
  }

  Future<void> _deleteDeck(Deck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa deck'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn xóa deck "${deck.name}"?'),
            const SizedBox(height: 8),
            const Text(
              'Hành động này sẽ xóa deck và tất cả từ vựng bên trong. Không thể hoàn tác.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _deckService.deleteDeck(deck.id!);
        // Clear cache khi xóa deck
        DeckPreloadCache().clearCache();
        await _loadDecks(forceReload: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text('Đã xóa deck "${deck.name}" thành công'),
                ],
              ),
              backgroundColor: Colors.green[50],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Text('Lỗi khi xóa deck: $e'),
                ],
              ),
              backgroundColor: Colors.red[50],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
