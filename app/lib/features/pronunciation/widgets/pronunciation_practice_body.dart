import 'package:flutter/material.dart';

import '../../../../core/models/vocabulary.dart';
import 'pronunciation_action_buttons.dart';
import 'pronunciation_confetti.dart';
import 'pronunciation_progress_header.dart';
import 'pronunciation_result_placeholder.dart';
import 'pronunciation_word_card.dart';

class PronunciationPracticeBody extends StatelessWidget {
  final Vocabulary vocabulary;
  final int currentExercise;
  final int totalExercises;
  final bool isHighScore;
  final bool isLowScore;
  final bool hasResult;
  final String statusMessage;
  final bool isRecording;
  final bool isEvaluating;
  final bool showConfetti;
  final bool isLoadingAudio;
  final VoidCallback onVoiceCoach;
  final VoidCallback onRepeat;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onShowDetails;

  const PronunciationPracticeBody({
    super.key,
    required this.vocabulary,
    required this.currentExercise,
    required this.totalExercises,
    required this.isHighScore,
    required this.isLowScore,
    required this.hasResult,
    required this.statusMessage,
    required this.isRecording,
    required this.isEvaluating,
    required this.showConfetti,
    required this.isLoadingAudio,
    required this.onVoiceCoach,
    required this.onRepeat,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PronunciationProgressHeader(
                  currentExercise: currentExercise,
                  totalExercises: totalExercises,
                ),
                const SizedBox(height: 16),
                PronunciationWordCard(
                  vocabulary: vocabulary,
                  isHighScore: isHighScore,
                  isLowScore: isLowScore,
                  hasResult: hasResult,
                  statusMessage: statusMessage,
                  onShowDetails: onShowDetails,
                ),
                const SizedBox(height: 24),
                PronunciationActionButtons(
                  onVoiceCoach: onVoiceCoach,
                  onRepeat: onRepeat,
                  onStartRecording: onStartRecording,
                  onStopRecording: onStopRecording,
                  isRecording: isRecording,
                  isEvaluating: isEvaluating,
                  isLoadingAudio: isLoadingAudio,
                ),
                const SizedBox(height: 24),
                if (hasResult)
                  Text(
                    'Nhấn "Xem chi tiết" để xem điểm và từng âm vị.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                  )
                else
                  const PronunciationResultPlaceholder(),
                const Spacer(),
              ],
            ),
          ),
          if (showConfetti) const PronunciationConfetti(),
        ],
      ),
    );
  }
}
