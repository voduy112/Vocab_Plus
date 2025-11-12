import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/deck.dart';
import '../../../core/models/vocabulary.dart';
import '../services/deck_service.dart';
import '../services/vocabulary_service.dart';
import '../widgets/vocabulary_card.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailScreen({
    super.key,
    required this.deck,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final DeckService _deckService = DeckService();
  final VocabularyService _vocabularyService = VocabularyService();
  final TextEditingController _searchController = TextEditingController();

  List<Vocabulary> _vocabularies = [];
  List<Vocabulary> _filteredVocabularies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSelectionMode = false;
  Set<int> _selectedVocabularyIds = {};

  @override
  void initState() {
    super.initState();
    _loadVocabularies();
    _loadDeckStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabularies() async {
    setState(() => _isLoading = true);
    try {
      final vocabularies =
          await _vocabularyService.getVocabulariesByDeckId(widget.deck.id!);
      setState(() {
        _vocabularies = vocabularies;
        _filteredVocabularies = vocabularies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải từ vựng: $e')),
        );
      }
    }
  }

  Future<void> _loadDeckStats() async {
    try {
      await _deckService.getDeckStats(widget.deck.id!);
      await _vocabularyService.countMinuteLearningByDeck(widget.deck.id!);
    } catch (e) {
      print('Lỗi khi tải thống kê deck: $e');
    }
  }

  void _filterVocabularies(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredVocabularies = _vocabularies;
      } else {
        _filteredVocabularies = _vocabularies
            .where((vocab) =>
                vocab.front.toLowerCase().contains(query.toLowerCase()) ||
                vocab.back.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _addNewVocabulary() async {
    final result =
        await context.push<bool>('/add-vocabulary', extra: widget.deck);

    if (result == true && mounted) {
      await _loadVocabularies();
      await _loadDeckStats();
    }
  }

  Future<void> _editVocabulary(Vocabulary vocabulary) async {
    final result = await context.push<bool>(
      '/edit-vocabulary',
      extra: {'deck': widget.deck, 'vocabulary': vocabulary},
    );

    if (result == true && mounted) {
      await _loadVocabularies();
      await _loadDeckStats();
    }
  }

  Future<void> _deleteVocabulary(Vocabulary vocabulary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa từ vựng'),
        content: Text('Bạn có chắc chắn muốn xóa từ "${vocabulary.front}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _vocabularyService.deleteVocabulary(vocabulary.id!);
        await _loadVocabularies();
        await _loadDeckStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa từ vựng thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa từ vựng: $e')),
          );
        }
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedVocabularyIds.clear();
      }
    });
  }

  void _toggleVocabularySelection(int vocabularyId) {
    setState(() {
      if (_selectedVocabularyIds.contains(vocabularyId)) {
        _selectedVocabularyIds.remove(vocabularyId);
      } else {
        _selectedVocabularyIds.add(vocabularyId);
      }
    });
  }

  void _selectAllVocabularies() {
    setState(() {
      _selectedVocabularyIds = _filteredVocabularies
          .where((vocab) => vocab.id != null)
          .map((vocab) => vocab.id!)
          .toSet();
    });
  }

  void _deselectAllVocabularies() {
    setState(() {
      _selectedVocabularyIds.clear();
    });
  }

  Future<void> _deleteSelectedVocabularies() async {
    if (_selectedVocabularyIds.isEmpty) return;

    final count = _selectedVocabularyIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa từ vựng'),
        content: Text('Bạn có chắc chắn muốn xóa $count từ vựng đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final id in _selectedVocabularyIds) {
          await _vocabularyService.deleteVocabulary(id);
        }
        await _loadVocabularies();
        await _loadDeckStats();

        setState(() {
          _selectedVocabularyIds.clear();
          _isSelectionMode = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xóa $count từ vựng thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa từ vựng: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('Đã chọn: ${_selectedVocabularyIds.length}')
            : Text(widget.deck.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            // Nút chọn tất cả / bỏ chọn tất cả
            IconButton(
              onPressed: _selectedVocabularyIds.length ==
                      _filteredVocabularies.where((v) => v.id != null).length
                  ? _deselectAllVocabularies
                  : _selectAllVocabularies,
              icon: Icon(
                _selectedVocabularyIds.length ==
                        _filteredVocabularies.where((v) => v.id != null).length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              tooltip: _selectedVocabularyIds.length ==
                      _filteredVocabularies.where((v) => v.id != null).length
                  ? 'Bỏ chọn tất cả'
                  : 'Chọn tất cả',
            ),
            // Nút xóa đã chọn
            if (_selectedVocabularyIds.isNotEmpty)
              IconButton(
                onPressed: _deleteSelectedVocabularies,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Xóa đã chọn',
              ),
          ] else ...[
            IconButton(
              onPressed: _toggleSelectionMode,
              icon: const Icon(Icons.checklist),
              tooltip: 'Chọn để xóa',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterVocabularies,
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

          // Danh sách từ vựng
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVocabularies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Chưa có từ vựng nào'
                                  : 'Không tìm thấy từ vựng nào',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Nhấn nút + để thêm từ vựng đầu tiên',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Header row
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (_isSelectionMode) ...[
                                  const SizedBox(width: 40),
                                  const SizedBox(width: 8),
                                ],
                                // Cột 1: Front
                                Expanded(
                                  child: Text(
                                    'Front',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                // Divider
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  color: Colors.grey[300],
                                ),
                                // Cột 2: Back
                                Expanded(
                                  child: Text(
                                    'Back',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                // Divider
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  color: Colors.grey[300],
                                ),
                                // Cột 3: Ngày tới hạn
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Due Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                // Space cho icon 3 chấm
                                if (!_isSelectionMode) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(width: 40),
                                ],
                              ],
                            ),
                          ),
                          // List
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: _filteredVocabularies.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final vocabulary = _filteredVocabularies[index];
                                final isSelected = vocabulary.id != null &&
                                    _selectedVocabularyIds
                                        .contains(vocabulary.id);
                                return VocabularyCard(
                                  vocabulary: vocabulary,
                                  isSelectionMode: _isSelectionMode,
                                  isSelected: isSelected,
                                  onTap: _isSelectionMode
                                      ? () {
                                          if (vocabulary.id != null) {
                                            _toggleVocabularySelection(
                                                vocabulary.id!);
                                          }
                                        }
                                      : () => _editVocabulary(vocabulary),
                                  onDelete: () => _deleteVocabulary(vocabulary),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _addNewVocabulary,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}
