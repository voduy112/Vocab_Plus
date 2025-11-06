import 'package:flutter/material.dart';
import 'image_picker_field.dart';

class ImagePickSection extends StatelessWidget {
  final bool pickForFront;
  final String? frontImageUrl;
  final String? frontImagePath;
  final String? backImageUrl;
  final String? backImagePath;
  final String frontText;
  final String backText;
  final ValueChanged<bool> onToggleTarget;
  final void Function(bool forFront, String? url, String? path) onChanged;

  const ImagePickSection({
    super.key,
    required this.pickForFront,
    required this.frontImageUrl,
    required this.frontImagePath,
    required this.backImageUrl,
    required this.backImagePath,
    required this.frontText,
    required this.backText,
    required this.onToggleTarget,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Thêm ảnh cho',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Mặt trước'),
              selected: pickForFront,
              onSelected: (v) {
                if (!v) return;
                onToggleTarget(true);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Mặt sau'),
              selected: !pickForFront,
              onSelected: (v) {
                if (!v) return;
                onToggleTarget(false);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        VocabularyImagePicker(
          key: ValueKey(pickForFront),
          title: 'Ảnh (tuỳ chọn)',
          initialImageUrl: pickForFront ? frontImageUrl : backImageUrl,
          initialImagePath: pickForFront ? frontImagePath : backImagePath,
          suggestQuery: pickForFront ? frontText : backText,
          onChanged: (imageUrl, imagePath) {
            onChanged(pickForFront, imageUrl, imagePath);
          },
        ),
      ],
    );
  }
}
