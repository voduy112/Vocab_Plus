import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'create_deck_dialog.dart';
import '../../../core/models/deck.dart';
import 'deck_row.dart';

enum DeskSortOption {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
}

class DeckTable extends StatelessWidget {
  final List<Deck> desks;
  final Map<int, Map<String, dynamic>> deskStats;
  final bool isLoading;
  final String searchQuery;
  final DeskSortOption sortOption;
  final VoidCallback onNameSortToggle;
  final Function(Deck) onDeckTap;
  final Function(Deck) onDeckLongPress;
  final VoidCallback? onCreateDeck;

  const DeckTable({
    super.key,
    required this.desks,
    required this.deskStats,
    required this.isLoading,
    required this.searchQuery,
    required this.sortOption,
    required this.onNameSortToggle,
    required this.onDeckTap,
    required this.onDeckLongPress,
    this.onCreateDeck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: onNameSortToggle,
                    child: Row(
                      children: [
                        Text(
                          'TITLE',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          sortOption == DeskSortOption.nameAsc
                              ? Icons.keyboard_arrow_up
                              : sortOption == DeskSortOption.nameDesc
                                  ? Icons.keyboard_arrow_down
                                  : Icons.unfold_more,
                          size: 16,
                          color: (sortOption == DeskSortOption.nameAsc ||
                                  sortOption == DeskSortOption.nameDesc)
                              ? Colors.blue[600]
                              : Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'NEW',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'LEARNED',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'DUE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rows
          if (desks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Lottie.asset(
                      'lib/core/assets/splash/Card preloader.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    searchQuery.isEmpty
                        ? 'No decks found'
                        : 'Không tìm thấy deck nào',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (onCreateDeck != null) {
                        onCreateDeck!();
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const CreateDeckDialog(),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tạo deck'),
                  ),
                ],
              ),
            )
          else ...[
            if (desks.length > 4)
              SizedBox(
                // Approximate height for 5 rows; adjust if your row height changes
                height: 5 * 70,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: desks.length,
                  itemBuilder: (context, index) {
                    final desk = desks[index];
                    return DeckRow(
                      desk: desk,
                      stats: deskStats[desk.id] ??
                          {
                            'total': 0,
                            'learned': 0,
                            'mastered': 0,
                            'needReview': 0,
                            'avgMastery': 0.0,
                            'progress': 0.0,
                          },
                      onTap: () => onDeckTap(desk),
                      onLongPress: () => onDeckLongPress(desk),
                    );
                  },
                ),
              )
            else
              ...desks.map((desk) => DeckRow(
                    desk: desk,
                    stats: deskStats[desk.id] ??
                        {
                          'total': 0,
                          'learned': 0,
                          'mastered': 0,
                          'needReview': 0,
                          'avgMastery': 0.0,
                          'progress': 0.0,
                        },
                    onTap: () => onDeckTap(desk),
                    onLongPress: () => onDeckLongPress(desk),
                  )),
          ],
        ],
      ),
    );
  }
}
