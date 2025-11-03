import 'package:flutter/material.dart';
import '../../../core/models/deck.dart';
import '../../../core/models/vocabulary.dart';
import '../services/deck_service.dart';
import '../services/vocabulary_service.dart';
import '../../study_session/views/study_session_screen.dart';
import '../widgets/vocabulary_card.dart';
import 'package:go_router/go_router.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck desk;

  const DeckDetailScreen({
    super.key,
    required this.desk,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final DeckService _deskService = DeckService();
  final VocabularyService _vocabularyService = VocabularyService();
  final TextEditingController _searchController = TextEditingController();

  List<Vocabulary> _vocabularies = [];
  List<Vocabulary> _filteredVocabularies = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVocabularies();
    _loadDeskStats();
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
          await _vocabularyService.getVocabulariesByDeskId(widget.desk.id!);
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

  Future<void> _loadDeskStats() async {
    try {
      await _deskService.getDeskStats(widget.desk.id!);
      await _vocabularyService.countMinuteLearningByDesk(widget.desk.id!);
    } catch (e) {
      print('Lỗi khi tải thống kê desk: $e');
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
        await context.push<bool>('/add-vocabulary', extra: widget.desk);

    if (result == true && mounted) {
      await _loadVocabularies();
      await _loadDeskStats();
    }
  }

  Future<void> _editVocabulary(Vocabulary vocabulary) async {
    final result = await context.push<bool>(
      '/edit-vocabulary',
      extra: {'desk': widget.desk, 'vocabulary': vocabulary},
    );

    if (result == true && mounted) {
      await _loadVocabularies();
      await _loadDeskStats();
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
        await _loadDeskStats();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.desk.name),
        backgroundColor:
            Color(int.parse(widget.desk.color.replaceFirst('#', '0xFF'))),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudySessionScreen(desk: widget.desk),
                ),
              );
              // Refresh thống kê sau khi học xong
              await _loadDeskStats();
            },
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: 'Bắt đầu học',
          ),
          IconButton(
            onPressed: _addNewVocabulary,
            icon: const Icon(Icons.add),
            tooltip: 'Thêm từ vựng',
          ),
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
                          // Header labels and list
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _filteredVocabularies.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final vocabulary = _filteredVocabularies[index];
                                return VocabularyCard(
                                  vocabulary: vocabulary,
                                  onTap: () => _editVocabulary(vocabulary),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewVocabulary,
        backgroundColor:
            Color(int.parse(widget.desk.color.replaceFirst('#', '0xFF'))),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
