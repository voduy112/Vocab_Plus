// features/decks/controllers/deck_screen_controller.dart
import 'package:flutter/material.dart';
import '../../../core/models/deck.dart';
import '../services/deck_service.dart';
import '../services/deck_preload_cache.dart';
import '../widgets/deck_table.dart';

class DeckScreenController extends ChangeNotifier {
  final DeckService _deckService = DeckService();
  final TextEditingController searchController = TextEditingController();

  List<Deck> _decks = [];
  List<Deck> _filteredDecks = [];
  Map<int, Map<String, dynamic>> _deckStats = {};
  bool _isLoading = true;
  bool _hasLoadedData = false;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  DeskSortOption _sortOption = DeskSortOption.nameAsc;

  // Getters
  List<Deck> get decks => _decks;
  List<Deck> get filteredDecks => _filteredDecks;
  Map<int, Map<String, dynamic>> get deckStats => _deckStats;
  bool get isLoading => _isLoading;
  bool get hasLoadedData => _hasLoadedData;
  bool get isSearchVisible => _isSearchVisible;
  String get searchQuery => _searchQuery;
  DeskSortOption get sortOption => _sortOption;

  DeckScreenController() {
    searchController.addListener(_onSearchChanged);
    loadDecks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadDecks({bool forceReload = false}) async {
    if (_hasLoadedData && !forceReload) {
      return;
    }

    // Kiểm tra cache từ splash screen
    final deckPreloadCache = DeckPreloadCache();
    if (!forceReload && deckPreloadCache.hasData) {
      final cachedDecks = deckPreloadCache.getCachedDecks();
      final cachedStats = deckPreloadCache.getCachedStats();

      if (cachedDecks != null && cachedStats != null) {
        _decks = cachedDecks;
        _filteredDecks = cachedDecks;
        _deckStats = cachedStats;
        _isLoading = false;
        _hasLoadedData = true;
        _sortDecks();
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final decks = await _deckService.getAllDecks();
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

      _decks = decks;
      _filteredDecks = decks;
      _deckStats = statsMap;
      _isLoading = false;
      _hasLoadedData = true;
      _sortDecks();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void _sortDecks() {
    _filteredDecks.sort((a, b) {
      // Ưu tiên deck yêu thích lên đầu
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;

      // Nếu cùng trạng thái favorite, sắp xếp theo sortOption
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
  }

  void toggleNameSort() {
    if (_sortOption == DeskSortOption.nameAsc) {
      _sortOption = DeskSortOption.nameDesc;
    } else {
      _sortOption = DeskSortOption.nameAsc;
    }
    _sortDecks();
    notifyListeners();
  }

  void toggleSearch() {
    _isSearchVisible = !_isSearchVisible;
    if (!_isSearchVisible) {
      searchController.clear();
      _searchQuery = '';
      _filteredDecks = _decks;
      _sortDecks();
    }
    notifyListeners();
  }

  void _onSearchChanged() {
    _searchQuery = searchController.text;
    if (_searchQuery.isEmpty) {
      _filteredDecks = _decks;
    } else {
      _filteredDecks = _decks
          .where((deck) =>
              deck.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    _sortDecks();
    notifyListeners();
  }

  Future<void> deleteDeck(Deck deck) async {
    await _deckService.deleteDeck(deck.id!);
    // Clear cache khi xóa deck
    DeckPreloadCache().clearCache();
    await loadDecks(forceReload: true);
  }
}
