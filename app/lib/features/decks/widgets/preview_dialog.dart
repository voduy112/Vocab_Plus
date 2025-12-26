import 'package:flutter/material.dart';
import '../../../core/models/vocabulary.dart';
import '../../study_session/services/study_session_service.dart';
import '../../study_session/widgets/sessions/basis_card_session.dart';
import '../../study_session/widgets/sessions/reverse_card_session.dart';
import '../../study_session/widgets/sessions/typing_card_session.dart';

Future<void> showVocabularyPreviewDialog({
  required BuildContext context,
  required Vocabulary vocabulary,
  required CardType cardType,
  required Color accent,
}) async {
  final labels = StudySessionService().previewChoiceLabels(vocabulary);

  Widget sessionWidget;
  switch (cardType) {
    case CardType.basis:
      sessionWidget = BasisCardSession(
        vocabulary: vocabulary,
        labels: labels,
        onChoiceSelected: (_) {},
        onAnswerShown: (_) {},
        accentColor: accent,
      );
      break;
    case CardType.reverse:
      sessionWidget = ReverseCardSession(
        vocabulary: vocabulary,
        labels: labels,
        onChoiceSelected: (_) {},
        onAnswerShown: (_) {},
        accentColor: accent,
      );
      break;
    case CardType.typing:
      sessionWidget = TypingCardSession(
        vocabulary: vocabulary,
        labels: labels,
        onChoiceSelected: (_) {},
        onAnswerShown: (_) {},
        accentColor: accent,
      );
      break;
  }

  await showDialog(
    context: context,
    builder: (ctx) => LayoutBuilder(
      builder: (context, constraints) {
        // Giới hạn width tối đa và đảm bảo width finite
        final maxDialogWidth =
            constraints.maxWidth > 700 ? 700.0 : constraints.maxWidth * 0.9;

        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cardType == CardType.basis
                      ? 'Basis'
                      : cardType == CardType.reverse
                          ? 'Reverse'
                          : 'Typing',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: maxDialogWidth,
            child: sessionWidget,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    ),
  );
}
