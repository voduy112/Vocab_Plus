import 'package:flutter/material.dart';
import '../../../../core/models/vocabulary.dart';
import '../../../../core/services/database_service.dart';
import '../choice_buttons.dart';

class ReverseCardSession extends StatefulWidget {
  final Vocabulary vocabulary;
  final Map<SrsChoice, String> labels;
  final Function(SrsChoice) onChoiceSelected;
  final Color? accentColor;

  const ReverseCardSession({
    super.key,
    required this.vocabulary,
    required this.labels,
    required this.onChoiceSelected,
    this.accentColor,
  });

  @override
  State<ReverseCardSession> createState() => _ReverseCardSessionState();
}

class _ReverseCardSessionState extends State<ReverseCardSession>
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
  void didUpdateWidget(ReverseCardSession oldWidget) {
    super.didUpdateWidget(oldWidget);
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
          // Icon đặc trưng cho reverse card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz,
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

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              'Nhấn để xem nghĩa',
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

  Widget _buildBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: _buildCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon đặc trưng cho reverse card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              widget.vocabulary.meaning,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

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
                  Colors.purple[600]!,
                  Colors.purple[400]!,
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
