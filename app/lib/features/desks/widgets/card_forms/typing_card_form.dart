import 'package:flutter/material.dart';

class TypingCardForm extends StatelessWidget {
  final TextEditingController frontController;
  final TextEditingController backController;

  const TypingCardForm({
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
          decoration: const InputDecoration(
            labelText: 'Mặt trước (front) *',
            helperText: 'Người học sẽ gõ câu trả lời',
            border: UnderlineInputBorder(),
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
          decoration: const InputDecoration(
            labelText: 'Mặt sau (back) *',
            border: UnderlineInputBorder(),
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
