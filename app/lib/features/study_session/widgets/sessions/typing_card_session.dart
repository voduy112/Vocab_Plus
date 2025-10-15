import 'package:flutter/material.dart';
import '../../../../core/models/vocabulary.dart';
import '../../../../core/services/database_service.dart';
import '../choice_buttons.dart';

class TypingCardSession extends StatefulWidget {
  final Vocabulary vocabulary;
  final Map<SrsChoice, String> labels;
  final Function(SrsChoice) onChoiceSelected;
  final Color? accentColor;

  const TypingCardSession({
    super.key,
    required this.vocabulary,
    required this.labels,
    required this.onChoiceSelected,
    this.accentColor,
  });

  @override
  State<TypingCardSession> createState() => _TypingCardSessionState();
}

class _TypingCardSessionState extends State<TypingCardSession>
    with SingleTickerProviderStateMixin {
  late TextEditingController _answerController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isShowingResult = false;
  bool _isCorrect = false;
  String _userAnswer = '';

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _answerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TypingCardSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vocabulary.id != widget.vocabulary.id) {
      _resetSession();
    }
  }

  void _resetSession() {
    _answerController.clear();
    setState(() {
      _isShowingResult = false;
      _isCorrect = false;
      _userAnswer = '';
    });
    _animationController.reset();
  }

  void _checkAnswer() {
    if (_answerController.text.trim().isEmpty) return;

    setState(() {
      _userAnswer = _answerController.text.trim();
      _isCorrect =
          _userAnswer.toLowerCase() == widget.vocabulary.meaning.toLowerCase();
      _isShowingResult = true;
    });

    _animationController.forward();
  }

  void _showAnswer() {
    if (!_isShowingResult) {
      _checkAnswer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _isShowingResult ? _buildResult() : _buildQuestion();
      },
    );
  }

  Widget _buildQuestion() {
    return _buildCard(
      context,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon đặc trưng cho typing card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.keyboard,
              size: 48,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            widget.vocabulary.word,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          if (widget.vocabulary.pronunciation != null &&
              widget.vocabulary.pronunciation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.vocabulary.pronunciation!,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 32),

          // Ô nhập câu trả lời
          if (widget.vocabulary.hintText != null &&
              widget.vocabulary.hintText!.isNotEmpty) ...[
            Text(
              widget.vocabulary.hintText!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _answerController,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập nghĩa của từ...',
                hintStyle: const TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _checkAnswer(),
            ),
          ),

          const SizedBox(height: 24),

          // Nút kiểm tra
          ElevatedButton(
            onPressed: _showAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Kiểm tra',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return _buildCard(
      context,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon kết quả
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isCorrect
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isCorrect ? Icons.check_circle : Icons.cancel,
              size: 48,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          // Kết quả
          Text(
            _isCorrect ? 'Chính xác!' : 'Không đúng',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isCorrect ? Colors.green[300] : Colors.red[300],
            ),
          ),

          const SizedBox(height: 16),

          // Câu trả lời của người dùng
          if (!_isCorrect) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Text(
                'Bạn đã trả lời: $_userAnswer',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Đáp án đúng
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Text(
              'Đáp án đúng: ${widget.vocabulary.meaning}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Nút đánh giá
          ChoiceButtons(
            onChoiceSelected: (choice) => widget.onChoiceSelected(choice),
            labels: widget.labels,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        // Limit height to avoid keyboard overflow; card becomes scrollable if needed
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.accentColor != null
              ? [
                  widget.accentColor!,
                  widget.accentColor!.withOpacity(0.8),
                ]
              : [
                  Colors.orange[600]!,
                  Colors.orange[400]!,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}
