import 'package:flutter/material.dart';
import '../../../core/models/vocabulary.dart';

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
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _exampleController = TextEditingController();
  final _translationController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vocabulary != null;
    if (_isEditing) {
      final vocab = widget.vocabulary!;
      _wordController.text = vocab.word;
      _meaningController.text = vocab.meaning;
      _pronunciationController.text = vocab.pronunciation ?? '';
      _exampleController.text = vocab.example ?? '';
      _translationController.text = vocab.translation ?? '';
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _pronunciationController.dispose();
    _exampleController.dispose();
    _translationController.dispose();
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
              TextFormField(
                controller: _wordController,
                decoration: const InputDecoration(
                  labelText: 'Từ vựng *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập từ vựng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _meaningController,
                decoration: const InputDecoration(
                  labelText: 'Nghĩa *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập nghĩa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pronunciationController,
                decoration: const InputDecoration(
                  labelText: 'Phiên âm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _exampleController,
                decoration: const InputDecoration(
                  labelText: 'Ví dụ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _translationController,
                decoration: const InputDecoration(
                  labelText: 'Bản dịch ví dụ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
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
                word: _wordController.text.trim(),
                meaning: _meaningController.text.trim(),
                pronunciation: _pronunciationController.text.trim().isEmpty
                    ? null
                    : _pronunciationController.text.trim(),
                example: _exampleController.text.trim().isEmpty
                    ? null
                    : _exampleController.text.trim(),
                translation: _translationController.text.trim().isEmpty
                    ? null
                    : _translationController.text.trim(),
                masteryLevel: _isEditing ? widget.vocabulary!.masteryLevel : 0,
                reviewCount: _isEditing ? widget.vocabulary!.reviewCount : 0,
                lastReviewed:
                    _isEditing ? widget.vocabulary!.lastReviewed : null,
                nextReview: _isEditing ? widget.vocabulary!.nextReview : null,
                createdAt: _isEditing ? widget.vocabulary!.createdAt : now,
                updatedAt: now,
              );
              Navigator.of(context).pop(vocabulary);
            }
          },
          child: Text(_isEditing ? 'Cập nhật' : 'Thêm'),
        ),
      ],
    );
  }
}
