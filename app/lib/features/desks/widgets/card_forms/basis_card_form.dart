import 'package:flutter/material.dart';
import 'dynamic_card_form.dart';

class BasisCardForm extends StatefulWidget {
  final TextEditingController frontController;
  final TextEditingController backController;
  final TextEditingController pronunciationController;
  final TextEditingController exampleController;
  final TextEditingController translationController;
  final Function(DynamicFormState) onChanged;
  final Map<String, String>? initialFrontExtra;
  final Map<String, String>? initialBackExtra;

  const BasisCardForm({
    super.key,
    required this.frontController,
    required this.backController,
    required this.pronunciationController,
    required this.exampleController,
    required this.translationController,
    required this.onChanged,
    this.initialFrontExtra,
    this.initialBackExtra,
  });

  @override
  State<BasisCardForm> createState() => _BasisCardFormState();
}

class _BasisCardFormState extends State<BasisCardForm> {
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
    return DynamicCardForm(
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
        widget.onChanged(state);
      },
    );
  }
}
