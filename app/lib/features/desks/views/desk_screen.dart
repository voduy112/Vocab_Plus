// features/desks/desks_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/desk.dart';
import '../../../core/services/database_service.dart';
import 'desk_detail_screen.dart';
import '../widgets/create_desk_dialog.dart';

class DesksScreen extends StatefulWidget {
  const DesksScreen({super.key});

  @override
  State<DesksScreen> createState() => _DesksScreenState();
}

enum DeskSortOption {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
}

class _DesksScreenState extends State<DesksScreen>
    with AutomaticKeepAliveClientMixin {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Desk> _desks = [];
  List<Desk> _filteredDesks = [];
  Map<int, Map<String, dynamic>> _deskStats = {};
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
    _loadDesks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDesks({bool forceReload = false}) async {
    // Nếu đã có data và không force reload thì không load lại
    if (_hasLoadedData && !forceReload) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final desks = await _databaseService.getAllDesks();
      if (mounted) {
        // Load stats for each desk
        final Map<int, Map<String, dynamic>> statsMap = {};
        for (final desk in desks) {
          if (desk.id != null) {
            try {
              final stats = await _databaseService.getDeskStats(desk.id!);
              statsMap[desk.id!] = stats;
            } catch (e) {
              // If stats loading fails, use default values
              statsMap[desk.id!] = {
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
          _desks = desks;
          _filteredDesks = desks;
          _deskStats = statsMap;
          _isLoading = false;
          _hasLoadedData = true;
        });
        _sortDesks();
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

  void _sortDesks() {
    setState(() {
      _filteredDesks.sort((a, b) {
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
    _sortDesks();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
        _filteredDesks = _desks;
        _sortDesks();
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      if (_searchQuery.isEmpty) {
        _filteredDesks = _desks;
      } else {
        _filteredDesks = _desks
            .where((desk) =>
                desk.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
      _sortDesks();
    });
  }

  Future<void> _createNewDesk() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => const CreateDeskDialog(),
    );

    if (result != null) {
      try {
        final now = DateTime.now();
        final desk = Desk(
          name: result['name']!,
          color: result['color'] ?? '#2196F3',
          createdAt: now,
          updatedAt: now,
        );

        await _databaseService.createDesk(desk);
        await _loadDesks(forceReload: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text('Created deck "${desk.name}" successfully'),
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
                  Text('Error creating deck: $e'),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //Title
              Text(
                'DECKS',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              // Right side icons
              Row(
                children: [
                  // Create new deck button
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: _createNewDesk,
                      borderRadius: BorderRadius.circular(8),
                      child:
                          const Icon(Icons.add, size: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Search
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
          // Search bar
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
    // Calculate total stats across all desks
    int totalWords = 0;
    int totalLearned = 0;
    int totalDue = 0;

    for (final desk in _desks) {
      if (desk.id != null && _deskStats.containsKey(desk.id)) {
        final stats = _deskStats[desk.id!]!;
        totalWords += stats['total'] as int;
        totalLearned += stats['learned'] as int;
        totalDue += stats['needReview'] as int;
      }
    }

    // Calculate new words (not learned yet)
    final totalNewWords = totalWords - totalLearned;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: _buildFeaturedCard(
        totalWords: totalWords,
        totalLearned: totalLearned,
        totalNewWords: totalNewWords,
        totalDue: totalDue,
        totalDecks: _desks.length,
      ),
    );
  }

  Widget _buildFeaturedCard({
    required int totalWords,
    required int totalLearned,
    required int totalNewWords,
    required int totalDue,
    required int totalDecks,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.pink.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.library_books,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Overview',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.book,
                  label: 'Total Words',
                  value: totalWords.toString(),
                  color: Colors.white70,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Learned',
                  value: totalLearned.toString(),
                  color: Colors.green[200]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.new_releases,
                  label: 'New Words',
                  value: totalNewWords.toString(),
                  color: Colors.blue[200]!,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.schedule,
                  label: 'Need Review',
                  value: totalDue.toString(),
                  color: Colors.orange[200]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalDecks deck${totalDecks > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDeckTable() {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    onTap: _toggleNameSort,
                    child: Row(
                      children: [
                        Text(
                          'DECK TITLE',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _sortOption == DeskSortOption.nameAsc
                              ? Icons.keyboard_arrow_up
                              : _sortOption == DeskSortOption.nameDesc
                                  ? Icons.keyboard_arrow_down
                                  : Icons.unfold_more,
                          size: 16,
                          color: (_sortOption == DeskSortOption.nameAsc ||
                                  _sortOption == DeskSortOption.nameDesc)
                              ? Colors.blue[600]
                              : Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'COMPLETE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'DUE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_filteredDesks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No decks found'
                        : 'Không tìm thấy deck nào',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._filteredDesks.map((desk) => _buildDeckRow(desk)),
        ],
      ),
    );
  }

  Widget _buildDeckRow(Desk desk) {
    final stats = _deskStats[desk.id] ??
        {
          'total': 0,
          'learned': 0,
          'mastered': 0,
          'needReview': 0,
          'avgMastery': 0.0,
          'progress': 0.0,
        };

    final int needReview = stats['needReview'] as int;
    final double progress = stats['progress'] as double;
    final int total = stats['total'] as int;
    final int learned = stats['learned'] as int;

    return InkWell(
      onTap: () => _navigateToDeskDetail(desk),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desk.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$learned/$total words',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                needReview.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: needReview > 0 ? Colors.orange[600] : Colors.grey[600],
                  fontSize: 12,
                  fontWeight:
                      needReview > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadDesks(forceReload: true),
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

  void _navigateToDeskDetail(Desk desk) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeskDetailScreen(desk: desk),
      ),
    );
  }
}
