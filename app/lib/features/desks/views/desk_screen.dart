// features/desks/desks_screen.dart
import 'package:flutter/material.dart';

class DesksScreen extends StatelessWidget {
  const DesksScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Danh sách desk',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Tạo desk mới')),
          const SizedBox(height: 16),
          ...List.generate(
              3,
              (i) => _DeskTile(
                  name: ['Travel', 'Language', 'Music'][i],
                  progress: [0.75, 0.5, 0.9][i])),
        ],
      ),
    );
  }
}

class _DeskTile extends StatelessWidget {
  final String name;
  final double progress;
  const _DeskTile({required this.name, required this.progress});
  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          title:
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle:
              const Text('120 words · 5 words\nÔn tập tiếp theo: Ngày mai'),
          trailing: SizedBox(
            width: 44,
            height: 44,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: progress, strokeWidth: 6),
              Text('${(progress * 100).round()}%')
            ]),
          ),
        ),
      );
}
