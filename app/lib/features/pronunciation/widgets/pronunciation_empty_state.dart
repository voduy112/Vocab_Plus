import 'package:flutter/material.dart';

class PronunciationEmptyState extends StatelessWidget {
  const PronunciationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Bộ từ này chưa có từ vựng',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}



