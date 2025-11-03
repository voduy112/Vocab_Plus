import 'package:flutter/material.dart';
import '../../../core/models/vocabulary.dart';
import 'card_forms/basis_card_form.dart';
import 'card_forms/reverse_card_form.dart';
import 'card_forms/typing_card_form.dart';
import 'card_forms/dynamic_card_form.dart';

class VocabularyFormCard extends StatelessWidget {
  final CardType cardType;
  final TextEditingController frontController;
  final TextEditingController backController;
  final TextEditingController hintTextController;
  final Map<String, String>? initialFrontExtra;
  final Map<String, String>? initialBackExtra;
  final ValueChanged<DynamicFormState> onChanged;

  const VocabularyFormCard({
    super.key,
    required this.cardType,
    required this.frontController,
    required this.backController,
    required this.hintTextController,
    required this.initialFrontExtra,
    required this.initialBackExtra,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Thông tin từ vựng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildFormByType(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormByType() {
    switch (cardType) {
      case CardType.basis:
        return BasisCardForm(
          frontController: frontController,
          backController: backController,
          pronunciationController: TextEditingController(),
          exampleController: TextEditingController(),
          translationController: TextEditingController(),
          initialFrontExtra: initialFrontExtra,
          initialBackExtra: initialBackExtra,
          onChanged: onChanged,
        );
      case CardType.reverse:
        return ReverseCardForm(
          frontController: frontController,
          backController: backController,
          initialFrontExtra: initialFrontExtra,
          initialBackExtra: initialBackExtra,
          onChanged: onChanged,
        );
      case CardType.typing:
        return TypingCardForm(
          frontController: frontController,
          backController: backController,
          hintTextController: hintTextController,
          initialFrontExtra: initialFrontExtra,
          initialBackExtra: initialBackExtra,
          onChanged: onChanged,
        );
    }
  }
}
