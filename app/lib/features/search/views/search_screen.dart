import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/search_controller.dart' as app_search;
import '../../../data/dictionary/models.dart';
import '../../../data/dictionary/dictionary_repository.dart';
import '../../../core/widgets/search.dart';
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
          final loading = context
              .select<app_search.SearchController, bool>((c) => c.loading);
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
              toolbarHeight: 105,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              titleSpacing: 8,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, 5),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade400,
                      Colors.pink.shade200,
                    ],
                  ),
                ),
              ),
              title: Column(
                children: [
                  Text('Dictionary', style: TextStyle(color: Colors.white)),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
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
                ],
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(loading ? 2 : 0),
                child: loading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : const SizedBox.shrink(),
              ),
            ),
            body: Builder(builder: (context) {
              final isEmptyQuery = ctrl.textController.text.trim().isEmpty;
              if (!showHistory && isEmptyQuery && results.isEmpty) {
                return Center(
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
              }
              if (showHistory) {
                if (recent.isEmpty) {
                  return Center(
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
                }
                return ListView.separated(
                  itemCount: recent.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        title: const Text('Tìm kiếm gần đây'),
                        trailing: TextButton(
                          onPressed: () => context
                              .read<app_search.SearchController>()
                              .clearRecent(),
                          child: const Text('Xoá tất cả'),
                        ),
                      );
                    }
                    final q = recent[index - 1];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(q),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => context
                            .read<app_search.SearchController>()
                            .removeRecent(q),
                      ),
                      onTap: () {
                        ctrl.textController.text = q;
                        ctrl.onChanged(q);
                      },
                    );
                  },
                );
              }
              return ListView.separated(
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
                        ? Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: Text(w.pos!),
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
            }),
          );
        },
      ),
    );
  }
}
