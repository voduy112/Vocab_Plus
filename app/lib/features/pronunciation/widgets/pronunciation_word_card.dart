import 'package:flutter/material.dart';

import '../../../core/models/vocabulary.dart';

class PronunciationWordCard extends StatelessWidget {
  final Vocabulary vocabulary;
  final bool isHighScore;
  final bool isLowScore;
  final bool hasResult;
  final String statusMessage;
  final VoidCallback onShowDetails;

  const PronunciationWordCard({
    super.key,
    required this.vocabulary,
    required this.isHighScore,
    required this.isLowScore,
    required this.hasResult,
    required this.statusMessage,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextStyle? secondaryStyle = theme.textTheme.titleMedium?.copyWith(
      color: isHighScore || isLowScore
          ? Colors.white.withOpacity(0.85)
          : theme.colorScheme.onSurface.withOpacity(0.6),
    );

    return Card(
      elevation: 8,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: _cardGradient,
          boxShadow: [
            if (isHighScore)
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            if (isLowScore)
              BoxShadow(
                color: Colors.red.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          children: [
            GradientWordText(
              text: vocabulary.front,
              solidColor: (isHighScore || isLowScore) ? Colors.white : null,
            ),
            const SizedBox(height: 24),
            Text(
              statusMessage,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: (isHighScore || isLowScore) ? Colors.white : null,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasResult) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onShowDetails,
                icon: const Icon(Icons.insights_rounded),
                label: const Text('Xem chi tiết'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isHighScore || isLowScore
                      ? Colors.white
                      : theme.colorScheme.primary,
                  side: BorderSide(
                    color: isHighScore || isLowScore
                        ? Colors.white70
                        : theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  backgroundColor: (isHighScore || isLowScore)
                      ? Colors.white.withOpacity(0.15)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  LinearGradient get _cardGradient {
    if (isHighScore) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green.shade500,
          Colors.green.shade300,
        ],
      );
    }
    if (isLowScore) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.red.shade500,
          Colors.red.shade300,
        ],
      );
    }
    return const LinearGradient(
      colors: [
        Colors.white,
        Colors.white,
      ],
    );
  }
}

class GradientWordText extends StatelessWidget {
  final String text;
  final List<Color>? colorsOverride;
  final Color? solidColor;

  const GradientWordText({
    super.key,
    required this.text,
    this.colorsOverride,
    this.solidColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: solidColor ?? Colors.white,
      letterSpacing: 1,
    );

    if (solidColor != null) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: textStyle,
      );
    }

    final colors = colorsOverride ??
        const [
          Color(0xFF34C8F5),
          Color(0xFF8B54FF),
          Color(0xFFFF7E67),
        ];

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: textStyle,
      ),
    );
  }
}
