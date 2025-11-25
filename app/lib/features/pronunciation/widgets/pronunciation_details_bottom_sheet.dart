import 'package:flutter/material.dart';
import '../../../core/models/pronunciation_result.dart';
import 'overall_score_card.dart';
import 'phoneme_scores_card.dart';

class PronunciationDetailsBottomSheet {
  static void show(
    BuildContext context, {
    required PronunciationResult result,
    required int currentExerciseIndex,
    required Color Function(double score) colorResolver,
    required bool Function(double score) isPhonemeCorrect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.95,
          initialChildSize: 0.85,
          minChildSize: 0.6,
          builder: (_, controller) {
            return _PronunciationDetailsContent(
              result: result,
              currentExerciseIndex: currentExerciseIndex,
              colorResolver: colorResolver,
              isPhonemeCorrect: isPhonemeCorrect,
              scrollController: controller,
            );
          },
        );
      },
    );
  }
}

class _PronunciationDetailsContent extends StatelessWidget {
  final PronunciationResult result;
  final int currentExerciseIndex;
  final Color Function(double score) colorResolver;
  final bool Function(double score) isPhonemeCorrect;
  final ScrollController scrollController;

  const _PronunciationDetailsContent({
    required this.result,
    required this.currentExerciseIndex,
    required this.colorResolver,
    required this.isPhonemeCorrect,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Chi tiết kết quả',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OverallScoreCard(
              result: result,
              colorResolver: colorResolver,
            ),
            const SizedBox(height: 16),
            PhonemeScoresCard(
              result: result,
              currentExerciseIndex: currentExerciseIndex,
              isPhonemeCorrect: isPhonemeCorrect,
            ),
          ],
        ),
      ),
    );
  }
}
