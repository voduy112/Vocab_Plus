import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/models/vocabulary.dart';
import '../../../../core/services/database_service.dart';

class BasisCardSession extends StatefulWidget {
  final Vocabulary vocabulary;
  final Map<SrsChoice, String> labels;
  final Function(SrsChoice) onChoiceSelected;
  final Function(bool)? onAnswerShown;
  final Color? accentColor;

  const BasisCardSession({
    super.key,
    required this.vocabulary,
    required this.labels,
    required this.onChoiceSelected,
    this.onAnswerShown,
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
      duration: const Duration(milliseconds: 800),
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

  String _getFieldLabel(String key) {
    switch (key) {
      case 'pronunciation':
        return 'Phiên âm';
      case 'example':
        return 'Ví dụ';
      case 'translation':
        return 'Bản dịch ví dụ';
      default:
        return key;
    }
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
      widget.onAnswerShown?.call(true);
    } else {
      setState(() => _isShowingAnswer = false);
      _animationController.reverse();
      widget.onAnswerShown?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showAnswer,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isFlipped = _animation.value >= 0.5;
          final flipValue = _animation.value;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(flipValue * 3.14159),
            child: isFlipped
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildAnswer(),
                  )
                : _buildQuestion(),
          );
        },
      ),
    );
  }

  Widget _buildQuestion() {
    return _buildCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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

          // Từ vựng chính
          Text(
            widget.vocabulary.front,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          // Dynamic front fields
          if (widget.vocabulary.frontExtra != null &&
              widget.vocabulary.frontExtra!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...widget.vocabulary.frontExtra!.entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_getFieldLabel(e.key)}: ${e.value}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )),
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

          // Nghĩa chính
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.vocabulary.back,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Dynamic back fields
          if (widget.vocabulary.backExtra != null &&
              widget.vocabulary.backExtra!.isNotEmpty) ...[
            ...widget.vocabulary.backExtra!.entries.map((e) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
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
                      Text(
                        '${_getFieldLabel(e.key)}:',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
          ],

          const Spacer(),
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
