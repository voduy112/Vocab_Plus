import 'package:flutter/material.dart';
import 'dynamic_card_form.dart';

class TypingCardForm extends StatefulWidget {
  final TextEditingController frontController;
  final TextEditingController backController;
  final TextEditingController hintTextController;
  final Function(DynamicFormState) onChanged;
  final Map<String, String>? initialFrontExtra;
  final Map<String, String>? initialBackExtra;

  const TypingCardForm({
    super.key,
    required this.frontController,
    required this.backController,
    required this.hintTextController,
    required this.onChanged,
    this.initialFrontExtra,
    this.initialBackExtra,
  });

  @override
  State<TypingCardForm> createState() => _TypingCardFormState();
}

class _TypingCardFormState extends State<TypingCardForm> {
  late List<DynamicField> _availableFields;
  late List<DynamicField> _currentFrontFields;
  late List<DynamicField> _currentBackFields;

  @override
  void initState() {
    super.initState();
    _availableFields = [
      DynamicField(
        id: 'pronunciation',
        label: 'Phiên âm',
        hint: 'Nhập phiên âm của từ',
        icon: Icons.record_voice_over,
      ),
      DynamicField(
        id: 'example',
        label: 'Ví dụ',
        hint: 'Nhập câu ví dụ',
        icon: Icons.format_quote,
        maxLines: 2,
      ),
      DynamicField(
        id: 'translation',
        label: 'Bản dịch ví dụ',
        hint: 'Nhập bản dịch của ví dụ',
        icon: Icons.translate,
        maxLines: 2,
      ),
      DynamicField(
        id: 'hint_text',
        label: 'Gợi ý',
        hint: 'Nhập gợi ý cho người học',
        icon: Icons.lightbulb_outline,
        maxLines: 2,
      ),
    ];

    // Initialize fields based on existing data
    _currentFrontFields = [];
    _currentBackFields = [];

    if (widget.initialFrontExtra != null) {
      for (final entry in widget.initialFrontExtra!.entries) {
        final field = _availableFields.firstWhere((f) => f.id == entry.key);
        _currentFrontFields.add(field);
      }
    }

    if (widget.initialBackExtra != null) {
      for (final entry in widget.initialBackExtra!.entries) {
        final field = _availableFields.firstWhere((f) => f.id == entry.key);
        _currentBackFields.add(field);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hint text field
        TextFormField(
          controller: widget.hintTextController,
          decoration: InputDecoration(
            labelText: 'Gợi ý (tuỳ chọn)',
            hintText: 'Nhập gợi ý để giúp người học',
            prefixIcon: const Icon(Icons.lightbulb_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            helperText: 'Gợi ý sẽ hiển thị khi người học đang gõ câu trả lời',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Dynamic fields
        DynamicCardForm(
          frontController: widget.frontController,
          backController: widget.backController,
          availableFields: _availableFields,
          initialFrontFields: _currentFrontFields,
          initialBackFields: _currentBackFields,
          initialFrontValues: widget.initialFrontExtra,
          initialBackValues: widget.initialBackExtra,
          onChanged: (state) {
            setState(() {
              _currentFrontFields = state.frontFields;
              _currentBackFields = state.backFields;
            });

            // Add hint_text to backValues if it has content
            final updatedState = DynamicFormState(
              frontFields: state.frontFields,
              backFields: state.backFields,
              frontValues: state.frontValues,
              backValues: {
                ...state.backValues,
                if (widget.hintTextController.text.trim().isNotEmpty)
                  'hint_text': widget.hintTextController.text.trim(),
              },
            );

            widget.onChanged(updatedState);
          },
        ),
      ],
    );
  }
}
