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
            prefixIcon: const Icon(Icons.swap_horiz),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            prefixIcon: const Icon(Icons.swap_horiz),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
