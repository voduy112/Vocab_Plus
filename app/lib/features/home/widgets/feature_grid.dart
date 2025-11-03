import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Widget Grid chức năng
class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2 cards nhỏ ở trên
        Row(
          children: [
            // Card 1: Tìm kiếm từ
            Expanded(
              child: _FeatureCard(
                icon: Icons.search_rounded,
                label: 'Tìm kiếm từ',
                bgColor: Colors.blue.shade50,
                iconColor: Colors.blue.shade700,
                onTap: () {
                  context.go('/tabs/search');
                },
              ),
            ),
            const SizedBox(width: 16),
            // Card 2: Quản lý bộ từ
            Expanded(
              child: _FeatureCard(
                icon: Icons.folder_rounded,
                label: 'Quản lý bộ từ',
                bgColor: Colors.purple.shade50,
                iconColor: Colors.purple.shade700,
                onTap: () {
                  context.go('/tabs/desks');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Card lớn: Đánh giá phát âm người đọc
        _FeatureCardLarge(
          title: 'Đánh giá phát âm người đọc',
          buttonLabel: 'Bắt đầu',
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đánh giá phát âm')),
            );
          },
        ),
      ],
    );
  }
}

// Widget Card nhỏ
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            elevation: _isPressed ? 2 : 8,
            borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) {
                setState(() => _isPressed = true);
                _controller.forward();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _controller.reverse();
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _controller.reverse();
              },
              borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                offset: const Offset(0, 2),
                      spreadRadius: -2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                      widget.icon,
                size: 32,
                      color: widget.iconColor,
              ),
              const Spacer(),
              Text(
                      widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
          ),
        );
      },
    );
  }
}

// Widget Card lớn với gradient
class _FeatureCardLarge extends StatefulWidget {
  final String title;
  final String buttonLabel;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FeatureCardLarge({
    required this.title,
    required this.buttonLabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_FeatureCardLarge> createState() => _FeatureCardLargeState();
}

class _FeatureCardLargeState extends State<_FeatureCardLarge>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            elevation: _isPressed ? 4 : 12,
            borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) {
                setState(() => _isPressed = true);
                _controller.forward();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _controller.reverse();
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _controller.reverse();
              },
              borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                offset: const Offset(0, 4),
                      spreadRadius: -4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Phần text và button bên trái
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                            widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                            onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                              elevation: 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                                  widget.buttonLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.mic, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Icon microphone bên phải
              Icon(
                Icons.mic_outlined,
                size: 64,
                color: Colors.white.withOpacity(0.9),
              ),
            ],
          ),
        ),
      ),
          ),
        );
      },
    );
  }
}
