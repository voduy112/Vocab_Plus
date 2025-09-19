import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../core/widgets/custom_form_field.dart';

class CreateDeskDialog extends StatefulWidget {
  const CreateDeskDialog({super.key});

  @override
  State<CreateDeskDialog> createState() => _CreateDeskDialogState();
}

class _CreateDeskDialogState extends State<CreateDeskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '#2196F3';

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
          title: const Text('Chọn màu'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: current,
              onColorChanged: (color) {
                current = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
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
              child: const Text('Chọn'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    return AlertDialog(
      scrollable: true,
      title: const Text('Tạo desk mới'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomFormField(
                  controller: _nameController,
                  label: 'Tên desk',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên desk';
                    }
                    return null;
                  },
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                            _selectedColor.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_selectedColor),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openColorPicker,
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text('Chọn màu'),
                    ),
                  ],
                ),
              ],
            ),
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
              final result = <String, String?>{
                'name': _nameController.text.trim(),
                'color': _selectedColor,
              };
              Navigator.of(context).pop(result);
            }
          },
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}
