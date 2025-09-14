// features/main/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/widgets/search.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthController>().displayName;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome back,',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w400,
                  )),
          Text(name,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 12),
          const Search(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Category', onSeeAll: () {}),
          const SizedBox(height: 12),
          const Wrap(spacing: 12, runSpacing: 12, children: [
            _Chip(label: 'Travel', icon: Icons.work_outline),
            _Chip(label: 'Learn', icon: Icons.pause_circle_outline),
            _Chip(label: 'Finance', icon: Icons.attach_money),
          ]),
          const SizedBox(height: 24),
          _SectionHeader(title: 'New words', onSeeAll: () {}),
          const SizedBox(height: 12),
          const _WordCard(
              title: 'Quaintrelle',
              ipa: '/kwāˈnˈtrel/',
              meaning: 'to go to a place in order to look at it'),
          const SizedBox(height: 12),
          const _WordCard(
              title: 'Learn',
              ipa: '/lɜːn/',
              meaning: 'to get new knowledge or skill'),
          const SizedBox(height: 12),
          const _WordCard(
              title: 'Learn',
              ipa: '/lɜːn/',
              meaning: 'to get new knowledge or skill'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          TextButton(onPressed: onSeeAll, child: const Text('See All')),
        ],
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      );
}

class _WordCard extends StatelessWidget {
  final String title, ipa, meaning;
  const _WordCard(
      {required this.title, required this.ipa, required this.meaning});
  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                      width: 56, height: 56, color: Colors.grey.shade300)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('Travel'),
                    ),
                    const SizedBox(height: 6),
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(ipa,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Colors.grey[700])),
                  ])),
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.volume_up_outlined))
            ]),
            const SizedBox(height: 12),
            Text(meaning),
            const SizedBox(height: 8),
            Text('We visited a few galleries while we were in Prague.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontStyle: FontStyle.italic))
          ]),
        ),
      );
}
