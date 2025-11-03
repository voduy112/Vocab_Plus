import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/search_controller.dart' as app_search;
import '../../../data/dictionary/models.dart';
import '../../../data/dictionary/dictionary_repository.dart';
import '../../../core/widgets/search_field.dart';
import 'package:lottie/lottie.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          app_search.SearchController(context.read<DictionaryRepository>())
            ..warmUp(),
      child: Builder(
        builder: (context) {
          final results =
              context.select<app_search.SearchController, List<WordEntry>>(
                  (c) => c.results);
          final recent =
              context.select<app_search.SearchController, List<String>>(
                  (c) => c.recent);
          final showHistory = context
              .select<app_search.SearchController, bool>((c) => c.showHistory);
          final ctrl = context.read<app_search.SearchController>();
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              title: const Text(
                'DICTIONARY',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              foregroundColor: Colors.black,
            ),
            body: Builder(builder: (context) {
              final isEmptyQuery = ctrl.textController.text.trim().isEmpty;
              Widget mainContent;
              if (!showHistory && isEmptyQuery && results.isEmpty) {
                mainContent = Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'lib/core/assets/splash/Empty Search.json',
                          width: 250,
                          repeat: true,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nhập từ bạn muốn tra cứu',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              } else if (showHistory) {
                if (recent.isEmpty) {
                  mainContent = Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'lib/core/assets/splash/Empty Search.json',
                            width: 250,
                            repeat: true,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nhập từ bạn muốn tra cứu',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  mainContent = ListView(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    children: [
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        title: const Text('Tìm kiếm gần đây'),
                        trailing: TextButton(
                          onPressed: () => context
                              .read<app_search.SearchController>()
                              .clearRecent(),
                          child: const Text('Xoá tất cả'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final q in recent)
                            InputChip(
                              avatar: const Icon(Icons.history, size: 18),
                              label: Text(q),
                              onPressed: () {
                                ctrl.textController.text = q;
                                ctrl.onChanged(q);
                              },
                              onDeleted: () => context
                                  .read<app_search.SearchController>()
                                  .removeRecent(q),
                            ),
                        ],
                      ),
                    ],
                  );
                }
              } else {
                mainContent = ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final w = results[index];
                    final subtitle = w.wordVi ??
                        (w.senses.isNotEmpty
                            ? (w.senses.first.glossesVi.isNotEmpty
                                ? w.senses.first.glossesVi.first
                                : (w.senses.first.glosses.isNotEmpty
                                    ? w.senses.first.glosses.first
                                    : null))
                            : null);
                    return ListTile(
                      title: Text(w.word),
                      subtitle: subtitle == null ? null : Text(subtitle),
                      leading: !(w.pos == null || w.pos!.trim().isEmpty)
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.blueGrey.shade100),
                              ),
                              child: Text(
                                w.pos!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Điền vào ô tìm kiếm',
                            icon: const Icon(Icons.north_west),
                            onPressed: () {
                              ctrl.textController.text = w.word;
                              ctrl.onChanged(w.word);
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        await ctrl.addToHistory(w.word);
                        if (context.mounted) {
                          context.push('/word', extra: w);
                        }
                      },
                    );
                  },
                );
              }

              return Column(
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 40,
                      child: Search(
                        controller: ctrl.textController,
                        focusNode: ctrl.focusNode,
                        onTap: ctrl.showHistoryNow,
                        onChanged: ctrl.onChanged,
                        onSubmitted: ctrl.onChanged,
                        onClear: ctrl.clear,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: mainContent),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}
