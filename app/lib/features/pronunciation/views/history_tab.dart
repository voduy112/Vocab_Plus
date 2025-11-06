import 'package:flutter/material.dart';

class PronunciationHistoryTab extends StatelessWidget {
  const PronunciationHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Chưa có lịch sử học',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy bắt đầu một buổi luyện để xem lịch sử tại đây',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
