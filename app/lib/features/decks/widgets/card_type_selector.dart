import 'package:flutter/material.dart';
import '../../../core/models/vocabulary.dart';

class CardTypeSelector extends StatelessWidget {
  final CardType value;
  final ValueChanged<CardType> onChanged;

  const CardTypeSelector(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Loại thẻ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CardType>(
              value: value,
              isExpanded: true,
              itemHeight: 48,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                helperText: 'Chọn loại thẻ phù hợp với cách học',
              ),
              items: CardType.values.map((e) {
                String title = '';
                String subtitle = '';
                IconData icon = Icons.help_outline;

                switch (e) {
                  case CardType.basis:
                    title = 'Basis Card';
                    subtitle = 'Đơn giản';
                    icon = Icons.description;
                    break;
                  case CardType.reverse:
                    title = 'Reverse Card';
                    subtitle = 'Tạo 2 thẻ ngước nhau';
                    icon = Icons.swap_horiz;
                    break;
                  case CardType.typing:
                    title = 'Typing Card';
                    subtitle = 'Luyện gõ với gợi ý';
                    icon = Icons.keyboard;
                    break;
                }

                return DropdownMenuItem<CardType>(
                  value: e,
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$title - $subtitle',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
