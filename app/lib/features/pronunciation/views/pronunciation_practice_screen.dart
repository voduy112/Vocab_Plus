import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/models/deck.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/models/pronunciation_result.dart';
import '../../../core/api/api_client.dart';
import '../../decks/services/vocabulary_service.dart';
import '../services/pronunciation_service.dart';
import '../services/voice_coach_service.dart';
import '../widgets/pronunciation_app_bar.dart';
import '../widgets/pronunciation_empty_state.dart';
import '../widgets/pronunciation_navigation_bar.dart';
import '../widgets/pronunciation_practice_body.dart';
import '../widgets/pronunciation_details_bottom_sheet.dart';
import '../utils/wav_info_reader.dart';

class PronunciationPracticeScreen extends StatefulWidget {
  final Deck deck;

  const PronunciationPracticeScreen({
    super.key,
    required this.deck,
  });

  @override
  State<PronunciationPracticeScreen> createState() =>
      _PronunciationPracticeScreenState();
}

class _PronunciationPracticeScreenState
    extends State<PronunciationPracticeScreen> {
  final VocabularyService _vocabularyService = VocabularyService();
  final AudioRecorder _recorder = AudioRecorder();
  late final PronunciationService _pronunciationService;
  late final VoiceCoachService _voiceCoachService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingVoiceCoach = false;
  bool _isLoadingAudio = false;

  List<Vocabulary> _vocabularies = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isEvaluating = false;
  bool _hasResult = false;
  PronunciationResult? _result;
  bool _showConfetti = false;
  Timer? _confettiTimer;
  int? _recordStartedAtMs;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  int? _lastSoundDetectedAtMs;
  bool _isAutoStopping = false; // Flag to prevent multiple auto-stop calls
  double? _peakAmplitude; // Mức amplitude cao nhất đã phát hiện
  static const double _absoluteSilenceThreshold =
      -50.0; // Ngưỡng tuyệt đối (dB)
  static const double _relativeSilenceDropDb =
      15.0; // Coi là silence nếu amplitude giảm ít nhất 15 dB so với peak
  static const double _minPeakAmplitude =
      -35.0; // Mức amplitude tối thiểu để coi là có âm thanh thực sự
  static const int _silenceDurationMs =
      1000; // 2 seconds of silence to auto-stop
  static const int _minRecordingDurationMs =
      1000; // Minimum 1 second before auto-stop

  @override
  void initState() {
    super.initState();
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://192.168.88.209:3000',
    );
    final apiClient = ApiClient(apiBaseUrl);
    _pronunciationService = PronunciationService(apiClient);
    _voiceCoachService = VoiceCoachService(apiClient: apiClient);
    _initializeRecorder();
    _loadVocabularies();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingVoiceCoach = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _confettiTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('[Pronun] Microphone permission denied');
        return;
      }

      if (await _recorder.hasPermission()) {
        debugPrint('[Pronun] Recorder initialized');
      } else {
        debugPrint('[Pronun] Microphone permission not granted');
      }
    } catch (e) {
      debugPrint('[Pronun][ERROR] _initializeRecorder: $e');
    }
  }

  Future<void> _loadVocabularies() async {
    if (widget.deck.id == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final vocabularies =
          await _vocabularyService.getVocabulariesByDeckId(widget.deck.id!);
      setState(() {
        _vocabularies = vocabularies.where((v) => v.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải từ vựng: $e')),
        );
      }
    }
  }

  Vocabulary? get _currentVocabulary {
    if (_currentIndex < 0 || _currentIndex >= _vocabularies.length) {
      return null;
    }
    return _vocabularies[_currentIndex];
  }

  bool get _isHighScore => _hasResult && ((_result?.overall ?? 0) >= 80);
  bool get _isLowScore => _hasResult && ((_result?.overall ?? 0) < 60);

  Future<void> _startRecording() async {
    try {
      // Kiểm tra permission
      if (!await _recorder.hasPermission()) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cần quyền ghi âm')),
            );
          }
          return;
        }
      }

      // Kiểm tra xem recorder có đang recording không
      if (await _recorder.isRecording()) {
        debugPrint('[Pronun] Already recording, stopping first');
        await _recorder.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _cancelConfetti();

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Cấu hình để ghi WAV 16kHz mono PCM
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      );

      debugPrint('[Pronun] Starting recorder with config: WAV 16kHz mono');
      await _recorder.start(config, path: path);

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _isRecording = true;
        _hasResult = false;
        _result = null;
        _recordStartedAtMs = nowMs;
        _lastSoundDetectedAtMs = nowMs;
        _isAutoStopping = false;
      });

      // Bắt đầu theo dõi amplitude để phát hiện silence
      _startAmplitudeMonitoring();

      debugPrint('[Pronun] Recording started: WAV 16kHz mono PCM at $path');
    } catch (e) {
      debugPrint('[Pronun][ERROR] _startRecording: $e');
      if (mounted) {
        String errorMessage = 'Lỗi khi bắt đầu ghi âm';
        if (e.toString().contains('MissingPluginException')) {
          errorMessage = 'Plugin ghi âm chưa được khởi tạo. Vui lòng:\n'
              '1. Dừng app hoàn toàn\n'
              '2. Chạy: flutter clean && flutter pub get\n'
              '3. Rebuild app (không dùng hot reload)';
        } else {
          errorMessage = 'Lỗi khi bắt đầu ghi âm: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSubscription?.cancel();
    _isAutoStopping = false;
    _peakAmplitude = null;
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(
      const Duration(milliseconds: 100),
    )
        .listen(
      (amplitude) {
        if (!_isRecording || _isAutoStopping) return;

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final currentAmplitude = amplitude.current;

        // Cập nhật peak amplitude nếu có âm thanh đủ lớn
        if (currentAmplitude > _minPeakAmplitude) {
          if (_peakAmplitude == null || currentAmplitude > _peakAmplitude!) {
            _peakAmplitude = currentAmplitude;
          }
        }

        // Kiểm tra xem có phải silence không
        final isSilence = _isSilence(currentAmplitude);

        if (!isSilence) {
          // Có âm thanh
          _lastSoundDetectedAtMs = nowMs;
          debugPrint(
              '[Pronun][AutoStop] Sound: ${currentAmplitude.toStringAsFixed(1)} dB (peak: ${_peakAmplitude?.toStringAsFixed(1) ?? "N/A"})');
        } else {
          // Im lặng - kiểm tra xem đã im lặng đủ lâu chưa
          final silenceDuration = _lastSoundDetectedAtMs != null
              ? nowMs - _lastSoundDetectedAtMs!
              : 0;
          final recordingDuration =
              _recordStartedAtMs != null ? nowMs - _recordStartedAtMs! : 0;

          debugPrint(
              '[Pronun][AutoStop] Silence: ${currentAmplitude.toStringAsFixed(1)} dB (duration: ${silenceDuration}ms, peak: ${_peakAmplitude?.toStringAsFixed(1) ?? "N/A"})');

          // Chỉ auto-stop nếu:
          // 1. Đã ghi âm ít nhất _minRecordingDurationMs
          // 2. Đã im lặng ít nhất _silenceDurationMs
          // 3. Đã có peak amplitude (đã từng có âm thanh thực sự)
          // 4. Chưa đang trong quá trình auto-stop
          if (recordingDuration >= _minRecordingDurationMs &&
              silenceDuration >= _silenceDurationMs &&
              _peakAmplitude != null &&
              !_isAutoStopping) {
            debugPrint(
                '[Pronun][AutoStop] Auto-stopping after ${silenceDuration}ms of silence');
            _isAutoStopping = true;
            _stopRecording();
          }
        }
      },
      onError: (error) {
        debugPrint(
            '[Pronun][AutoStop][ERROR] Amplitude monitoring error: $error');
      },
    );
  }

  bool _isSilence(double currentAmplitude) {
    // Kiểm tra ngưỡng tuyệt đối
    if (currentAmplitude <= _absoluteSilenceThreshold) {
      return true;
    }

    // Kiểm tra ngưỡng tương đối (so với peak)
    // Nếu đã có peak amplitude đủ lớn, coi là silence nếu amplitude giảm đáng kể
    if (_peakAmplitude != null && _peakAmplitude! > _minPeakAmplitude) {
      final amplitudeDrop = _peakAmplitude! - currentAmplitude;
      // Nếu amplitude giảm ít nhất _relativeSilenceDropDb so với peak
      if (amplitudeDrop >= _relativeSilenceDropDb) {
        return true;
      }
    }

    return false;
  }

  Future<void> _stopRecording() async {
    try {
      // Dừng theo dõi amplitude
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final startedMs = _recordStartedAtMs ?? nowMs;
      final durationMs = nowMs - startedMs;

      const minDurationMs = 700;
      if (durationMs < minDurationMs) {
        debugPrint('[Pronun] Stop ignored: too short (${durationMs}ms)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bản ghi quá ngắn, vui lòng thử lại')),
          );
        }
        setState(() {
          _isRecording = false;
          _recordStartedAtMs = null;
          _lastSoundDetectedAtMs = null;
          _isAutoStopping = false;
          _peakAmplitude = null;
        });
        return;
      }

      final path = await _recorder.stop();
      debugPrint('[Pronun] Stop recording. File: $path (~${durationMs}ms)');

      // Cho encoder/IO có thời gian ghi nốt và sửa header
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _isRecording = false;
        _recordStartedAtMs = null;
        _lastSoundDetectedAtMs = null;
        _isAutoStopping = false;
        _peakAmplitude = null;
      });

      if (path == null) return;

      final file = File(path);

      // Retry đọc info vài lần để đảm bảo header đã finalize
      const tries = 4;
      int attempt = 0;
      Map<String, dynamic>? info;
      while (attempt < tries) {
        info = await WavInfoReader.readWavInfo(file);
        final totalLen = info['totalLen'] as int? ?? 0;
        final payloadBytes = totalLen > 44 ? totalLen - 44 : 0;

        final dataSize = info['dataSize'] as int?;
        final durationMsFromPayload = info['durationMsFromPayload'] as int?;
        final durationMsFromData = info['durationMsFromData'] as int?;

        debugPrint('[Pronun] attempt#$attempt '
            'payloadBytes=$payloadBytes dataSize=$dataSize '
            'durPayload=${durationMsFromPayload}ms durData=${durationMsFromData}ms');

        if (payloadBytes > 0 || (dataSize != null && dataSize > 0)) break;

        await Future.delayed(const Duration(milliseconds: 120));
        attempt++;
      }

      final stat = await file.stat();
      final size = stat.size;
      debugPrint('[Pronun] Recorded file info: '
          'path=$path, size=${size} bytes, modified=${stat.modified.toIso8601String()}');

      if (size <= 44) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không thu được âm thanh. Kiểm tra quyền micro hoặc thử trên thiết bị thật.',
              ),
            ),
          );
        }
        try {
          await file.delete();
        } catch (_) {}
        return;
      }

      if (size < 2000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Âm thanh quá ngắn hoặc không hợp lệ, vui lòng ghi lại'),
            ),
          );
        }
        try {
          await file.delete();
        } catch (_) {}
        return;
      }

      await _evaluatePronunciation(file);
    } catch (e) {
      debugPrint('[Pronun][ERROR] _stopRecording: $e');
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi dừng ghi âm: $e')),
        );
      }
    }
  }

  Future<void> _handleVoiceCoach() async {
    final vocabulary = _currentVocabulary;
    if (vocabulary == null) return;

    // Nếu đang phát, dừng lại
    if (_isPlayingVoiceCoach) {
      await _audioPlayer.stop();
      return;
    }

    try {
      // Kiểm tra xem audio đã tải chưa
      final audioPath = await _voiceCoachService.getAudioPath(vocabulary);

      if (audioPath != null && await File(audioPath).exists()) {
        // Phát audio từ file đã lưu
        await _audioPlayer.play(DeviceFileSource(audioPath));
      } else {
        // Nếu chưa có file, thử tải hoặc dùng TTS
        setState(() {
          _isLoadingAudio = true;
        });

        // Tải audio
        final loadedPath =
            await _voiceCoachService.loadVoiceCoachAudio(vocabulary);

        if (mounted) {
          setState(() {
            _isLoadingAudio = false;
          });
        }

        if (loadedPath != null && await File(loadedPath).exists()) {
          // Phát audio từ file vừa tải
          await _audioPlayer.play(DeviceFileSource(loadedPath));
        } else {
          // Fallback: Sử dụng TTS để phát trực tiếp
          await _voiceCoachService.playVoiceCoach(vocabulary);
        }
      }
    } catch (e) {
      debugPrint('[VoiceCoach] Error playing audio: $e');
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi phát audio: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleRepeat() {
    if (_isRecording || _isEvaluating) return;
    _cancelConfetti();
    setState(() {
      _hasResult = false;
      _result = null;
    });
  }

  Future<void> _evaluatePronunciation(File audioFile) async {
    final vocabulary = _currentVocabulary;
    if (vocabulary == null) return;

    setState(() {
      _isEvaluating = true;
    });

    try {
      final fileSize = await audioFile.length();
      final fileStat = await audioFile.stat();

      debugPrint('[Pronun] ========== Starting Evaluation ==========');
      debugPrint('[Pronun] Audio File: ${audioFile.path}');
      debugPrint(
          '[Pronun] File Size: ${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)');
      debugPrint('[Pronun] Modified: ${fileStat.modified}');
      debugPrint('[Pronun] Reference Text: "${vocabulary.front}"');
      debugPrint('[Pronun] Language Code: en-US');
      debugPrint('[Pronun] Sending request to API...');

      final result = await _pronunciationService.assessPronunciation(
        audioFile: audioFile,
        referenceText: vocabulary.front,
        languageCode: 'en-US',
      );

      debugPrint('[Pronun] Received response from API');

      final isHighScore = result.overall >= 80;

      setState(() {
        _result = result;
        _hasResult = true;
        _isEvaluating = false;
        _showConfetti = isHighScore;
      });

      if (isHighScore) {
        _startConfettiCountdown();
      } else {
        _confettiTimer?.cancel();
        _confettiTimer = null;
      }

      // Log tổng quan
      debugPrint('[Pronun] ========== Evaluation Results ==========');
      debugPrint(
          '[Pronun] Overall Score: ${result.overall.toStringAsFixed(1)}/100');
      debugPrint(
          '[Pronun] Accuracy: ${result.accuracy.toStringAsFixed(1)}/100');
      debugPrint('[Pronun] Fluency: ${result.fluency.toStringAsFixed(1)}/100');
      debugPrint(
          '[Pronun] Completeness: ${result.completeness.toStringAsFixed(1)}/100');
      debugPrint(
          '[Pronun] Total Words: ${result.words.length}, Total Phonemes: ${result.phonemes.length}');
      debugPrint('[Pronun] =========================================');

      // Log chi tiết từng từ và âm vị
      for (int wi = 0; wi < result.words.length; wi++) {
        final word = result.words[wi];
        final wordPhonemes =
            result.phonemes.where((p) => p.wordIndex == wi).toList();

        debugPrint('[Pronun] --- Word $wi: "${word.text}" ---');
        debugPrint('[Pronun]   Score: ${word.score.toStringAsFixed(1)}/100');
        debugPrint(
            '[Pronun]   Timing: ${word.start}ms - ${word.end}ms (duration: ${word.end - word.start}ms)');
        debugPrint('[Pronun]   Phonemes (${wordPhonemes.length}):');

        for (int pi = 0; pi < wordPhonemes.length; pi++) {
          final phoneme = wordPhonemes[pi];
          final scoreColor = phoneme.score >= 80
              ? '🟢'
              : phoneme.score >= 60
                  ? '🟡'
                  : '🔴';

          debugPrint('[Pronun]     [$pi] $scoreColor ${phoneme.p}: '
              '${phoneme.score.toStringAsFixed(1)}/100 '
              '[${phoneme.start}ms - ${phoneme.end}ms, '
              'duration: ${phoneme.end - phoneme.start}ms]');
        }
        debugPrint('[Pronun] ');
      }

      debugPrint('[Pronun] =========================================');
    } catch (e) {
      debugPrint('[Pronun][ERROR] _evaluatePronunciation: $e');
      if (mounted) {
        setState(() => _isEvaluating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đánh giá: $e')),
        );
      }
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _nextVocabulary() {
    if (_currentIndex < _vocabularies.length - 1) {
      _cancelConfetti();
      setState(() {
        _currentIndex++;
        _hasResult = false;
        _result = null;
      });
    }
  }

  void _previousVocabulary() {
    if (_currentIndex > 0) {
      _cancelConfetti();
      setState(() {
        _currentIndex--;
        _hasResult = false;
        _result = null;
      });
    }
  }

  void _startConfettiCountdown() {
    _confettiTimer?.cancel();
    _confettiTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _showConfetti = false);
      }
    });
  }

  void _cancelConfetti() {
    _confettiTimer?.cancel();
    _confettiTimer = null;
    if (_showConfetti) {
      setState(() => _showConfetti = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vocabulary = _currentVocabulary;
    final hasEvaluated = _hasResult && _result != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      appBar: PronunciationAppBar(
        currentExercise: _currentIndex + 1,
        deckName: widget.deck.name,
        onBack: () => context.pop(),
        onDownloadTap: () {
          context.push('/pronunciation/voice-coach-loading',
              extra: widget.deck);
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vocabularies.isEmpty
              ? const PronunciationEmptyState()
              : (vocabulary == null
                  ? const SizedBox()
                  : PronunciationPracticeBody(
                      vocabulary: vocabulary,
                      currentExercise: _currentIndex + 1,
                      totalExercises: _vocabularies.length,
                      isHighScore: _isHighScore,
                      isLowScore: _isLowScore,
                      hasResult: hasEvaluated,
                      statusMessage: _statusMessage(),
                      isRecording: _isRecording,
                      isEvaluating: _isEvaluating,
                      showConfetti: _showConfetti,
                      isLoadingAudio: _isLoadingAudio,
                      onVoiceCoach: _handleVoiceCoach,
                      onRepeat: _handleRepeat,
                      onStartRecording: _startRecording,
                      onStopRecording: _stopRecording,
                      onShowDetails: _showDetailsBottomSheet,
                    )),
      bottomNavigationBar: _isLoading || _vocabularies.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: PronunciationNavigationBar(
                  hasPrevious: _currentIndex > 0,
                  hasNext: _currentIndex < _vocabularies.length - 1,
                  onPrevious: _previousVocabulary,
                  onNext: _nextVocabulary,
                ),
              ),
            ),
    );
  }

  void _showDetailsBottomSheet() {
    if (!_hasResult || _result == null) return;
    PronunciationDetailsBottomSheet.show(
      context,
      result: _result!,
      currentExerciseIndex: _currentIndex,
      colorResolver: _getScoreColor,
      isPhonemeCorrect: _isPhonemeCorrect,
    );
  }

  String _statusMessage() {
    if (_isEvaluating) return 'Đang chấm điểm...';
    if (_isRecording) return 'Đang nghe bạn nói';
    if (_hasResult && _result != null) {
      if (_result!.overall >= 80) return 'Tuyệt vời!';
      if (_result!.overall >= 60) return 'Gần đến rồi!';
      return 'Thử lại!';
    }
    return 'Bắt đầu nói';
  }

  bool _isPhonemeCorrect(double score) => score >= 70;
}
