import 'package:flutter/material.dart';

class BasisCardForm extends StatelessWidget {
  final TextEditingController frontController;
  final TextEditingController backController;
  final TextEditingController pronunciationController;
  final TextEditingController exampleController;
  final TextEditingController translationController;

  const BasisCardForm({
    super.key,
    required this.frontController,
    required this.backController,
    required this.pronunciationController,
    required this.exampleController,
    required this.translationController,
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
          controller: backController,
          decoration: const InputDecoration(
            labelText: 'Mặt sau (back) *',
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
          controller: pronunciationController,
          decoration: const InputDecoration(
            labelText: 'Phiên âm',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: exampleController,
          decoration: const InputDecoration(
            labelText: 'Ví dụ',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: translationController,
          decoration: const InputDecoration(
            labelText: 'Bản dịch ví dụ',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
