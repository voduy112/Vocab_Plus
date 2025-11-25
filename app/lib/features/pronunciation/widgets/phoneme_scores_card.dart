import 'package:flutter/material.dart';

import '../../../core/models/pronunciation_result.dart';

class PhonemeScoresCard extends StatelessWidget {
  final PronunciationResult result;
  final int currentExerciseIndex;
  final bool Function(double score) isPhonemeCorrect;

  const PhonemeScoresCard({
    super.key,
    required this.result,
    required this.currentExerciseIndex,
    required this.isPhonemeCorrect,
  });

  @override
  Widget build(BuildContext context) {
    if (result.words.isEmpty) {
      return _emptyCard(context);
    }

    final targetIndex =
        currentExerciseIndex.clamp(0, result.words.length - 1).toInt();
    final phonemes =
        result.phonemes.where((p) => p.wordIndex == targetIndex).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phoneme scores',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            phonemes.isEmpty
                ? Text(
                    'Không có dữ liệu phoneme cho từ này.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < phonemes.length; i++) ...[
                          PronunciationPhonemeChip(
                            phoneme: phonemes[i],
                            isCorrect: isPhonemeCorrect(phonemes[i].score),
                            wasPronounced: phonemes[i].score > 0,
                          ),
                          if (i != phonemes.length - 1)
                            const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Không có dữ liệu phoneme cho từ này.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class PronunciationPhonemeChip extends StatelessWidget {
  final PhonemeResult phoneme;
  final bool isCorrect;
  final bool wasPronounced;

  const PronunciationPhonemeChip({
    super.key,
    required this.phoneme,
    required this.isCorrect,
    required this.wasPronounced,
  });

  Color get _backgroundColor {
    if (!wasPronounced) return Colors.grey.shade400;
    if (isCorrect) return const Color(0xFF2DB098);
    return const Color(0xFFE8515B);
  }

  Color get _textColor {
    if (!wasPronounced) return Colors.grey.shade900;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _backgroundColor,
      ),
      child: Text(
        phoneme.p,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}
