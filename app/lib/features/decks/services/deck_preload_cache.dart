import '../../../core/models/deck.dart';
import 'deck_service.dart';

/// Service để cache dữ liệu decks đã được preload từ splash screen
class DeckPreloadCache {
  static final DeckPreloadCache _instance = DeckPreloadCache._internal();
  factory DeckPreloadCache() => _instance;
  DeckPreloadCache._internal();

  List<Deck>? _cachedDecks;
  Map<int, Map<String, dynamic>>? _cachedStats;
  bool _isLoading = false;
  bool _hasData = false;

  /// Preload dữ liệu decks và stats
  Future<void> preloadDecks() async {
    if (_isLoading || _hasData) {
      return;
    }

    _isLoading = true;
    try {
      final deckService = DeckService();
      final decks = await deckService.getAllDecks();

      final Map<int, Map<String, dynamic>> statsMap = {};
      for (final deck in decks) {
        if (deck.id != null) {
          try {
            final stats = await deckService.getDeckStats(deck.id!);
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

      _cachedDecks = decks;
      _cachedStats = statsMap;
      _hasData = true;
    } catch (e) {
      // Nếu có lỗi, vẫn giữ cache là null
      _cachedDecks = null;
      _cachedStats = null;
    } finally {
      _isLoading = false;
    }
  }

  /// Lấy dữ liệu decks đã cache
  List<Deck>? getCachedDecks() => _cachedDecks;

  /// Lấy dữ liệu stats đã cache
  Map<int, Map<String, dynamic>>? getCachedStats() => _cachedStats;

  /// Kiểm tra xem dữ liệu đã được load chưa
  bool get hasData => _hasData;

  /// Kiểm tra xem đang loading không
  bool get isLoading => _isLoading;

  /// Clear cache (khi cần reload)
  void clearCache() {
    _cachedDecks = null;
    _cachedStats = null;
    _hasData = false;
  }

  /// Invalidate cache và reload
  Future<void> reload() async {
    clearCache();
    await preloadDecks();
  }
}
