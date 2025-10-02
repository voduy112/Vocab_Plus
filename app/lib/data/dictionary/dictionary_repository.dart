import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';
import 'package:dio/dio.dart';

class DictionaryRepository {
  final String jsonlAssetPath;
  final String imagesBasePath; // e.g. assets/dictionary/images_small/
  // Static cache shared across all repository instances to avoid reloading large asset
  static List<WordEntry>? _cache;

  DictionaryRepository({
    this.jsonlAssetPath = 'lib/core/assets/dictionary/simple_with_vi.jsonl',
    this.imagesBasePath = 'lib/core/assets/dictionary/',
  });

  Future<List<WordEntry>> loadAll() async {
    if (_cache != null) return _cache!;
    final data = await rootBundle.loadString(jsonlAssetPath);
    final lines = const LineSplitter().convert(data);
    final List<WordEntry> entries = [];
    for (final line in lines) {
      final entry = WordEntry.tryParseLine(line);
      if (entry != null) entries.add(entry);
    }
    _cache = entries;
    return entries;
  }

  Future<List<WordEntry>> search(String query, {int limit = 20}) async {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return [];
    final entries = await loadAll();
    // Deduplicate by word (case-insensitive), keep first match to preserve order
    final Map<String, WordEntry> uniqueByWord = <String, WordEntry>{};
    for (final entry in entries) {
      final wordKey = entry.word.toLowerCase();
      if (entry.word.toLowerCase().startsWith(lower) ||
          (entry.wordVi ?? '').toLowerCase().contains(lower)) {
        uniqueByWord.putIfAbsent(wordKey, () => entry);
        if (uniqueByWord.length >= limit) break;
      }
    }
    return uniqueByWord.values.toList(growable: false);
  }

  /// Return all distinct parts-of-speech labels available for a given word
  Future<List<String>> getPosLabelsFor(String word) async {
    final entries = await loadAll();
    final target = word.toLowerCase();
    final Set<String> posSet = <String>{};
    for (final e in entries) {
      if (e.word.toLowerCase() == target &&
          (e.pos != null && e.pos!.trim().isNotEmpty)) {
        posSet.add(e.pos!.trim());
      }
    }
    final list = posSet.toList();
    list.sort();
    return list;
  }

  /// Return all entries with the exact same word (case-insensitive)
  Future<List<WordEntry>> getEntriesByWord(String word) async {
    final entries = await loadAll();
    final target = word.toLowerCase();
    return entries
        .where((e) => e.word.toLowerCase() == target)
        .toList(growable: false);
  }
}

class SoundResolverService {
  static final SoundResolverService _instance =
      SoundResolverService._internal();
  factory SoundResolverService() => _instance;
  SoundResolverService._internal();

  final Dio _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12)));
  final Map<String, String> _cache = <String, String>{};

  Future<String?> resolveCommonsUrl(String fileName) async {
    if (fileName.isEmpty) return null;
    final cached = _cache[fileName];
    if (cached != null) return cached;

    // Build Wikimedia Commons API URL
    final encodedTitle = Uri.encodeComponent('File:$fileName');
    final uri = Uri.parse(
        'https://commons.wikimedia.org/w/api.php?action=query&titles=$encodedTitle&prop=imageinfo&iiprop=url&format=json&origin=*');
    try {
      final resp = await _dio.getUri(uri);
      final data = resp.data as Map<String, dynamic>;
      final query = data['query'] as Map<String, dynamic>?;
      final pages = query?['pages'] as Map<String, dynamic>?;
      if (pages == null) return null;
      for (final entry in pages.values) {
        final info =
            (entry['imageinfo'] as List?)?.first as Map<String, dynamic>?;
        final url = info?['url']?.toString();
        if (url != null && url.isNotEmpty) {
          _cache[fileName] = url;
          return url;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
