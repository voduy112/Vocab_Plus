// features/decks/deck_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/deck.dart';
import '../../../core/widgets/search_field.dart';
import '../services/deck_preload_cache.dart';
import 'deck_overview_screen.dart';
import '../widgets/create_deck_dialog.dart';
import '../widgets/featured_card.dart';
import '../widgets/deck_table.dart';
import '../widgets/deck_context_menu.dart';
import '../controllers/deck_screen_controller.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _createNewDeck(
      BuildContext context, DeckScreenController controller) async {
    final result = await showModalBottomSheet<Deck?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateDeckDialog(),
    );
    if (result != null) {
      // Clear cache khi có deck mới
      DeckPreloadCache().clearCache();
      await controller.loadDecks(forceReload: true);
    }
  }

  Widget _buildHeader() {
    return Consumer<DeckScreenController>(
      builder: (context, controller, _) {
        return Container(
          key: const ValueKey('header'),
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
                      if (controller.filteredDecks.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: () => _createNewDeck(context, controller),
                            borderRadius: BorderRadius.circular(8),
                            child: const Icon(Icons.add,
                                size: 20, color: Colors.white),
                          ),
                        ),
                      if (controller.filteredDecks.isNotEmpty)
                        const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: controller.isSearchVisible
                              ? Colors.blue[100]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => controller.toggleSearch(),
                          borderRadius: BorderRadius.circular(8),
                          child: Icon(
                            controller.isSearchVisible
                                ? Icons.close
                                : Icons.search,
                            size: 20,
                            color: controller.isSearchVisible
                                ? Colors.blue[600]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchOnlyView() {
    return Consumer<DeckScreenController>(
      builder: (context, controller, _) {
        return Container(
          key: const ValueKey('search'),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => controller.toggleSearch(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child:
                              Icon(Icons.arrow_back, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: Search(
                          controller: controller.searchController,
                          hintText: 'Search decks...',
                          autofocus: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedCards() {
    return Consumer<DeckScreenController>(
      builder: (context, controller, _) {
        int totalWords = 0;
        int totalLearned = 0;
        int totalDue = 0;

        for (final deck in controller.decks) {
          if (deck.id != null && controller.deckStats.containsKey(deck.id)) {
            final stats = controller.deckStats[deck.id!]!;
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
      },
    );
  }

  Widget _buildDeckTable() {
    return Consumer<DeckScreenController>(
      builder: (context, controller, _) {
        return DeckTable(
          desks: controller.filteredDecks,
          deskStats: controller.deckStats,
          isLoading: controller.isLoading,
          searchQuery: controller.searchQuery,
          sortOption: controller.sortOption,
          onNameSortToggle: () => controller.toggleNameSort(),
          onDeckTap: (deck) => _navigateToDeckDetail(context, controller, deck),
          onDeckLongPress: (deck) =>
              _showDeckContextMenu(context, controller, deck),
          onCreateDeck: controller.filteredDecks.isEmpty
              ? () => _createNewDeck(context, controller)
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider(
      create: (_) => DeckScreenController(),
      child: Consumer<DeckScreenController>(
        builder: (context, controller, _) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, -1.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: controller.isSearchVisible
                        ? _buildSearchOnlyView()
                        : _buildHeader(),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => controller.loadDecks(forceReload: true),
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
        },
      ),
    );
  }

  void _navigateToDeckDetail(
      BuildContext context, DeckScreenController controller, Deck deck) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final stats =
              (deck.id != null) ? controller.deckStats[deck.id!] : null;
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

    // Refresh danh sách khi quay lại để cập nhật trạng thái favorite
    await controller.loadDecks(forceReload: true);
  }

  void _showDeckContextMenu(
      BuildContext context, DeckScreenController controller, Deck deck) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DeckContextMenu(
        deck: deck,
        onDelete: () => _deleteDeck(context, controller, deck),
      ),
    );
  }

  Future<void> _deleteDeck(
      BuildContext context, DeckScreenController controller, Deck deck) async {
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
        await controller.deleteDeck(deck);

        if (context.mounted) {
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
        if (context.mounted) {
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
