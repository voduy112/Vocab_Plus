import 'package:flutter/material.dart';

class ReverseCardForm extends StatelessWidget {
  final TextEditingController frontController;
  final TextEditingController backController;

  const ReverseCardForm({
    super.key,
    required this.frontController,
    required this.backController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: frontController,
          decoration: InputDecoration(
            labelText: 'Mặt trước (front) *',
            hintText: 'Nhập từ vựng hoặc câu hỏi',
            prefixIcon: const Icon(Icons.swap_horiz),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            helperText: 'Đây sẽ là mặt hiển thị trước khi học',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập mặt trước';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: backController,
          decoration: InputDecoration(
            labelText: 'Mặt sau (back) *',
            hintText: 'Nhập nghĩa hoặc câu trả lời',
            prefixIcon: const Icon(Icons.swap_horiz),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            helperText: 'Đây sẽ là mặt hiển thị sau khi học',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập mặt sau';
            }
            return null;
          },
        ),
      ],
    );
  }
}
