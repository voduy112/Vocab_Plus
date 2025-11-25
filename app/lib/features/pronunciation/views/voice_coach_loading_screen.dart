import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/deck.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/api/api_client.dart';
import '../../decks/services/vocabulary_service.dart';
import '../services/voice_coach_service.dart';

class VoiceCoachLoadingScreen extends StatefulWidget {
  final Deck deck;

  const VoiceCoachLoadingScreen({
    super.key,
    required this.deck,
  });

  @override
  State<VoiceCoachLoadingScreen> createState() =>
      _VoiceCoachLoadingScreenState();
}

class _VoiceCoachLoadingScreenState extends State<VoiceCoachLoadingScreen> {
  final VocabularyService _vocabularyService = VocabularyService();
  late final VoiceCoachService _voiceCoachService;

  @override
  void initState() {
    super.initState();
    // Khởi tạo ApiClient giống như pronunciation_practice_screen
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://192.168.2.167:3000',
    );
    final apiClient = ApiClient(apiBaseUrl);
    _voiceCoachService = VoiceCoachService(apiClient: apiClient);
    _loadVocabularies();
  }

  List<Vocabulary> _vocabularies = [];
  Map<int, bool> _loadingStatus = {}; // vocabulary.id -> isLoaded
  Map<int, bool> _isLoadingMap = {}; // vocabulary.id -> isCurrentlyLoading
  Map<int, String?> _audioPaths = {}; // vocabulary.id -> audioPath
  bool _isLoading = true;
  bool _isLoadingAll = false;
  bool _hasError = false;
  String? _errorMessage;

  Future<void> _loadVocabularies() async {
    if (widget.deck.id == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Deck không hợp lệ';
      });
      return;
    }

    try {
      final vocabularies =
          await _vocabularyService.getVocabulariesByDeckId(widget.deck.id!);
      final activeVocabularies = vocabularies.where((v) => v.isActive).toList();

      // Khởi tạo trạng thái loading cho tất cả từ vựng
      final Map<int, bool> loadingStatus = {};
      final Map<int, bool> isLoadingMap = {};
      final Map<int, String?> audioPaths = {};

      for (final vocab in activeVocabularies) {
        if (vocab.id != null) {
          loadingStatus[vocab.id!] = false;
          isLoadingMap[vocab.id!] = false;
        }
      }

      // Kiểm tra cache cho tất cả từ vựng TRƯỚC KHI setState
      for (final vocab in activeVocabularies) {
        if (vocab.id == null) continue;
        if (!mounted) return;

        try {
          // Kiểm tra xem audio đã tồn tại chưa
          final audioPath = await _voiceCoachService.getAudioPath(vocab);
          if (audioPath != null) {
            // Kiểm tra file có thực sự tồn tại không
            final file = File(audioPath);
            if (await file.exists()) {
              loadingStatus[vocab.id!] = true;
              audioPaths[vocab.id!] = audioPath;
            }
          }
        } catch (e) {
          // Bỏ qua lỗi khi check cache
          debugPrint(
              '[VoiceCoach] Error checking cache for ${vocab.front}: $e');
        }
      }

      // Chỉ setState một lần sau khi đã kiểm tra xong cache
      if (mounted) {
        setState(() {
          _vocabularies = activeVocabularies;
          _loadingStatus = loadingStatus;
          _isLoadingMap = isLoadingMap;
          _audioPaths = audioPaths;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Lỗi khi tải từ vựng: $e';
        });
      }
    }
  }

  /// Tải audio cho một từ vựng cụ thể
  Future<void> _loadSingleVocabulary(Vocabulary vocab) async {
    if (vocab.id == null) return;
    if (_isLoadingMap[vocab.id!] == true) return; // Đang tải rồi

    // Kiểm tra xem đã tải chưa
    if (_loadingStatus[vocab.id!] == true) {
      final existingPath = _audioPaths[vocab.id!];
      if (existingPath != null) {
        final file = File(existingPath);
        if (await file.exists()) {
          // Đã tải rồi, không cần tải lại
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Audio cho "${vocab.front}" đã được tải rồi'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }
    }

    setState(() {
      _isLoadingMap[vocab.id!] = true;
    });

    try {
      final audioPath = await _voiceCoachService.loadVoiceCoachAudio(vocab);
      if (mounted) {
        setState(() {
          _loadingStatus[vocab.id!] = true;
          _audioPaths[vocab.id!] = audioPath;
          _isLoadingMap[vocab.id!] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingStatus[vocab.id!] = true; // Đánh dấu là đã xử lý (dù lỗi)
          _audioPaths[vocab.id!] = null;
          _isLoadingMap[vocab.id!] = false;
        });
      }
    }
  }

  /// Tải tất cả từ vựng
  Future<void> _loadAllVocabularies() async {
    if (_isLoadingAll) return;

    setState(() {
      _isLoadingAll = true;
    });

    for (final vocab in _vocabularies) {
      if (!mounted) return;
      if (vocab.id == null) continue;

      // Kiểm tra xem đã tải chưa (bao gồm cả file có tồn tại không)
      if (_loadingStatus[vocab.id!] == true) {
        final existingPath = _audioPaths[vocab.id!];
        if (existingPath != null) {
          final file = File(existingPath);
          if (await file.exists()) {
            // Đã tải rồi, bỏ qua
            continue;
          }
        }
      }

      await _loadSingleVocabulary(vocab);

      // Thêm delay nhỏ để UI mượt hơn
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      setState(() {
        _isLoadingAll = false;
      });
    }
  }

  /// Đếm số từ vựng đã tải
  int get _loadedCount {
    return _loadingStatus.values.where((loaded) => loaded == true).length;
  }

  /// Kiểm tra xem tất cả đã tải chưa
  bool get _allLoaded {
    if (_vocabularies.isEmpty) return false;
    return _loadedCount == _vocabularies.length;
  }

  void _navigateBackToPractice() {
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _navigateBackToPractice,
        ),
        title: const Text('Tải âm thanh Voice Coach'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Đã xảy ra lỗi',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Quay lại'),
                      ),
                    ],
                  ),
                )
              : _vocabularies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_rounded,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Không có từ vựng nào',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Quay lại'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Progress header
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: _vocabularies.isEmpty
                                    ? 0
                                    : _loadedCount / _vocabularies.length,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6366F1)),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Đã tải: $_loadedCount / ${_vocabularies.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (!_allLoaded)
                                    TextButton.icon(
                                      onPressed: _isLoadingAll
                                          ? null
                                          : _loadAllVocabularies,
                                      icon: _isLoadingAll
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.download_rounded,
                                              size: 18),
                                      label: Text(
                                        _isLoadingAll
                                            ? 'Đang tải...'
                                            : 'Tải tất cả',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Vocabulary list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _vocabularies.length,
                            itemBuilder: (context, index) {
                              final vocab = _vocabularies[index];
                              final isLoaded = vocab.id != null
                                  ? _loadingStatus[vocab.id!] ?? false
                                  : false;
                              final isLoading = vocab.id != null
                                  ? _isLoadingMap[vocab.id!] ?? false
                                  : false;
                              final hasAudio = vocab.id != null
                                  ? _audioPaths[vocab.id!] != null
                                  : false;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: isLoading ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: isLoading
                                      ? const BorderSide(
                                          color: Color(0xFF6366F1),
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Status icon
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isLoading
                                              ? const Color(0xFF6366F1)
                                                  .withOpacity(0.1)
                                              : isLoaded
                                                  ? (hasAudio
                                                      ? Colors.green
                                                          .withOpacity(0.1)
                                                      : Colors.orange
                                                          .withOpacity(0.1))
                                                  : Colors.grey
                                                      .withOpacity(0.1),
                                        ),
                                        child: isLoading
                                            ? const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Color(0xFF6366F1),
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                isLoaded
                                                    ? (hasAudio
                                                        ? Icons
                                                            .check_circle_rounded
                                                        : Icons.warning_rounded)
                                                    : Icons
                                                        .radio_button_unchecked_rounded,
                                                color: isLoaded
                                                    ? (hasAudio
                                                        ? Colors.green
                                                        : Colors.orange)
                                                    : Colors.grey,
                                                size: 24,
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Vocabulary info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vocab.front,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            if (vocab.back.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                vocab.back,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Download button
                                      if (!isLoaded)
                                        IconButton(
                                          onPressed: isLoading
                                              ? null
                                              : () =>
                                                  _loadSingleVocabulary(vocab),
                                          icon: isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.download_rounded,
                                                  color: Color(0xFF6366F1),
                                                ),
                                          tooltip: 'Tải âm thanh',
                                        )
                                      else if (hasAudio)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
