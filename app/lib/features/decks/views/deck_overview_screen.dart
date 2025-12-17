import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/deck.dart';
import '../repositories/deck_repository.dart';
import '../repositories/vocabulary_repository.dart';
import '../../study_session/views/study_session_screen.dart';
import '../../home/widgets/due_heat_map.dart';

class DeckOverviewScreen extends StatefulWidget {
  final Deck deck;
  final Map<String, dynamic>? initialStats;
  final int? initialNewCount;
  final int? initialMinuteLearningCount;

  const DeckOverviewScreen({
    super.key,
    required this.deck,
    this.initialStats,
    this.initialNewCount,
    this.initialMinuteLearningCount,
  });

  @override
  State<DeckOverviewScreen> createState() => _DeckOverviewScreenState();
}

class _DeckOverviewScreenState extends State<DeckOverviewScreen> {
  final DeckRepository _deckRepository = DeckRepository();
  Map<String, dynamic>? _deckStats;
  int _minuteLearningCount = 0;
  int _newCount = 0;
  // ignore: unused_field
  bool _isLoading = false;
  late Deck _currentDeck;
  Key _heatmapKey = UniqueKey();

  // Learning metrics
  int _dailyAverage = 0;
  double _daysLearnedPercent = 0.0;
  int _longestStreak = 0;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _currentDeck = widget.deck;
    // Seed with initial values if provided, to avoid empty UI on entry
    if (widget.initialStats != null) {
      _deckStats = Map<String, dynamic>.from(widget.initialStats!);
    }
    if (widget.initialNewCount != null) {
      _newCount = widget.initialNewCount!;
    }
    if (widget.initialMinuteLearningCount != null) {
      _minuteLearningCount = widget.initialMinuteLearningCount!;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final deckRepo = context.read<DeckRepository>();
      final vocabRepo = context.read<VocabularyRepository>();
      // Reload deck để lấy trạng thái favorite mới nhất
      if (_currentDeck.id != null) {
        final updatedDeck = await deckRepo.getDeckById(_currentDeck.id!);
        if (updatedDeck != null) {
          setState(() {
            _currentDeck = updatedDeck;
          });
        }
      }
      final stats = await deckRepo.getDeckStats(_currentDeck.id!);
      final minuteLearning =
          await vocabRepo.countMinuteLearning(_currentDeck.id!);
      final newCount = await vocabRepo.countNewVocabularies(_currentDeck.id!);

      final learningMetrics = await _calculateLearningMetrics();

      if (mounted) {
        setState(() {
          _deckStats = stats;
          _minuteLearningCount = minuteLearning;
          _newCount = newCount;
          _dailyAverage = learningMetrics['dailyAverage'] ?? 0;
          _daysLearnedPercent = learningMetrics['daysLearnedPercent'] ?? 0.0;
          _longestStreak = learningMetrics['longestStreak'] ?? 0;
          _currentStreak = learningMetrics['currentStreak'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _calculateLearningMetrics() async {
    return {
      'dailyAverage': 4,
      'daysLearnedPercent': 10.0,
      'longestStreak': 3,
      'currentStreak': 0,
    };
  }

  Future<void> _startStudySession() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudySessionScreen(deck: _currentDeck),
      ),
    );
    if (_currentDeck.id != null) {
      DueHeatMap.invalidateCacheForDeck(_currentDeck.id);
    }
    if (mounted) {
      setState(() {
        _heatmapKey = UniqueKey();
      });
    }
    await _loadData();
  }

  Future<void> _addNewVocabulary() async {
    final result =
        await context.push<bool>('/add-vocabulary', extra: _currentDeck);

    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_currentDeck.id != null) {
        final newFavoriteStatus = !_currentDeck.isFavorite;
        await _deckRepository.toggleFavorite(
            _currentDeck.id!, newFavoriteStatus);
        setState(() {
          _currentDeck = _currentDeck.copyWith(isFavorite: newFavoriteStatus);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật yêu thích: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 15);
    final end = DateTime(now.year, now.month + 2, now.day);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildLearningStatus(),
                    const SizedBox(height: 20),
                    _buildStudyNowButton(),
                    const SizedBox(height: 24),
                    _buildHeatmap(start, end),
                    const SizedBox(height: 24),
                    _buildLearningMetrics(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        Expanded(
          child: Text(
            _currentDeck.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.add, color: Colors.blue[600]),
              onPressed: _addNewVocabulary,
              tooltip: 'Thêm từ vựng',
            ),
            IconButton(
              icon: Icon(
                _currentDeck.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _currentDeck.isFavorite
                    ? Colors.red[600]
                    : Colors.grey[600],
              ),
              onPressed: _toggleFavorite,
              tooltip: _currentDeck.isFavorite
                  ? 'Bỏ yêu thích'
                  : 'Thêm vào yêu thích',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLearningStatus() {
    if (_deckStats == null) return const SizedBox.shrink();
    final needReview = _deckStats!['needReview'] as int;

    return Row(
      children: [
        Expanded(
          child: _buildStatusItem('Mới', _newCount, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              _buildStatusItem('Đang học', _minuteLearningCount, Colors.cyan),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusItem('Cần Ôn', needReview, Colors.orange),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startStudySession,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Học Bây giờ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmap(DateTime start, DateTime end) {
    return DueHeatMap(
      key: _heatmapKey,
      start: start,
      end: end,
      deckId: widget.deck.id,
    );
  }

  Widget _buildLearningMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê học tập',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Daily average',
                  '$_dailyAverage cards',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Days learned',
                  '${_daysLearnedPercent.toStringAsFixed(0)}%',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Longest streak',
                  '$_longestStreak days',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Current streak',
                  '$_currentStreak day',
                  Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
