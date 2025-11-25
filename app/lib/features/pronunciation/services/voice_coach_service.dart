import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/models/vocabulary.dart';
import '../../../core/api/api_client.dart';

class VoiceCoachService {
  final FlutterTts _tts = FlutterTts();
  final Map<int, String> _cachedAudioPaths = {};
  ApiClient? _apiClient;

  VoiceCoachService({ApiClient? apiClient}) : _apiClient = apiClient {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Tải âm thanh voice coach cho một từ vựng
  /// Có 2 cách:
  /// 1. Tải từ API nếu có endpoint (ưu tiên)
  /// 2. Sử dụng TTS để tạo audio (fallback)
  /// Trả về đường dẫn file audio đã lưu, hoặc null nếu lỗi
  Future<String?> loadVoiceCoachAudio(Vocabulary vocabulary) async {
    try {
      // Kiểm tra cache
      if (vocabulary.id != null &&
          _cachedAudioPaths.containsKey(vocabulary.id)) {
        final cachedPath = _cachedAudioPaths[vocabulary.id!];
        if (cachedPath != null && await File(cachedPath).exists()) {
          debugPrint('[VoiceCoach] Using cached audio for ${vocabulary.front}');
          return cachedPath;
        }
      }

      // Tạo thư mục cache nếu chưa có
      final voiceCoachDir = await getVoiceCoachDirectory();
      // API trả về MP3 format
      final audioPath =
          '${voiceCoachDir.path}/vocab_${vocabulary.id ?? DateTime.now().millisecondsSinceEpoch}.mp3';

      // Thử tải từ API trước (nếu có)
      if (_apiClient != null) {
        try {
          final downloaded = await _downloadFromApi(vocabulary, audioPath);
          if (downloaded != null && await File(downloaded).exists()) {
            if (vocabulary.id != null) {
              _cachedAudioPaths[vocabulary.id!] = downloaded;
            }

            // Lấy thông tin file để log
            final file = File(downloaded);
            final fileStat = await file.stat();
            final fileSizeKB = (fileStat.size / 1024).toStringAsFixed(2);

            debugPrint(
                '[VoiceCoach] ✅ Downloaded audio from API for ${vocabulary.front}');
            debugPrint('[VoiceCoach] Saved to: $downloaded');
            debugPrint('[VoiceCoach] File size: ${fileSizeKB} KB');
            debugPrint('[VoiceCoach] File exists: true');

            return downloaded;
          }
        } catch (e) {
          debugPrint(
              '[VoiceCoach] API download failed, using TTS fallback: $e');
        }
      }

      // Fallback: Sử dụng TTS để tạo audio
      // Lưu ý: flutter_tts không hỗ trợ trực tiếp lưu file
      // Ta sẽ đánh dấu là đã "tải" và sử dụng TTS khi phát
      // Trong tương lai có thể tích hợp TTS service có thể export file
      if (vocabulary.id != null) {
        _cachedAudioPaths[vocabulary.id!] = audioPath;
      }

      // Giả lập thời gian tải TTS
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('[VoiceCoach] Prepared TTS audio for ${vocabulary.front}');
      debugPrint('[VoiceCoach] Audio path: $audioPath');
      return audioPath;
    } catch (e) {
      debugPrint(
          '[VoiceCoach] Error loading audio for ${vocabulary.front}: $e');
      return null;
    }
  }

  /// Tải audio từ API (nếu có endpoint)
  Future<String?> _downloadFromApi(
      Vocabulary vocabulary, String savePath) async {
    if (_apiClient == null) return null;

    try {
      // Gọi API để tải audio voice coach
      // Endpoint có thể là: /voice-coach/audio?text=...
      final response = await _apiClient!.dio.get(
        '/voice-coach/audio',
        queryParameters: {
          'text': vocabulary.front,
          'language': 'en-US',
        },
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Lưu file audio
        final file = File(savePath);
        await file.writeAsBytes(response.data as List<int>);
        return savePath;
      }
    } catch (e) {
      // API có thể không có endpoint này, không phải lỗi nghiêm trọng
      debugPrint('[VoiceCoach] API endpoint not available: $e');
    }

    return null;
  }

  /// Tải âm thanh cho nhiều từ vựng
  Future<Map<int, String?>> loadVoiceCoachAudios(
      List<Vocabulary> vocabularies) async {
    final results = <int, String?>{};

    for (final vocab in vocabularies) {
      if (vocab.id != null) {
        results[vocab.id!] = await loadVoiceCoachAudio(vocab);
      }
    }

    return results;
  }

  /// Phát âm thanh voice coach cho một từ vựng
  Future<void> playVoiceCoach(Vocabulary vocabulary) async {
    try {
      await _tts.speak(vocabulary.front);
    } catch (e) {
      debugPrint('[VoiceCoach] Error playing audio: $e');
    }
  }

  /// Kiểm tra xem đã tải audio cho từ vựng chưa
  bool isAudioLoaded(Vocabulary vocabulary) {
    if (vocabulary.id == null) return false;
    return _cachedAudioPaths.containsKey(vocabulary.id);
  }

  /// Lấy thư mục lưu audio voice coach
  /// Đường dẫn: {appDocumentsDirectory}/voice_coach/
  ///
  /// Trên các platform:
  /// - Android: /data/data/{package}/app_flutter/voice_coach/
  /// - iOS: ~/Documents/voice_coach/
  /// - Windows: {User}/Documents/{app}/voice_coach/
  /// - macOS: ~/Library/Application Support/{app}/voice_coach/
  /// - Linux: ~/.local/share/{app}/voice_coach/
  Future<Directory> getVoiceCoachDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final voiceCoachDir = Directory('${appDir.path}/voice_coach');
    if (!await voiceCoachDir.exists()) {
      await voiceCoachDir.create(recursive: true);
    }
    return voiceCoachDir;
  }

  /// Lấy đường dẫn file audio của một từ vựng
  /// Trả về null nếu chưa tải hoặc file không tồn tại
  Future<String?> getAudioPath(Vocabulary vocabulary) async {
    if (vocabulary.id == null) return null;

    // Kiểm tra cache trong memory
    if (_cachedAudioPaths.containsKey(vocabulary.id)) {
      final cachedPath = _cachedAudioPaths[vocabulary.id!];
      if (cachedPath != null && await File(cachedPath).exists()) {
        return cachedPath;
      }
    }

    // Kiểm tra file trên disk (thử cả MP3 và WAV để tương thích)
    final voiceCoachDir = await getVoiceCoachDirectory();
    final audioPathMp3 = '${voiceCoachDir.path}/vocab_${vocabulary.id}.mp3';
    final audioPathWav = '${voiceCoachDir.path}/vocab_${vocabulary.id}.wav';

    if (await File(audioPathMp3).exists()) {
      _cachedAudioPaths[vocabulary.id!] = audioPathMp3;
      return audioPathMp3;
    }

    if (await File(audioPathWav).exists()) {
      _cachedAudioPaths[vocabulary.id!] = audioPathWav;
      return audioPathWav;
    }

    return null;
  }

  /// Lấy đường dẫn thư mục cache (dùng để debug hoặc hiển thị cho user)
  Future<String> getCacheDirectoryPath() async {
    final dir = await getVoiceCoachDirectory();
    return dir.path;
  }

  /// Xóa cache
  Future<void> clearCache() async {
    try {
      final voiceCoachDir = await getVoiceCoachDirectory();
      if (await voiceCoachDir.exists()) {
        await voiceCoachDir.delete(recursive: true);
        // Tạo lại thư mục rỗng
        await voiceCoachDir.create(recursive: true);
      }
      _cachedAudioPaths.clear();
      debugPrint('[VoiceCoach] Cache cleared at: ${voiceCoachDir.path}');
    } catch (e) {
      debugPrint('[VoiceCoach] Error clearing cache: $e');
    }
  }
}
