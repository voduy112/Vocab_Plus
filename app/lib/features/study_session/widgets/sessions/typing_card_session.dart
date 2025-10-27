import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/models/vocabulary.dart';
import '../../../../core/services/database_service.dart';

class TypingCardSession extends StatefulWidget {
  final Vocabulary vocabulary;
  final Map<SrsChoice, String> labels;
  final Function(SrsChoice) onChoiceSelected;
  final Function(bool)? onAnswerShown;
  final Color? accentColor;

  const TypingCardSession({
    super.key,
    required this.vocabulary,
    required this.labels,
    required this.onChoiceSelected,
    this.onAnswerShown,
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
    widget.onAnswerShown?.call(false);
  }

  void _checkAnswer() {
    if (_answerController.text.trim().isEmpty) return;

    setState(() {
      _userAnswer = _answerController.text.trim();
      _isCorrect =
          _userAnswer.toLowerCase() == widget.vocabulary.back.toLowerCase();
      _isShowingResult = true;
    });

    _animationController.forward();
    widget.onAnswerShown?.call(true);
  }

  void _showAnswer() {
    if (!_isShowingResult) {
      _checkAnswer();
    }
  }

  bool _hasOtherFields(Map<String, String> extra) {
    return extra.entries.any((entry) =>
        entry.key != 'pronunciation' &&
        entry.key != 'hint_text' &&
        entry.value.trim().isNotEmpty);
  }

  String _getFieldLabel(String key) {
    switch (key) {
      case 'pronunciation':
        return 'Phiên âm';
      case 'example':
        return 'Ví dụ';
      case 'translation':
        return 'Bản dịch ví dụ';
      case 'hint_text':
        return 'Gợi ý';
      default:
        return key;
    }
  }

  IconData _getFieldIcon(String key) {
    switch (key) {
      case 'pronunciation':
        return Icons.record_voice_over;
      case 'example':
        return Icons.format_quote;
      case 'translation':
        return Icons.translate;
      case 'hint_text':
        return Icons.lightbulb_outline;
      default:
        return Icons.text_fields;
    }
  }

  Widget _buildFieldItem(String key, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getFieldIcon(key),
            size: 18,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFieldLabel(key),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          // Hint text ở đầu trang
          if (widget.vocabulary.backExtra != null &&
              widget.vocabulary.backExtra!.containsKey('hint_text') &&
              widget.vocabulary.backExtra!['hint_text']!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.vocabulary.backExtra!['hint_text']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Ảnh mặt trước (nếu có)
          if (widget.vocabulary.imageUrl != null ||
              widget.vocabulary.imagePath != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.vocabulary.imagePath != null
                    ? Image.file(
                        File(widget.vocabulary.imagePath!),
                        height: 120,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: 200,
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
                      )
                    : Image.network(
                        widget.vocabulary.imageUrl!,
                        height: 120,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: 200,
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
                      ),
              ),
            ),

          // Main content
          Text(
            widget.vocabulary.front,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          // Pronunciation directly under main content
          if (widget.vocabulary.frontExtra != null &&
              widget.vocabulary.frontExtra!.containsKey('pronunciation') &&
              widget.vocabulary.frontExtra!['pronunciation']!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.record_voice_over,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.vocabulary.frontExtra!['pronunciation']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Other dynamic fields section
          if (widget.vocabulary.frontExtra != null &&
              _hasOtherFields(widget.vocabulary.frontExtra!)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin bổ sung',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.vocabulary.frontExtra!.entries
                      .where((entry) =>
                          entry.key != 'pronunciation' &&
                          entry.key != 'hint_text' &&
                          entry.value.trim().isNotEmpty)
                      .map((entry) => _buildFieldItem(entry.key, entry.value)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Ô nhập câu trả lời
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Ảnh mặt sau (nếu có)
          if (widget.vocabulary.backImageUrl != null ||
              widget.vocabulary.backImagePath != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.vocabulary.backImagePath != null
                    ? Image.file(
                        File(widget.vocabulary.backImagePath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
                      )
                    : Image.network(
                        widget.vocabulary.backImageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
                      ),
              ),
            ),

          // Câu trả lời của người dùng với so sánh từng ký tự
          if (!_isCorrect) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bạn đã trả lời:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCharacterComparison(),
                ],
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
              'Đáp án đúng: ${widget.vocabulary.back}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pronunciation ở mặt sau
          if (widget.vocabulary.backExtra != null &&
              widget.vocabulary.backExtra!.containsKey('pronunciation') &&
              widget.vocabulary.backExtra!['pronunciation']!
                  .trim()
                  .isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.record_voice_over,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.vocabulary.backExtra!['pronunciation']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Translation ở mặt sau
          if (widget.vocabulary.backExtra != null &&
              widget.vocabulary.backExtra!.containsKey('translation') &&
              widget.vocabulary.backExtra!['translation']!
                  .trim()
                  .isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.translate,
                    size: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bản dịch ví dụ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.vocabulary.backExtra!['translation']!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 4),

          // Hiển thị các trường động từ backExtra
          if (widget.vocabulary.backExtra != null &&
              widget.vocabulary.backExtra!.entries.any((entry) =>
                  entry.key != 'hint_text' &&
                  entry.key != 'pronunciation' &&
                  entry.key != 'translation' &&
                  entry.value.trim().isNotEmpty)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin bổ sung',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.vocabulary.backExtra!.entries
                      .where((entry) =>
                          entry.key != 'hint_text' &&
                          entry.key != 'pronunciation' &&
                          entry.key != 'translation' &&
                          entry.value.trim().isNotEmpty)
                      .map((entry) => _buildFieldItem(entry.key, entry.value)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
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

  Widget _buildCharacterComparison() {
    final correctAnswer = widget.vocabulary.back.toLowerCase();
    final userAnswer = _userAnswer.toLowerCase();

    // Nếu đúng hoàn toàn, hiển thị màu xanh lá
    if (userAnswer == correctAnswer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.withOpacity(0.6)),
        ),
        child: Text(
          _userAnswer,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // So sánh từng ký tự
    final List<Widget> characterWidgets = [];
    final maxLength = userAnswer.length > correctAnswer.length
        ? userAnswer.length
        : correctAnswer.length;

    for (int i = 0; i < maxLength; i++) {
      final userChar = i < userAnswer.length ? userAnswer[i] : '';
      final correctChar = i < correctAnswer.length ? correctAnswer[i] : '';

      Color charColor;
      String displayChar;

      if (userChar == correctChar && userChar.isNotEmpty) {
        charColor = Colors.white; // Đúng: màu trắng
        displayChar = userChar;
      } else if (userChar.isEmpty) {
        charColor = Colors.grey; // Chưa nhập: màu xám
        displayChar = correctChar; // Hiển thị ký tự thật của đáp án
      } else {
        charColor = Colors.red; // Sai: màu đỏ
        displayChar = userChar;
      }

      characterWidgets.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: charColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: charColor.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Text(
            displayChar,
            style: TextStyle(
              fontSize: 16,
              color: charColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Wrap(
      children: characterWidgets,
    );
  }
}
