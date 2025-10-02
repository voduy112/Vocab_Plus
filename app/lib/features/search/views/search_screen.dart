import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/search_controller.dart' as app_search;
import '../../../data/dictionary/models.dart';
import '../../../data/dictionary/dictionary_repository.dart';
import '../../../core/widgets/search.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          app_search.SearchController(DictionaryRepository())..warmUp(),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<app_search.SearchController>();
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Search(
                    controller: ctrl.textController,
                    onChanged: ctrl.onChanged,
                    onSubmitted: ctrl.onChanged,
                    onClear: ctrl.clear,
                    hintText: 'Tìm từ hoặc nghĩa (việt)...',
                  ),
                ),
                if (ctrl.loading) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.separated(
                    itemCount: ctrl.results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final w = ctrl.results[index];
                      final subtitle = w.wordVi ??
                          (w.senses.isNotEmpty
                              ? (w.senses.first.glossesVi.isNotEmpty
                                  ? w.senses.first.glossesVi.first
                                  : (w.senses.first.glosses.isNotEmpty
                                      ? w.senses.first.glosses.first
                                      : null))
                              : null);
                      return ListTile(
                        leading: _WordAvatar(entry: w),
                        title: Text(w.word),
                        subtitle: subtitle == null ? null : Text(subtitle),
                        trailing: Text(w.pos ?? ''),
                        onTap: () => context.push('/word', extra: w),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WordAvatar extends StatelessWidget {
  final WordEntry entry;
  const _WordAvatar({required this.entry});
  @override
  Widget build(BuildContext context) {
    if (entry.images.isEmpty || entry.images.first.local == null) {
      return CircleAvatar(
          child: Text(entry.word.substring(0, 1).toUpperCase()));
    }
    final local = entry.images.first.local!; // relative path
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'lib/core/assets/dictionary/$local',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            CircleAvatar(child: Text(entry.word.substring(0, 1).toUpperCase())),
      ),
    );
  }
}
