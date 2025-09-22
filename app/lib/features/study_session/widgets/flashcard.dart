import 'package:flutter/material.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/services/database_service.dart';
import '../widgets/choice_buttons.dart';

class Flashcard extends StatefulWidget {
  final Vocabulary vocabulary;
  final Map<SrsChoice, String> labels;
  final Function(SrsChoice) onChoiceSelected;
  final Color? accentColor;

  const Flashcard({
    super.key,
    required this.vocabulary,
    required this.labels,
    required this.onChoiceSelected,
    this.accentColor,
  });

  @override
  State<Flashcard> createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

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
  void didUpdateWidget(Flashcard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset card to front when vocabulary changes
    if (oldWidget.vocabulary.id != widget.vocabulary.id) {
      _resetToFront();
    }
  }

  void _resetToFront() {
    _animationController.reset();
  }

  void _flipCard() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isShowingFront = _animation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_animation.value * 3.14159),
            child: isShowingFront ? _buildFront() : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return _buildCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          const SizedBox(height: 24),
          const Text(
            'Nhấn để xem nghĩa',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vocabulary.meaning,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (widget.vocabulary.example != null &&
                widget.vocabulary.example!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.vocabulary.example!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const Spacer(),
            ChoiceButtons(
              onChoiceSelected: (choice) => widget.onChoiceSelected(choice),
              labels: widget.labels,
            ),
          ],
        ),
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
