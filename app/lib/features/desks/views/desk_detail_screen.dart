import 'package:flutter/material.dart';
import '../../../core/models/desk.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/services/database_service.dart';
import '../widgets/stat_card.dart';
import 'study_session_screen.dart';
import '../widgets/vocabulary_card.dart';
import '../widgets/add_vocabulary_dialog.dart';

class DeskDetailScreen extends StatefulWidget {
  final Desk desk;

  const DeskDetailScreen({
    super.key,
    required this.desk,
  });

  @override
  State<DeskDetailScreen> createState() => _DeskDetailScreenState();
}

class _DeskDetailScreenState extends State<DeskDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Vocabulary> _vocabularies = [];
  List<Vocabulary> _filteredVocabularies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, dynamic>? _deskStats;

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
          await _databaseService.getVocabulariesByDeskId(widget.desk.id!);
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
      final stats = await _databaseService.getDeskStats(widget.desk.id!);
      setState(() {
        _deskStats = stats;
      });
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
                vocab.word.toLowerCase().contains(query.toLowerCase()) ||
                vocab.meaning.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _addNewVocabulary() async {
    final result = await showDialog<Vocabulary>(
      context: context,
      builder: (context) => AddVocabularyDialog(deskId: widget.desk.id!),
    );

    if (result != null) {
      try {
        await _databaseService.createVocabulary(result);
        await _loadVocabularies();
        await _loadDeskStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm từ vựng thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi thêm từ vựng: $e')),
          );
        }
      }
    }
  }

  Future<void> _editVocabulary(Vocabulary vocabulary) async {
    final result = await showDialog<Vocabulary>(
      context: context,
      builder: (context) => AddVocabularyDialog(
        deskId: widget.desk.id!,
        vocabulary: vocabulary,
      ),
    );

    if (result != null) {
      try {
        await _databaseService.updateVocabulary(result);
        await _loadVocabularies();
        await _loadDeskStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật từ vựng thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi cập nhật từ vựng: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteVocabulary(Vocabulary vocabulary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa từ vựng'),
        content: Text('Bạn có chắc chắn muốn xóa từ "${vocabulary.word}"?'),
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
        await _databaseService.deleteVocabulary(vocabulary.id!);
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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudySessionScreen(desk: widget.desk),
                ),
              );
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
          // Header với thống kê
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Color(int.parse(widget.desk.color.replaceFirst('#', '0xFF')))
                      .withOpacity(0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.desk.description != null) ...[
                  Text(
                    widget.desk.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                ],
                if (_deskStats != null) ...[
                  Row(
                    children: [
                      StatCard(
                        title: 'Tổng',
                        value: '${_deskStats!['total']}',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        title: 'Đã học',
                        value: '${_deskStats!['learned']}',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        title: 'Cần ôn',
                        value: '${_deskStats!['needReview']}',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _deskStats!['progress'],
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(int.parse(
                          widget.desk.color.replaceFirst('#', '0xFF'))),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tiến độ: ${(_deskStats!['progress'] * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterVocabularies,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm từ vựng...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredVocabularies.length,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewVocabulary,
        backgroundColor:
            Color(int.parse(widget.desk.color.replaceFirst('#', '0xFF'))),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
