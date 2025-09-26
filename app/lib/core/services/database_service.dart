import '../database/database_helper.dart';
import '../models/desk.dart';
import '../models/vocabulary.dart';
import '../models/study_session.dart';
import '../../features/desks/repositories/desk_repository.dart';
import '../../features/desks/repositories/vocabulary_repository.dart';
import '../../features/study_session/repositories/study_session_repository.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final DeskRepository _deskRepository = DeskRepository();
  final VocabularyRepository _vocabularyRepository = VocabularyRepository();
  final StudySessionRepository _studySessionRepository =
      StudySessionRepository();

  // Desk operations
  Future<int> createDesk(Desk desk) => _deskRepository.createDesk(desk);
  Future<List<Desk>> getAllDesks() => _deskRepository.getAllDesks();
  Future<Desk?> getDeskById(int id) => _deskRepository.getDeskById(id);
  Future<int> updateDesk(Desk desk) => _deskRepository.updateDesk(desk);
  Future<int> deleteDesk(int id) => _deskRepository.deleteDesk(id);
  Future<List<Desk>> searchDesks(String query) =>
      _deskRepository.searchDesks(query);
  Future<Map<String, dynamic>> getDeskStats(int deskId) =>
      _deskRepository.getDeskStats(deskId);

  // Vocabulary operations
  Future<int> createVocabulary(Vocabulary vocabulary) =>
      _vocabularyRepository.createVocabulary(vocabulary);
  Future<List<Vocabulary>> getVocabulariesByDeskId(int deskId) =>
      _vocabularyRepository.getVocabulariesByDeskId(deskId);
  Future<Vocabulary?> getVocabularyById(int id) =>
      _vocabularyRepository.getVocabularyById(id);
  Future<int> updateVocabulary(Vocabulary vocabulary) =>
      _vocabularyRepository.updateVocabulary(vocabulary);
  Future<int> deleteVocabulary(int id) =>
      _vocabularyRepository.deleteVocabulary(id);
  Future<List<Vocabulary>> searchVocabularies(int deskId, String query) =>
      _vocabularyRepository.searchVocabularies(deskId, query);
  Future<List<Vocabulary>> getVocabulariesForStudy(int deskId) =>
      _vocabularyRepository.getVocabulariesForStudy(deskId);
  Future<int> updateMasteryLevel(int vocabularyId, int newMasteryLevel,
          {DateTime? nextReview}) =>
      _vocabularyRepository.updateMasteryLevel(vocabularyId, newMasteryLevel,
          nextReview: nextReview);

  // Study session operations
  Future<int> createStudySession(StudySession session) =>
      _studySessionRepository.createStudySession(session);
  Future<List<StudySession>> getSessionsByDeskId(int deskId) =>
      _studySessionRepository.getSessionsByDeskId(deskId);

  // Utility methods
  Future<void> closeDatabase() => _databaseHelper.close();
  Future<void> deleteDatabase() => _databaseHelper.deleteDatabase();

  // --- Spaced Repetition helpers ---
  // Map 4-nút sang SM-2, với bước học đầu tiên theo phút
  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // Helper: xác định step hiện tại cho learning theo srs_left (b phần nghìn)
  int _currentLearningStep(int srsLeft, int srsRepetitions) {
    if (srsRepetitions == 0) return 1; // mới => bước 1
    final int remainder = srsLeft % 1000;
    if (remainder == 2) return 2;
    if (remainder == 1) return 3; // day-learning
    return 1; // fallback
  }

  // Mô phỏng lịch SRS khi chọn 1 nút. Trả về map chứa các trường cập nhật.
  Map<String, dynamic> _simulateSrs(Vocabulary vocab, SrsChoice choice,
      {DateTime? nowOverride}) {
    final DateTime now = nowOverride ?? DateTime.now();

    double ef = vocab.srsEaseFactor;
    int interval = vocab.srsIntervalDays;
    int reps = vocab.srsRepetitions;
    int lapses = vocab.srsLapses;
    int left = vocab.srsLeft;
    int srsType = vocab.srsType; // 0=new, 1=learning, 2=review
    int srsQueue = vocab.srsQueue; // 0=new, 1=learning, 2=review

    final bool isLearning = (srsType == 0 || srsType == 1 || reps == 0);
    DateTime due;
    bool dueIsMinutes = false;

    if (isLearning) {
      // 3-step program: 1m (LRN), 10m (LRN), 1d (DLN)
      final int step = _currentLearningStep(left, reps);
      srsType = 1;
      srsQueue = 1;
      interval = 0;
      reps = reps + 1;

      if (step == 1) {
        if (choice == SrsChoice.again) {
          due = now.add(const Duration(minutes: 1));
          dueIsMinutes = true;
          left = 1000 + 3; // reset về bước 1 (còn 3 bước)
        } else if (choice == SrsChoice.hard) {
          due = now.add(const Duration(minutes: 6)); // TB(1m,10m)≈6m
          dueIsMinutes = true;
          left = 1000 + 3; // vẫn còn đủ 3 bước để tốt nghiệp
        } else if (choice == SrsChoice.good) {
          due = now.add(const Duration(minutes: 10));
          dueIsMinutes = true;
          left = 1000 + 2; // sang bước 2
        } else {
          // Easy: tốt nghiệp ngay sang review với easy interval 4d
          srsType = 2;
          srsQueue = 2;
          interval = 4;
          due = _startOfDay(now.add(Duration(days: interval)));
          left = 0;
        }
      } else if (step == 2) {
        if (choice == SrsChoice.again) {
          due = now.add(const Duration(minutes: 1));
          dueIsMinutes = true;
          left = 1000 + 3; // reset về bước 1
        } else if (choice == SrsChoice.hard) {
          due = now.add(const Duration(minutes: 8)); // lặp lại bước 2 (8 phút)
          dueIsMinutes = true;
          left = 1000 + 2;
        } else if (choice == SrsChoice.good) {
          // Chọn "ngày" tại bước 2: tốt nghiệp ngay sang review với graduating interval = 1d
          srsType = 2;
          srsQueue = 2;
          interval = 1;
          due = _startOfDay(now.add(Duration(days: interval)));
          dueIsMinutes = false;
          left = 0;
        } else {
          // Easy: tốt nghiệp ngay
          srsType = 2;
          srsQueue = 2;
          interval = 4;
          due = _startOfDay(now.add(Duration(days: interval)));
          dueIsMinutes = false;
          left = 0;
        }
      } else {
        // step 3 (day-learning 1d)
        if (choice == SrsChoice.again) {
          due = now.add(const Duration(minutes: 1));
          dueIsMinutes = true;
          left = 1000 + 3; // reset về bước 1
        } else if (choice == SrsChoice.hard) {
          due =
              _startOfDay(now.add(const Duration(days: 1))); // lặp lại day step
          dueIsMinutes = false;
          left = 1000 + 1;
        } else if (choice == SrsChoice.good) {
          // tốt nghiệp với graduating interval = 1d
          srsType = 2;
          srsQueue = 2;
          interval = 1;
          due = _startOfDay(now.add(Duration(days: interval)));
          dueIsMinutes = false;
          left = 0;
        } else {
          // Easy: tốt nghiệp với easy interval = 4d
          srsType = 2;
          srsQueue = 2;
          interval = 4;
          due = _startOfDay(now.add(Duration(days: interval)));
          dueIsMinutes = false;
          left = 0;
        }
      }
    } else {
      // Review (SM-2 style EF updates and interval scaling)
      int q;
      switch (choice) {
        case SrsChoice.again:
          q = 1;
          break;
        case SrsChoice.hard:
          q = 3;
          break;
        case SrsChoice.good:
          q = 4;
          break;
        case SrsChoice.easy:
          q = 5;
          break;
      }

      // Update EF per SM-2 formula and clamp
      ef = (ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))).clamp(1.3, 3.0);

      if (choice == SrsChoice.again) {
        // Lapse -> relearn
        lapses = lapses + 1;
        srsType = 1;
        srsQueue = 1;
        interval = 0;
        due = now.add(const Duration(minutes: 1));
        dueIsMinutes = true;
        reps = reps + 1;
        left = 1000 + 2; // relearn hai bước (1m -> 10m) trước khi day step
      } else if (choice == SrsChoice.hard) {
        // If previous interval is invalid/zero, seed a distinct base interval
        if (interval < 1) {
          interval = 1;
        } else {
          interval = (interval * 1.2).round();
          if (interval < 1) interval = 1;
        }
        due = _startOfDay(now.add(Duration(days: interval)));
        dueIsMinutes = false;
        reps = reps + 1;
      } else if (choice == SrsChoice.good) {
        if (interval < 1) {
          interval = 2;
        } else {
          interval = (interval * ef).round();
          if (interval < 1) interval = 1;
        }
        due = _startOfDay(now.add(Duration(days: interval)));
        dueIsMinutes = false;
        reps = reps + 1;
      } else {
        // easy
        if (interval < 1) {
          interval = 4;
        } else {
          int goodInterval = (interval * ef).round();
          if (goodInterval < 1) goodInterval = 1;
          interval = (goodInterval * 1.3).round();
        }
        if (interval < 1) interval = 1;
        due = _startOfDay(now.add(Duration(days: interval)));
        dueIsMinutes = false;
        reps = reps + 1;
      }
      srsType = (choice == SrsChoice.again) ? 1 : 2;
      srsQueue = (choice == SrsChoice.again) ? 1 : 2;
    }

    return {
      'ef': ef,
      'interval': interval,
      'reps': reps,
      'lapses': lapses,
      'left': left,
      'srsType': srsType,
      'srsQueue': srsQueue,
      'due': due,
      'dueIsMinutes': dueIsMinutes,
    };
  }

  Future<Map<String, dynamic>> reviewWithChoice({
    required int vocabularyId,
    required SrsChoice choice,
    SessionType sessionType = SessionType.review,
    int timeSpentSeconds = 0,
  }) async {
    final vocab = await getVocabularyById(vocabularyId);
    if (vocab == null) return {'srsType': -1, 'dueIsMinutes': false};

    // Mặc định map sang quality
    int quality;
    switch (choice) {
      case SrsChoice.again:
        quality = 1; // rất tệ
        break;
      case SrsChoice.hard:
        quality = 3; // khó
        break;
      case SrsChoice.good:
        quality = 4; // được
        break;
      case SrsChoice.easy:
        quality = 5; // dễ
        break;
    }

    final sim = _simulateSrs(vocab, choice);
    final double ef = sim['ef'] as double;
    final int interval = sim['interval'] as int;
    final int reps = sim['reps'] as int;
    final int lapses = sim['lapses'] as int;
    final int left = sim['left'] as int;
    final int srsType = sim['srsType'] as int;
    final int srsQueue = sim['srsQueue'] as int;
    final DateTime computedDue = sim['due'] as DateTime;
    final bool isMinuteInterval = (sim['dueIsMinutes'] as bool?) ?? false;
    // Minute choices must not change due at all (even if null)
    final DateTime? selectedDue = isMinuteInterval ? vocab.srsDue : computedDue;

    print('due: $selectedDue');
    print('srsType: $srsType');
    print('srsQueue: $srsQueue');
    print('lapses: $lapses');
    print('left: $left');
    print('ef: $ef');
    print('interval: $interval');
    print('reps: $reps');
    print('quality: $quality');
    print('timeSpentSeconds: $timeSpentSeconds');
    print('sessionType: $sessionType');
    print('vocabularyId: $vocabularyId');
    print('choice: $choice');
    print('vocab: $vocab');

    await _vocabularyRepository.updateSrsSchedule(
      vocabularyId: vocabularyId,
      easeFactor: ef,
      intervalDays: interval,
      repetitions: reps,
      due: selectedDue,
      srsType: srsType,
      srsQueue: srsQueue,
      srsLapses: lapses,
      srsLeft: left,
    );

    // Cập nhật mastery_level dựa trên lựa chọn
    int newMasteryLevel = vocab.masteryLevel;
    // Trong learning/relearning, Again/Hard/Good không tăng mastery
    if (srsType == 1 &&
        (choice == SrsChoice.again ||
            choice == SrsChoice.hard ||
            choice == SrsChoice.good)) {
      newMasteryLevel = vocab.masteryLevel;
    } else {
      if (choice == SrsChoice.easy) {
        // Dễ: tăng mastery_level đáng kể
        newMasteryLevel = (vocab.masteryLevel + 25).clamp(0, 100);
      } else if (choice == SrsChoice.good) {
        // Tốt: tăng mastery_level vừa phải
        newMasteryLevel = (vocab.masteryLevel + 15).clamp(0, 100);
      } else if (choice == SrsChoice.hard) {
        // Khó: tăng mastery_level ít
        newMasteryLevel = (vocab.masteryLevel + 5).clamp(0, 100);
      }
      // Again: không tăng mastery_level
    }

    // Cập nhật mastery_level nếu có thay đổi
    if (newMasteryLevel != vocab.masteryLevel) {
      await _vocabularyRepository.updateMasteryLevel(
        vocabularyId,
        newMasteryLevel,
        nextReview: srsType == 2 ? selectedDue : null,
      );
    }

    final session = StudySession(
      deskId: vocab.deskId,
      vocabularyId: vocabularyId,
      sessionType: sessionType,
      result: quality >= 3 ? SessionResult.correct : SessionResult.incorrect,
      timeSpent: timeSpentSeconds,
      createdAt: DateTime.now(),
    );
    await createStudySession(session);
    print('srsType: $srsType');
    // Trả về srsType và cờ dueIsMinutes để UI quyết định hàng đợi ngay lập tức
    return {
      'srsType': srsType,
      'dueIsMinutes': isMinuteInterval,
    };
  }

  // --- Queue helpers for today ---
  Future<List<Vocabulary>> getTodayDueVocabularies(int deskId, {int? limit}) {
    return _vocabularyRepository.getVocabulariesForStudy(deskId);
  }

  Future<Map<String, int>> getTodayQueueCounts(int deskId) async {
    final allDue = await getTodayDueVocabularies(deskId);
    int learning = 0;
    int review = 0;
    for (final v in allDue) {
      if (v.srsRepetitions == 0) {
        learning += 1;
      } else {
        review += 1;
      }
    }
    return {
      'learning': learning,
      'review': review,
      'total': allDue.length,
    };
  }

  // Preview label cho 4 nút theo thuật toán hiện tại
  Map<SrsChoice, String> previewChoiceLabels(Vocabulary vocab) {
    final preview = previewChoiceDue(vocab);
    final labels = <SrsChoice, String>{};
    final int step = _currentLearningStep(vocab.srsLeft, vocab.srsRepetitions);
    final bool isLearningState =
        (vocab.srsType == 0 || vocab.srsType == 1 || vocab.srsRepetitions == 0);
    preview.forEach((choice, due) {
      final Duration delta = due.difference(DateTime.now());
      if (isLearningState && delta.inMinutes > 0 && delta.inMinutes < 60) {
        // Chuẩn hoá nhãn phút cho toàn bộ trạng thái learning/relearning
        switch (choice) {
          case SrsChoice.again:
            labels[choice] = '1ph';
            break;
          case SrsChoice.hard:
            labels[choice] = (step == 2) ? '8ph' : '6ph';
            break;
          case SrsChoice.good:
            labels[choice] = (step == 1) ? '10ph' : '1ng';
            break;
          case SrsChoice.easy:
            labels[choice] = '4ng';
            break;
        }
      } else {
        labels[choice] = _intervalLabel(delta);
      }
    });
    return labels;
  }

  Map<SrsChoice, DateTime> previewChoiceDue(Vocabulary v) {
    final Map<SrsChoice, DateTime> map = {};

    for (final choice in SrsChoice.values) {
      final sim = _simulateSrs(v, choice);
      map[choice] = sim['due'] as DateTime;
    }

    return map;
  }

  String _intervalLabel(Duration d) {
    if (d.inMinutes < 1) return '<1ph';
    if (d.inMinutes < 60) {
      final int minutesCeil = (d.inSeconds / 60).ceil();
      return '${minutesCeil}ph';
    }
    if (d.inDays < 1) return '1ng';
    final int daysCeil = (d.inHours / 24).ceil();
    if (daysCeil > 30) {
      final double monthsCeil = ((daysCeil / 30.0) * 10).ceil() / 10.0;
      final String label = monthsCeil.toStringAsFixed(1).replaceAll('.', ',');
      return '${label}th';
    }
    return '${daysCeil}ng';
  }
}

enum SrsChoice { again, hard, good, easy }
