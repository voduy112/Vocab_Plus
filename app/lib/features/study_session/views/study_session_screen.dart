import 'package:flutter/material.dart';
import '../../../core/models/deck.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/models/study_session.dart';
import '../../../core/models/srs_choice.dart';
import '../../decks/services/deck_service.dart';
import '../../decks/services/vocabulary_service.dart';
import '../services/study_session_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/sessions/basis_card_session.dart';
import '../widgets/sessions/reverse_card_session.dart';
import '../widgets/sessions/typing_card_session.dart';
import '../widgets/stats_card.dart';
import '../widgets/choice_buttons.dart';

class StudySessionScreen extends StatefulWidget {
  final Deck deck;
  const StudySessionScreen({super.key, required this.deck});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final DeckService _deckService = DeckService();
  final VocabularyService _vocabService = VocabularyService();
  final StudySessionService _studyService = StudySessionService();
  List<Vocabulary> _queue = [];
  int _index = 0;
  bool _isLoading = true;
  Map<SrsChoice, String> _labels = const {};
  int _totalVocabularies = 0;
  int _reviewCount = 0;
  int _minuteLearningCount = 0;
  int _newCount = 0;
  bool _isShowingResult = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final items =
          await _vocabService.getVocabulariesForStudyByDeck(widget.deck.id!);

      // Tính toán thống kê
      final deskStats = await _deckService.getDeckStats(widget.deck.id!);
      final totalCount = deskStats['total'] ?? 0;
      final reviewCount = deskStats['needReview'] ?? 0; // Số từ tới hạn cần ôn
      final minuteLearning =
          await _vocabService.countMinuteLearningByDeck(widget.deck.id!);
      final newCount = await _vocabService.countNewByDeck(widget.deck.id!);

      setState(() {
        _queue = items;
        _index = 0;
        _isLoading = false;
        _isShowingResult = false;
        _totalVocabularies = totalCount;
        _reviewCount = reviewCount;
        _minuteLearningCount = minuteLearning;
        _newCount = newCount;
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
    final labels = _studyService.previewChoiceLabels(v);
    setState(() => _labels = labels);
  }

  void _setIsShowingResultSafely(bool isShowing) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isShowingResult = isShowing);
    });
  }

  Future<void> _updateStats() async {
    try {
      final deskStats = await _deckService.getDeckStats(widget.deck.id!);
      final totalCount = deskStats['total'] ?? 0;
      final reviewCount = deskStats['needReview'] ?? 0; // Số từ tới hạn cần ôn
      final minuteLearning =
          await _vocabService.countMinuteLearningByDeck(widget.deck.id!);
      final newCount = await _vocabService.countNewByDeck(widget.deck.id!);

      if (mounted) {
        setState(() {
          _totalVocabularies = totalCount;
          _reviewCount = reviewCount;
          _minuteLearningCount = minuteLearning;
          _newCount = newCount;
        });
      }
    } catch (e) {
      // Không hiển thị lỗi cho việc cập nhật thống kê
      print('Lỗi cập nhật thống kê: $e');
    }
  }

  Future<void> _choose(SrsChoice choice) async {
    if (_queue.isEmpty || _index >= _queue.length) return;
    final v = _queue[_index];
    try {
      // Luôn lật về mặt trước trước khi xử lý lựa chọn, đặc biệt khi là thẻ cuối
      print('isShowingResult: $_isShowingResult');
      print('choice: $choice');
      print('v: $v');
      if (_isShowingResult) {
        setState(() => _isShowingResult = false);
        print('isShowingResult: $_isShowingResult');
      }
      final bool wasNew = (v.srsRepetitions == 0);
      final result = await _studyService.reviewWithChoice(
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

      if (wasNew) {
        setState(() {
          _newCount = _newCount > 0 ? _newCount - 1 : 0;
        });
      }

      if (!dueIsMinutes || updatedSrsType == 2 || choice == SrsChoice.easy) {
        // Due theo ngày hoặc đã vào review: loại khỏi phiên
        _queue.removeAt(_index);
        if (_index >= _queue.length) _index = 0;
        // Cập nhật reviewCount ngay lập tức khi từ được loại khỏi queue
        setState(() {
          _reviewCount = _reviewCount > 0 ? _reviewCount - 1 : 0;
        });
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
        final latest = await _studyService.getVocabularyById(currentFrontId);
        if (!mounted) return;
        setState(() {
          _labels = _studyService.previewChoiceLabels(latest ?? _queue[_index]);
        });
      }

      // Reset trạng thái hiển thị answer
      setState(() => _isShowingResult = false);

      // Cập nhật thống kê ngay lập tức sau khi học
      await _updateStats();
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
    final color = Theme.of(context).colorScheme.primary;
    return WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(true);
          return false;
        },
        child: Scaffold(
          appBar: _isLoading || _queue.isEmpty
              ? AppBar(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  title: Text(widget.deck.name),
                )
              : AppBar(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  title: Text(widget.deck.name),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(50),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: StatsCard(
                        reviewCount: _reviewCount,
                        minuteLearningCount: _minuteLearningCount,
                        newCount: _newCount,
                      ),
                    ),
                  ),
                ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _queue.isEmpty
                  ? const EmptyState(
                      message: 'Hết từ để học/ôn!',
                      icon: Icons.celebration,
                    )
                  : _buildCard(color),
        ));
  }

  Widget _buildCard(Color color) {
    final v = _queue[_index];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildSessionByCardType(v, color),
          ),
          const SizedBox(height: 16),
          // Choice buttons luôn hiển thị bên ngoài card
          ChoiceButtons(
            onChoiceSelected: _choose,
            labels: _labels,
            isVisible: _isShowingResult,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionByCardType(Vocabulary vocabulary, Color color) {
    switch (vocabulary.cardType) {
      case CardType.basis:
        return BasisCardSession(
          vocabulary: vocabulary,
          labels: _labels,
          onChoiceSelected: _choose,
          onAnswerShown: (isShowing) => _setIsShowingResultSafely(isShowing),
          accentColor: color,
          isParentShowingResult: _isShowingResult,
        );
      case CardType.reverse:
        return ReverseCardSession(
          vocabulary: vocabulary,
          labels: _labels,
          onChoiceSelected: _choose,
          onAnswerShown: (isShowing) => _setIsShowingResultSafely(isShowing),
          accentColor: color,
          isParentShowingResult: _isShowingResult,
        );
      case CardType.typing:
        return TypingCardSession(
          vocabulary: vocabulary,
          labels: _labels,
          onChoiceSelected: _choose,
          onAnswerShown: (isShowing) => _setIsShowingResultSafely(isShowing),
          accentColor: color,
          isParentShowingResult: _isShowingResult,
        );
    }
  }
}
