import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../core/widgets/context_menu_scaffold.dart';
import '../../../core/widgets/custom_form_field.dart';
import '../../../core/models/deck.dart';
import '../repositories/deck_repository.dart';

class CreateDeckDialog extends StatefulWidget {
  const CreateDeckDialog({super.key});

  @override
  State<CreateDeckDialog> createState() => _CreateDeckDialogState();
}

class _CreateDeckDialogState extends State<CreateDeckDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '#2196F3';

  bool get _isValid {
    final String name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2 || name.length > 50) return false;
    return true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openColorPicker() async {
    Color current = Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')));
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.palette, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('Chọn màu sắc'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlockPicker(
                  pickerColor: current,
                  onColorChanged: (color) {
                    current = color;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: current,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${current.red.toRadixString(16).padLeft(2, '0')}'
                                '${current.green.toRadixString(16).padLeft(2, '0')}'
                                '${current.blue.toRadixString(16).padLeft(2, '0')}'
                            .toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _selectedColor = '#'
                          '${current.red.toRadixString(16).padLeft(2, '0')}'
                          '${current.green.toRadixString(16).padLeft(2, '0')}'
                          '${current.blue.toRadixString(16).padLeft(2, '0')}'
                      .toUpperCase();
                });
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Chọn màu'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: ContextMenuScaffold(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Deck',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomFormField(
                        controller: _nameController,
                        label: 'Deck',
                        hintText: 'Deck',
                        suffixIcon: InkWell(
                          onTap: _openColorPicker,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(int.parse(
                                    _selectedColor.replaceFirst('#', '0xFF'))),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên deck';
                          }
                          if (value.trim().length < 2) {
                            return 'Tên deck phải có ít nhất 2 ký tự';
                          }
                          if (value.trim().length > 50) {
                            return 'Tên deck không được quá 50 ký tự';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isValid
                            ? () async {
                                if (!_formKey.currentState!.validate()) return;
                                final repo = context.read<DeckRepository>();
                                final now = DateTime.now();
                                final desk = Deck(
                                  name: _nameController.text.trim(),
                                  color: _selectedColor,
                                  createdAt: now,
                                  updatedAt: now,
                                );
                                final id = await repo.createDesk(desk);
                                final created = desk.copyWith(id: id);
                                if (context.mounted) {
                                  Navigator.of(context).pop(created);
                                }
                              }
                            : null,
                        child: const Text('Add deck'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


