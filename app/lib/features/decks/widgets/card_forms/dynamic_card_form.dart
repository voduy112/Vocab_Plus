import 'package:flutter/material.dart';
import 'package:app/core/widgets/custom_form_field.dart';

class DynamicField {
  final String id;
  final String label;
  final String hint;
  final IconData? icon;
  final int maxLines;
  final bool isRequired;

  DynamicField({
    required this.id,
    required this.label,
    required this.hint,
    this.icon,
    this.maxLines = 1,
    this.isRequired = false,
  });
}

class DynamicFormState {
  final List<DynamicField> frontFields;
  final List<DynamicField> backFields;
  final Map<String, String> frontValues;
  final Map<String, String> backValues;

  const DynamicFormState({
    required this.frontFields,
    required this.backFields,
    required this.frontValues,
    required this.backValues,
  });
}

class DynamicCardForm extends StatefulWidget {
  final TextEditingController frontController;
  final TextEditingController backController;
  final List<DynamicField> availableFields;
  final List<DynamicField> initialFrontFields;
  final List<DynamicField> initialBackFields;
  final Function(DynamicFormState) onChanged;
  final Map<String, String>? initialFrontValues;
  final Map<String, String>? initialBackValues;

  const DynamicCardForm({
    super.key,
    required this.frontController,
    required this.backController,
    required this.availableFields,
    required this.initialFrontFields,
    required this.initialBackFields,
    required this.onChanged,
    this.initialFrontValues,
    this.initialBackValues,
  });

  @override
  State<DynamicCardForm> createState() => _DynamicCardFormState();
}

class _DynamicCardFormState extends State<DynamicCardForm> {
  late List<DynamicField> _frontFields;
  late List<DynamicField> _backFields;
  late Map<String, TextEditingController> _frontControllers;
  late Map<String, TextEditingController> _backControllers;

  @override
  void initState() {
    super.initState();
    _frontFields = List.from(widget.initialFrontFields);
    _backFields = List.from(widget.initialBackFields);
    _frontControllers = {};
    _backControllers = {};
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final field in _frontFields) {
      final initialValue = widget.initialFrontValues?[field.id] ?? '';
      _frontControllers[field.id] = TextEditingController(text: initialValue);
      _frontControllers[field.id]!.addListener(_emitChange);
    }
    for (final field in _backFields) {
      final initialValue = widget.initialBackValues?[field.id] ?? '';
      _backControllers[field.id] = TextEditingController(text: initialValue);
      _backControllers[field.id]!.addListener(_emitChange);
    }
  }

  void _emitChange() {
    // Include all values from controllers, even empty ones
    final frontValues = <String, String>{};
    for (final entry in _frontControllers.entries) {
      frontValues[entry.key] = entry.value.text;
    }

    final backValues = <String, String>{};
    for (final entry in _backControllers.entries) {
      backValues[entry.key] = entry.value.text;
    }

    widget.onChanged(
      DynamicFormState(
        frontFields: List.unmodifiable(_frontFields),
        backFields: List.unmodifiable(_backFields),
        frontValues: Map.unmodifiable(frontValues),
        backValues: Map.unmodifiable(backValues),
      ),
    );
  }

  void _addFrontField(DynamicField field) {
    setState(() {
      _frontFields.add(field);
      _frontControllers[field.id] = TextEditingController();
      _frontControllers[field.id]!.addListener(_emitChange);
    });
    _emitChange();
  }

  void _addBackField(DynamicField field) {
    setState(() {
      _backFields.add(field);
      _backControllers[field.id] = TextEditingController();
      _backControllers[field.id]!.addListener(_emitChange);
    });
    _emitChange();
  }

  void _removeFrontField(String fieldId) {
    setState(() {
      _frontFields.removeWhere((field) => field.id == fieldId);
      _frontControllers[fieldId]?.removeListener(_emitChange);
      _frontControllers[fieldId]?.dispose();
      _frontControllers.remove(fieldId);
    });
    _emitChange();
  }

  void _removeBackField(String fieldId) {
    setState(() {
      _backFields.removeWhere((field) => field.id == fieldId);
      _backControllers[fieldId]?.removeListener(_emitChange);
      _backControllers[fieldId]?.dispose();
      _backControllers.remove(fieldId);
    });
    _emitChange();
  }

  @override
  void dispose() {
    for (final controller in _frontControllers.values) {
      controller.removeListener(_emitChange);
      controller.dispose();
    }
    for (final controller in _backControllers.values) {
      controller.removeListener(_emitChange);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Front field (always present) + add button
        Row(
          children: [
            Expanded(
              child: _buildField(
                controller: widget.frontController,
                label: 'Mặt trước *',
                hint: 'Nhập từ vựng hoặc câu hỏi',
                icon: Icons.front_hand,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 8),
            if (_availableFor(_frontFields).isNotEmpty)
              _buildAddMenuButton(
                tooltip: 'Thêm trường cho mặt trước',
                existing: _frontFields,
                onSelected: _addFrontField,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Front dynamic fields
        ..._frontFields.map((field) => Column(
              children: [
                _buildDynamicField(field, _frontControllers, _removeFrontField),
                const SizedBox(height: 16),
              ],
            )),

        // Back field (always present) + add button
        Row(
          children: [
            Expanded(
              child: _buildField(
                controller: widget.backController,
                label: 'Mặt sau *',
                hint: 'Nhập nghĩa hoặc câu trả lời',
                icon: Icons.back_hand,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 8),
            if (_availableFor(_backFields).isNotEmpty)
              _buildAddMenuButton(
                tooltip: 'Thêm trường cho mặt sau',
                existing: _backFields,
                onSelected: _addBackField,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Back dynamic fields
        ..._backFields.map((field) => Column(
              children: [
                _buildDynamicField(field, _backControllers, _removeBackField),
                const SizedBox(height: 16),
              ],
            )),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
  }) {
    return CustomFormField(
      controller: controller,
      label: label,
      hintText: hint,
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập thông tin';
              }
              return null;
            }
          : null,
    );
  }

  List<DynamicField> _availableFor(List<DynamicField> existing) {
    return widget.availableFields
        .where((field) => !existing.any((f) => f.id == field.id))
        .toList();
  }

  Widget _buildAddMenuButton({
    required String tooltip,
    required List<DynamicField> existing,
    required void Function(DynamicField) onSelected,
  }) {
    final options = _availableFor(existing);
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 56, // align with default TextFormField height
        child: Center(
          child: PopupMenuButton<DynamicField>(
            padding: const EdgeInsets.only(bottom: 5),
            tooltip: tooltip,
            child: const Icon(Icons.add_circle_outline),
            itemBuilder: (context) => options
                .map((f) => PopupMenuItem<DynamicField>(
                      value: f,
                      child: Row(
                        children: [
                          if (f.icon != null) ...[
                            Icon(f.icon, size: 16),
                            const SizedBox(width: 8),
                          ],
                          Expanded(child: Text(f.label)),
                        ],
                      ),
                    ))
                .toList(),
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicField(
    DynamicField field,
    Map<String, TextEditingController> controllers,
    void Function(String) onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(field.icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: CustomFormField(
              controller: controllers[field.id],
              label: field.label,
              hintText: field.hint,
              maxLines: field.maxLines,
              validator: field.isRequired
                  ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập thông tin';
                      }
                      return null;
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => onRemove(field.id),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            tooltip: 'Xóa trường',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // Deprecated: chip-based add button replaced by compact + popup menu near fields
}
