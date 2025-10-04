import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/dictionary/dictionary_repository.dart';
import '../../../data/dictionary/models.dart';
import '../services/search_history_service.dart';

class SearchController extends ChangeNotifier {
  final DictionaryRepository repository;
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final SearchHistoryService _historyService = SearchHistoryService();

  List<WordEntry> _results = const [];
  bool _loading = false;
  Timer? _debounce;
  bool _disposed = false;
  List<String> _recent = const [];
  bool _showHistory = false;

  SearchController(this.repository);

  List<WordEntry> get results => _results;
  bool get loading => _loading;
  List<String> get recent => _recent;
  bool get showHistory => _showHistory;

  void warmUp() {
    repository.loadAll();
    _loadRecent();
    focusNode.addListener(() {
      if (_disposed) return;
      _setShowHistory(focusNode.hasFocus);
    });
  }

  Future<void> onChanged(String value) async {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _results = const [];
      _setShowHistory(true);
      return;
    }
    _setShowHistory(false);
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      _setLoading(true);
      final found = await repository.search(trimmed, limit: 100);
      if (_disposed) return;
      _results = found;
      _setLoading(false);
    });
  }

  void clear() {
    textController.clear();
    _results = const [];
    _setShowHistory(true);
  }

  Future<void> _loadRecent() async {
    final items = await _historyService.getRecent();
    if (_disposed) return;
    _recent = items;
    notifyListeners();
  }

  Future<void> addToHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    await _historyService.addQuery(q);
    await _loadRecent();
  }

  Future<void> removeRecent(String query) async {
    await _historyService.remove(query);
    await _loadRecent();
  }

  Future<void> clearRecent() async {
    await _historyService.clearAll();
    await _loadRecent();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setShowHistory(bool v) {
    _showHistory = v;
    notifyListeners();
  }

  void showHistoryNow() {
    _setShowHistory(true);
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
