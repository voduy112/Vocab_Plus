import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/dictionary/dictionary_repository.dart';
import '../../../data/dictionary/models.dart';

class SearchController extends ChangeNotifier {
  final DictionaryRepository repository;
  final TextEditingController textController = TextEditingController();

  List<WordEntry> _results = const [];
  bool _loading = false;
  Timer? _debounce;
  bool _disposed = false;

  SearchController(this.repository);

  List<WordEntry> get results => _results;
  bool get loading => _loading;

  void warmUp() {
    repository.loadAll();
  }

  Future<void> onChanged(String value) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      _setLoading(true);
      final found = await repository.search(value, limit: 100);
      if (_disposed) return;
      _results = found;
      _setLoading(false);
    });
  }

  void clear() {
    textController.clear();
    _results = const [];
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    textController.dispose();
    super.dispose();
  }
}
