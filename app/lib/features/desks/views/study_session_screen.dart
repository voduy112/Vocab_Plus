import 'package:flutter/material.dart';
import '../../../core/models/desk.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/models/study_session.dart';
import '../../../core/services/database_service.dart';

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
      final items = await _service.getVocabulariesForReview(widget.desk.id!);
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
      await _service.reviewWithChoice(
        vocabularyId: v.id!,
        choice: choice,
        sessionType: SessionType.review,
      );
      // Remove reviewed card from queue and move to next
      setState(() {
        _queue.removeAt(_index);
        if (_index >= _queue.length) _index = 0;
      });
      _refreshLabels();
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.celebration,
                          size: 72, color: Colors.green[400]),
                      const SizedBox(height: 12),
                      const Text('Hết từ để học/ôn!'),
                    ],
                  ),
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
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.word,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(v.meaning, style: const TextStyle(fontSize: 16)),
                  if (v.pronunciation != null &&
                      v.pronunciation!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(v.pronunciation!,
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic)),
                  ],
                  if (v.example != null && v.example!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(v.example!,
                        style:
                            TextStyle(color: Colors.grey[800], fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          _choiceRow(),
        ],
      ),
    );
  }

  Widget _choiceRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _labelText(_labels[SrsChoice.again] ?? ''),
            _labelText(_labels[SrsChoice.hard] ?? ''),
            _labelText(_labels[SrsChoice.good] ?? ''),
            _labelText(_labels[SrsChoice.easy] ?? ''),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _pillButton('Lại', () => _choose(SrsChoice.again)),
            _pillButton('Khó', () => _choose(SrsChoice.hard)),
            _pillButton('Được', () => _choose(SrsChoice.good)),
            _pillButton('Dễ', () => _choose(SrsChoice.easy)),
          ],
        ),
      ],
    );
  }

  Widget _labelText(String text) {
    return SizedBox(
      width: 70,
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700], fontSize: 12)),
    );
  }

  Widget _pillButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 78,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }
}
