import 'package:flutter/material.dart';
import '../../../core/models/desk.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/models/study_session.dart';
import '../../../core/services/database_service.dart';
import '../widgets/flashcard.dart';
import '../widgets/empty_state.dart';

class StudySessionScreen extends StatefulWidget {
  final Desk desk;
  const StudySessionScreen({super.key, required this.desk});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final DatabaseService _service = DatabaseService();
  List<Vocabulary> _queue = [];
  int _index = 0;
  bool _isLoading = true;
  Map<SrsChoice, String> _labels = const {};

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.getVocabulariesForStudy(widget.desk.id!);
      setState(() {
        _queue = items;
        _index = 0;
        _isLoading = false;
      });
      _refreshLabels();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách học: $e')),
        );
      }
    }
  }

  void _refreshLabels() {
    if (_queue.isEmpty || _index >= _queue.length) {
      setState(() => _labels = const {});
      return;
    }
    final v = _queue[_index];
    final labels = _service.previewChoiceLabels(v);
    setState(() => _labels = labels);
  }

  Future<void> _choose(SrsChoice choice) async {
    if (_queue.isEmpty || _index >= _queue.length) return;
    final v = _queue[_index];
    try {
      final result = await _service.reviewWithChoice(
        vocabularyId: v.id!,
        choice: choice,
        sessionType: SessionType.review,
      );
      final int updatedSrsType = (result['srsType'] as int?) ?? v.srsType;
      final bool dueIsMinutes = (result['dueIsMinutes'] as bool?) ?? false;
      print('updatedSrsType: $updatedSrsType');
      print('dueIsMinutes: $dueIsMinutes');
      print('choice: $choice');
      print('Từ vựng đã được ghi nhận học với choice: $choice');

      if (!dueIsMinutes || updatedSrsType == 2 || choice == SrsChoice.easy) {
        // Due theo ngày hoặc đã vào review: loại khỏi phiên
        _queue.removeAt(_index);
        if (_index >= _queue.length) _index = 0;
      } else {
        // Còn học theo phút: giữ trong phiên
        final current = _queue.removeAt(_index);
        _queue.add(current);
        if (_index >= _queue.length) _index = 0;
      }
      // Fetch latest SRS for the new front card and update labels immediately
      if (_queue.isEmpty || _index >= _queue.length) {
        setState(() => _labels = const {});
      } else {
        final currentFrontId = _queue[_index].id!;
        final latest = await _service.getVocabularyById(currentFrontId);
        if (!mounted) return;
        setState(() {
          _labels = _service.previewChoiceLabels(latest ?? _queue[_index]);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu kết quả: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(widget.desk.color.replaceFirst('#', '0xFF')));
    return Scaffold(
      appBar: AppBar(
        title: Text('Học: ${widget.desk.name}'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadQueue, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
              ? const EmptyState(
                  message: 'Hết từ để học/ôn!',
                  icon: Icons.celebration,
                )
              : _buildCard(color),
    );
  }

  Widget _buildCard(Color color) {
    final v = _queue[_index];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Flashcard(
              vocabulary: v,
              labels: _labels,
              onChoiceSelected: _choose,
              accentColor: color,
            ),
          ),
        ],
      ),
    );
  }
}
