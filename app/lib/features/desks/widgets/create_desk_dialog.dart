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
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_circle_outline, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Tạo deck mới'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomFormField(
              controller: _nameController,
              label: 'Tên deck',
              hintText: 'Nhập tên deck của bạn',
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
              maxLines: 1,
            ),
            const SizedBox(height: 20),
            const Text(
              'Màu sắc',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(
                        int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedColor,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openColorPicker,
                  icon: const Icon(Icons.palette_outlined, size: 18),
                  label: const Text('Chọn màu'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
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
            if (_formKey.currentState!.validate()) {
              final result = <String, String?>{
                'name': _nameController.text.trim(),
                'color': _selectedColor,
              };
              Navigator.of(context).pop(result);
            }
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tạo deck'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
