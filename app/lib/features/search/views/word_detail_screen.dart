import 'package:flutter/material.dart';
import '../../../data/dictionary/models.dart';
import '../../../data/dictionary/dictionary_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/word_header.dart';
import '../widgets/images_strip.dart';
import 'package:provider/provider.dart';
import '../controllers/word_detail_controller.dart';

class WordDetailScreen extends StatelessWidget {
  final WordEntry entry;
  const WordDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    // final theme = Theme.of(context);
    // Senses will be loaded/grouped dynamically per POS

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(entry.word),
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
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
          bottom: TabBar(
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'ANH - VIỆT'),
              Tab(text: 'ANH - ANH'),
              Tab(text: 'ĐỒNG NGHĨA'),
              Tab(text: 'TRÁI NGHĨA'),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WordHeader(entry: entry),
            ImagesStrip(entry: entry),
            const SizedBox(height: 8),
            Expanded(
              child: ChangeNotifierProvider(
                create: (_) => WordDetailController(
                    repository: DictionaryRepository(), word: entry.word)
                  ..load(),
                child: Builder(builder: (context) {
                  final ctrl = context.watch<WordDetailController>();
                  if (ctrl.loading && ctrl.entries.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final grouped = ctrl.groupedByPos.isEmpty
                      ? _groupByPos([entry])
                      : ctrl.groupedByPos;
                  final posKeys = grouped.keys.toList()..sort();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (posKeys.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in posKeys)
                                Chip(
                                  label: Text(p.toUpperCase()),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  visualDensity: const VisualDensity(
                                      horizontal: -4, vertical: -4),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: Colors.blue.shade50,
                                  side: BorderSide(color: Colors.blue.shade200),
                                  labelStyle: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      Expanded(
                        child: TabBarView(
                          children: [
                            _GroupedSensesTab(groups: grouped, viFirst: true),
                            _GroupedSensesTab(groups: grouped, viFirst: false),
                            _SynonymsTab(senses: entry.senses),
                            _AntonymsTab(senses: entry.senses),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SenseCard extends StatelessWidget {
  final Sense sense;
  final int index;
  final bool viFirst;
  const _SenseCard(
      {required this.sense, required this.index, required this.viFirst});
  @override
  Widget build(BuildContext context) {
    final gloss = viFirst
        ? (sense.glossesVi.isNotEmpty
            ? sense.glossesVi.first
            : (sense.glosses.isNotEmpty ? sense.glosses.first : ''))
        : (sense.glosses.isNotEmpty
            ? sense.glosses.first
            : (sense.glossesVi.isNotEmpty ? sense.glossesVi.first : ''));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$index',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.blue)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(gloss,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (sense.examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(viFirst ? 'Ví dụ' : 'Example',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 6),
              for (final ex in sense.examples)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ex.text != null)
                        Text('“${ex.text}”',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontStyle: FontStyle.italic)),
                      if (viFirst && ex.textVi != null)
                        Text(ex.textVi!,
                            style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }
}

// _SensesList removed; using grouped-by-POS rendering

Map<String, List<Sense>> _groupByPos(List<WordEntry> entries) {
  final Map<String, List<Sense>> map = <String, List<Sense>>{};
  for (final e in entries) {
    final key = (e.pos ?? 'khác');
    final list = map.putIfAbsent(key, () => <Sense>[]);
    list.addAll(e.senses);
  }
  return map;
}

class _GroupedSensesTab extends StatelessWidget {
  final Map<String, List<Sense>> groups;
  final bool viFirst;
  const _GroupedSensesTab({required this.groups, required this.viFirst});
  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const _PlaceholderEmpty(label: 'Không có dữ liệu');
    }
    final keys = groups.keys.toList();
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: keys.length,
      itemBuilder: (context, idx) {
        final pos = keys[idx];
        final senses = groups[pos] ?? const <Sense>[];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.play_arrow,
                        size: 20, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Text(
                      '${pos.toUpperCase()}:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < senses.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SenseCard(
                    sense: senses[i],
                    index: i + 1,
                    viFirst: viFirst,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaceholderEmpty extends StatelessWidget {
  final String label;
  const _PlaceholderEmpty({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _SynonymsTab extends StatelessWidget {
  final List<Sense> senses;
  const _SynonymsTab({required this.senses});
  @override
  Widget build(BuildContext context) {
    final all = <String>{};
    for (final s in senses) {
      all.addAll(s.synonyms);
    }
    final list = all.toList()..sort();
    if (list.isEmpty) {
      return const _PlaceholderEmpty(label: 'Không có từ đồng nghĩa');
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in list)
              ActionChip(
                label: Text(w),
                onPressed: () => _openWordDetail(context, w),
                backgroundColor: Colors.grey.shade100,
              ),
          ],
        ),
      ],
    );
  }
}

class _AntonymsTab extends StatelessWidget {
  final List<Sense> senses;
  const _AntonymsTab({required this.senses});
  @override
  Widget build(BuildContext context) {
    final all = <String>{};
    for (final s in senses) {
      all.addAll((s.antonyms ?? const <String>[]));
    }
    final list = all.toList()..sort();
    if (list.isEmpty) {
      return const _PlaceholderEmpty(label: 'Không có từ trái nghĩa');
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in list)
              ActionChip(
                label: Text(w),
                onPressed: () => _openWordDetail(context, w),
                backgroundColor: Colors.grey.shade100,
              ),
          ],
        ),
      ],
    );
  }
}

Future<void> _openWordDetail(BuildContext context, String word) async {
  final repo = DictionaryRepository();
  final entries = await repo.getEntriesByWord(word);
  if (entries.isEmpty) return;
  // Prefer an entry that has senses
  entries.sort((a, b) => b.senses.length.compareTo(a.senses.length));
  final entry = entries.first;
  // Navigate to a new detail screen
  // Using Navigator to avoid routing dependency assumptions
  // ignore: use_build_context_synchronously
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => WordDetailScreen(entry: entry)),
  );
}

class _SoundButtons extends StatefulWidget {
  final WordEntry entry;
  const _SoundButtons({required this.entry});
  @override
  State<_SoundButtons> createState() => _SoundButtonsState();
}

class _SoundButtonsState extends State<_SoundButtons> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  WordSound? _findByTag(String tag) {
    final sounds = widget.entry.sounds ?? const <WordSound>[];
    final upper = tag.toUpperCase();
    // Prefer explicit tag match (case-insensitive)
    final tagged = sounds.where((s) =>
        s.audio != null &&
        s.tags.any((t) => t.toString().toUpperCase() == upper));
    if (tagged.isNotEmpty) return tagged.first;
    // Heuristic fallback by filename pattern
    final byName = sounds.where(
        (s) => (s.audio ?? '').toLowerCase().contains(upper.toLowerCase()));
    if (byName.isNotEmpty) return byName.first;
    return null;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playForTag(String tag) async {
    final sound = _findByTag(tag);
    final fileName = sound?.audio;
    if (fileName == null || fileName.isEmpty) return;

    setState(() => _isPlaying = true);
    final url = await SoundResolverService().resolveCommonsUrl(fileName);
    if (url != null) {
      await _player.stop();
      await _player.play(UrlSource(url));
    }
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasUS = _findByTag('US')?.audio != null;
    final hasUK = _findByTag('UK')?.audio != null;
    if (!hasUS && !hasUK) return const SizedBox.shrink();
    return Row(
      children: [
        if (hasUS)
          _SoundIconButton(
            tooltip: 'US',
            isLoading: _isPlaying,
            onPressed: () => _playForTag('US'),
          ),
        const SizedBox(width: 8),
        if (hasUK)
          _SoundIconButton(
            tooltip: 'UK',
            isLoading: _isPlaying,
            onPressed: () => _playForTag('UK'),
          ),
      ],
    );
  }
}

class _SoundActions extends StatefulWidget {
  final WordEntry entry;
  const _SoundActions({required this.entry});
  @override
  State<_SoundActions> createState() => _SoundActionsState();
}

class _SoundActionsState extends State<_SoundActions> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  WordSound? _findByTag(String tag) {
    final sounds = widget.entry.sounds ?? const <WordSound>[];
    final upper = tag.toUpperCase();
    final tagged = sounds.where((s) =>
        s.audio != null &&
        s.tags.any((t) => t.toString().toUpperCase() == upper));
    if (tagged.isNotEmpty) return tagged.first;
    final byName = sounds.where(
        (s) => (s.audio ?? '').toLowerCase().contains(upper.toLowerCase()));
    if (byName.isNotEmpty) return byName.first;
    return null;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playForTag(String tag) async {
    final sound = _findByTag(tag);
    final fileName = sound?.audio;
    if (fileName == null || fileName.isEmpty) return;
    setState(() => _isPlaying = true);
    final url = await SoundResolverService().resolveCommonsUrl(fileName);
    if (url != null) {
      await _player.stop();
      await _player.play(UrlSource(url));
    }
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasUS = _findByTag('US')?.audio != null;
    final hasUK = _findByTag('UK')?.audio != null;
    if (!hasUS && !hasUK) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasUS)
          _SoundIconButton(
            tooltip: 'US',
            isLoading: _isPlaying,
            onPressed: () => _playForTag('US'),
          ),
        if (hasUK)
          _SoundIconButton(
            tooltip: 'UK',
            isLoading: _isPlaying,
            onPressed: () => _playForTag('UK'),
          ),
      ],
    );
  }
}

class _SoundIconButton extends StatelessWidget {
  final String tooltip;
  final bool isLoading;
  final VoidCallback onPressed;
  const _SoundIconButton(
      {required this.tooltip,
      required this.isLoading,
      required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: const Icon(Icons.volume_up, size: 20),
      label: Text(tooltip),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue.shade800,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

// IPA widgets moved to features/search/widgets/ipa_row.dart
