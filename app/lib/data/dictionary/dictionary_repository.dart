import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'package:dio/dio.dart';

// Top-level function to parse dictionary in isolate (required for compute)
List<WordEntry> _parseDictionaryInIsolate(String data) {
  final lines = const LineSplitter().convert(data);
  final List<WordEntry> entries = [];
  for (final line in lines) {
    final entry = WordEntry.tryParseLine(line);
    if (entry != null) entries.add(entry);
  }
  return entries;
}

class DictionaryRepository {
  final String jsonlAssetPath;
  final String imagesBasePath; // e.g. assets/dictionary/images_small/
  // Static cache shared across all repository instances to avoid reloading large asset
  static List<WordEntry>? _cache;
  static Map<String, List<WordEntry>>? _prefixIndex;
  static bool _isLoading = false;
  static Completer<List<WordEntry>>? _loadingCompleter;

  DictionaryRepository({
    this.jsonlAssetPath = 'lib/core/assets/dictionary/simple_with_vi.jsonl',
    this.imagesBasePath = 'lib/core/assets/dictionary/',
  });

  Future<List<WordEntry>> loadAll() async {
    if (_cache != null) return _cache!;

    // If already loading, wait for the existing load
    if (_isLoading && _loadingCompleter != null) {
      return _loadingCompleter!.future;
    }

    _isLoading = true;
    _loadingCompleter = Completer<List<WordEntry>>();

    try {
      // Load asset string
      final data = await rootBundle.loadString(jsonlAssetPath);

      // Parse in isolate to avoid blocking main thread
      final entries = await compute(_parseDictionaryInIsolate, data);

      _cache = entries;
      _buildIndex(entries);
      _isLoading = false;
      _loadingCompleter!.complete(entries);
      return entries;
    } catch (e) {
      _isLoading = false;
      if (!_loadingCompleter!.isCompleted) {
        _loadingCompleter!.completeError(e);
      }
      rethrow;
    }
  }

  // Build prefix index for faster search
  void _buildIndex(List<WordEntry> entries) {
    if (_prefixIndex != null) return;

    _prefixIndex = <String, List<WordEntry>>{};

    // Index by word prefixes (first 3 characters for fast lookup)
    for (final entry in entries) {
      final wordLower = entry.word.toLowerCase();
      if (wordLower.length >= 3) {
        final prefix = wordLower.substring(0, 3);
        _prefixIndex!.putIfAbsent(prefix, () => []).add(entry);
      }

      // Also index by wordVi if available
      if (entry.wordVi != null) {
        final viLower = entry.wordVi!.toLowerCase();
        if (viLower.length >= 2) {
          final prefix = viLower.substring(0, 2);
          _prefixIndex!.putIfAbsent(prefix, () => []).add(entry);
        }
      }
    }
  }

  Future<List<WordEntry>> search(String query, {int limit = 20}) async {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return [];

    final entries = await loadAll();

    // Use index for faster prefix matching
    if (lower.length >= 3 && _prefixIndex != null) {
      final prefix = lower.substring(0, 3);
      final candidates = _prefixIndex![prefix];

      if (candidates != null && candidates.isNotEmpty) {
        final Map<String, WordEntry> uniqueByWord = <String, WordEntry>{};

        // Search in indexed candidates first
        for (final entry in candidates) {
          final wordKey = entry.word.toLowerCase();
          if (entry.word.toLowerCase().startsWith(lower) ||
              (entry.wordVi ?? '').toLowerCase().contains(lower)) {
            uniqueByWord.putIfAbsent(wordKey, () => entry);
            if (uniqueByWord.length >= limit) {
              return uniqueByWord.values.toList(growable: false);
            }
          }
        }

        // If not enough results, fall back to full search
        if (uniqueByWord.length < limit) {
          for (final entry in entries) {
            final wordKey = entry.word.toLowerCase();
            if (!uniqueByWord.containsKey(wordKey) &&
                (entry.word.toLowerCase().startsWith(lower) ||
                    (entry.wordVi ?? '').toLowerCase().contains(lower))) {
              uniqueByWord.putIfAbsent(wordKey, () => entry);
              if (uniqueByWord.length >= limit) break;
            }
          }
        }

        return uniqueByWord.values.toList(growable: false);
      }
    }

    // Fallback to original search if index not available or query too short
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
