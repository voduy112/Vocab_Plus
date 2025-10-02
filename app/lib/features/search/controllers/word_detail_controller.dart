import 'package:flutter/foundation.dart';
import '../../../data/dictionary/dictionary_repository.dart';
import '../../../data/dictionary/models.dart';

class WordDetailController extends ChangeNotifier {
  final DictionaryRepository repository;
  final String word;

  bool _loading = false;
  List<WordEntry> _entries = const [];
  Map<String, List<Sense>> _grouped = const {};

  WordDetailController({required this.repository, required this.word});

  bool get loading => _loading;
  List<WordEntry> get entries => _entries;
  Map<String, List<Sense>> get groupedByPos => _grouped;

  Future<void> load() async {
    _setLoading(true);
    final list = await repository.getEntriesByWord(word);
    _entries = list.isEmpty ? const [] : list;
    _grouped = _groupByPos(_entries);
    _setLoading(false);
  }

  Map<String, List<Sense>> _groupByPos(List<WordEntry> entries) {
    final Map<String, List<Sense>> map = <String, List<Sense>>{};
    if (entries.isEmpty) return map;
    for (final e in entries) {
      final key = (e.pos ?? 'khác');
      final list = map.putIfAbsent(key, () => <Sense>[]);
      list.addAll(e.senses);
    }
    return map;
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
