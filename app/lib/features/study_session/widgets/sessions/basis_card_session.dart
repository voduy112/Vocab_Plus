import 'package:flutter/material.dart';
import '../../../../core/models/vocabulary.dart';
import '../../../../core/services/database_service.dart';
import '../choice_buttons.dart';

class BasisCardSession extends StatefulWidget {
  final Vocabulary vocabulary;
  final Map<SrsChoice, String> labels;
  final Function(SrsChoice) onChoiceSelected;
  final Color? accentColor;

  const BasisCardSession({
    super.key,
    required this.vocabulary,
    required this.labels,
    required this.onChoiceSelected,
    this.accentColor,
  });

  @override
  State<BasisCardSession> createState() => _BasisCardSessionState();
}

class _BasisCardSessionState extends State<BasisCardSession>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isShowingAnswer = false;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BasisCardSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vocabulary.id != widget.vocabulary.id) {
      _resetToQuestion();
    }
  }

  void _resetToQuestion() {
    _animationController.reset();
    setState(() => _isShowingAnswer = false);
  }

  void _showAnswer() {
    if (!_isShowingAnswer) {
      setState(() => _isShowingAnswer = true);
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isShowingAnswer ? null : _showAnswer,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return _isShowingAnswer ? _buildAnswer() : _buildQuestion();
        },
      ),
    );
  }

  Widget _buildQuestion() {
    return _buildCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Từ vựng chính
          Text(
            widget.vocabulary.word,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          // Phiên âm
          if (widget.vocabulary.pronunciation != null &&
              widget.vocabulary.pronunciation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.vocabulary.pronunciation!,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Hướng dẫn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              'Nhấn để xem nghĩa và ví dụ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswer() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nghĩa chính
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.vocabulary.meaning,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Ví dụ
          if (widget.vocabulary.example != null &&
              widget.vocabulary.example!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ví dụ:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.vocabulary.example!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (widget.vocabulary.translation != null &&
                      widget.vocabulary.translation!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.vocabulary.translation!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Spacer(),

          // Nút đánh giá
          ChoiceButtons(
            onChoiceSelected: (choice) => widget.onChoiceSelected(choice),
            labels: widget.labels,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 400,
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
                  Colors.blue[600]!,
                  Colors.blue[400]!,
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
        child: child,
      ),
    );
  }
}
