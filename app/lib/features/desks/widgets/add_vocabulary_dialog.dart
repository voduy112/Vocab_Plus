import 'package:flutter/material.dart';
import '../../../core/models/vocabulary.dart';
import 'card_forms/basis_card_form.dart';
import 'card_forms/reverse_card_form.dart';
import 'card_forms/typing_card_form.dart';

class AddVocabularyDialog extends StatefulWidget {
  final int deskId;
  final Vocabulary? vocabulary;

  const AddVocabularyDialog({
    super.key,
    required this.deskId,
    this.vocabulary,
  });

  @override
  State<AddVocabularyDialog> createState() => _AddVocabularyDialogState();
}

class _AddVocabularyDialogState extends State<AddVocabularyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _exampleController = TextEditingController();
  final _translationController = TextEditingController();
  final _hintTextController = TextEditingController();
  final _optAController = TextEditingController();
  final _optBController = TextEditingController();
  final _optCController = TextEditingController();
  final _optDController = TextEditingController();
  bool _isEditing = false;
  CardType _selectedCardType = CardType.basis;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vocabulary != null;
    if (_isEditing) {
      final vocab = widget.vocabulary!;
      _frontController.text = vocab.word;
      _backController.text = vocab.meaning;
      _pronunciationController.text = vocab.pronunciation ?? '';
      _exampleController.text = vocab.example ?? '';
      _translationController.text = vocab.translation ?? '';
      _hintTextController.text = vocab.hintText ?? '';
      _selectedCardType = vocab.cardType;
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _pronunciationController.dispose();
    _exampleController.dispose();
    _translationController.dispose();
    _hintTextController.dispose();
    _optAController.dispose();
    _optBController.dispose();
    _optCController.dispose();
    _optDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Chỉnh sửa từ vựng' : 'Thêm từ vựng mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<CardType>(
                value: _selectedCardType,
                decoration: const InputDecoration(
                  labelText: 'Loại thẻ',
                  border: OutlineInputBorder(),
                ),
                items: CardType.values
                    .map((e) => DropdownMenuItem<CardType>(
                          value: e,
                          child: Text(
                            e.toString().split('.').last,
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCardType = val);
                },
              ),
              const SizedBox(height: 16),
              _buildFormByType(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final now = DateTime.now();
              final vocabulary = Vocabulary(
                id: _isEditing ? widget.vocabulary!.id : null,
                deskId: widget.deskId,
                word: _frontController.text.trim(),
                meaning: _backController.text.trim(),
                pronunciation: _pronunciationController.text.trim().isEmpty
                    ? null
                    : _pronunciationController.text.trim(),
                example: _exampleController.text.trim().isEmpty
                    ? null
                    : _exampleController.text.trim(),
                translation: _translationController.text.trim().isEmpty
                    ? null
                    : _translationController.text.trim(),
                hintText: _hintTextController.text.trim().isEmpty
                    ? null
                    : _hintTextController.text.trim(),
                masteryLevel: _isEditing ? widget.vocabulary!.masteryLevel : 0,
                reviewCount: _isEditing ? widget.vocabulary!.reviewCount : 0,
                lastReviewed:
                    _isEditing ? widget.vocabulary!.lastReviewed : null,
                nextReview: _isEditing ? widget.vocabulary!.nextReview : null,
                createdAt: _isEditing ? widget.vocabulary!.createdAt : now,
                updatedAt: now,
                cardType: _selectedCardType,
              );
              Navigator.of(context).pop(vocabulary);
            }
          },
          child: Text(_isEditing ? 'Cập nhật' : 'Thêm'),
        ),
      ],
    );
  }

  Widget _buildFormByType() {
    switch (_selectedCardType) {
      case CardType.basis:
        return BasisCardForm(
          frontController: _frontController,
          backController: _backController,
          pronunciationController: _pronunciationController,
          exampleController: _exampleController,
          translationController: _translationController,
        );
      case CardType.reverse:
        return ReverseCardForm(
          frontController: _frontController,
          backController: _backController,
        );
      case CardType.typing:
        return TypingCardForm(
          frontController: _frontController,
          backController: _backController,
          hintTextController: _hintTextController,
        );
    }
  }
}
