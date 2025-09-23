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
  Future<void> reviewWithChoice({
    required int vocabularyId,
    required SrsChoice choice,
    SessionType sessionType = SessionType.review,
    int timeSpentSeconds = 0,
  }) async {
    final vocab = await getVocabularyById(vocabularyId);
    if (vocab == null) return;

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

    double ef = vocab.srsEaseFactor;
    int interval = vocab.srsIntervalDays;
    int reps = vocab.srsRepetitions;
    final bool isFirstLearning = (reps == 0);

    DateTime due;
    if (choice == SrsChoice.again) {
      reps = 0;
      interval = 0;
      ef = (ef + (0.1 - (5 - 1) * (0.08 + (5 - 1) * 0.02))).clamp(1.3, 3.0);
      due = DateTime.now().add(const Duration(minutes: 1));
    } else if (choice == SrsChoice.hard) {
      // lần đầu: 6 phút, các lần sau: tăng nhẹ và giảm EF một chút
      if (reps == 0) {
        due = DateTime.now().add(const Duration(minutes: 6));
        interval = 0;
        reps = 0;
      } else {
        interval = (interval * 1.2).round(); // Hard interval grows slower
        if (interval < 1) interval = 1;
        due = _startOfDay(DateTime.now().add(Duration(days: interval)));
      }
      ef = (ef - 0.15).clamp(1.3, 3.0);
    } else if (choice == SrsChoice.good) {
      if (reps == 0) {
        // lần đầu: 10 phút (vẫn ở trạng thái learning)
        interval = 0;
        reps = 0;
        ef = (ef + 0.05).clamp(1.3, 3.0);
        due = DateTime.now().add(const Duration(minutes: 10));
      } else if (reps == 1) {
        interval = 6;
        reps = reps + 1;
        // EF cập nhật theo quality 4
        ef = (ef + (0.1 - (5 - 4) * (0.08 + (5 - 4) * 0.02))).clamp(1.3, 3.0);
        due = _startOfDay(DateTime.now().add(Duration(days: interval)));
      } else {
        interval = (interval * ef).round();
        if (interval < 1) interval = 1;
        reps = reps + 1;
        // EF cập nhật theo quality 4
        ef = (ef + (0.1 - (5 - 4) * (0.08 + (5 - 4) * 0.02))).clamp(1.3, 3.0);
        due = _startOfDay(DateTime.now().add(Duration(days: interval)));
      }
    } else {
      // easy
      int goodInterval;
      if (reps == 0) {
        goodInterval = 1;
      } else if (reps == 1) {
        goodInterval = 6;
      } else {
        goodInterval = (interval * ef).round();
        if (goodInterval < 1) goodInterval = 1;
      }
      interval = (goodInterval * 1.5).round(); // Easy bonus ~1.5x
      reps = reps + 1;
      ef = (ef + 0.15);
      if (ef < 1.3) ef = 1.3;
      due = _startOfDay(DateTime.now().add(Duration(days: interval)));
    }

    // Không cập nhật due nếu là lựa chọn theo phút
    final bool isMinuteChoice = choice == SrsChoice.again ||
        (isFirstLearning &&
            (choice == SrsChoice.hard || choice == SrsChoice.good));
    if (!isMinuteChoice) {
      await _vocabularyRepository.updateSrsSchedule(
        vocabularyId: vocabularyId,
        easeFactor: ef,
        intervalDays: interval,
        repetitions: reps,
        due: due,
      );
    }

    // Cập nhật mastery_level dựa trên lựa chọn
    int newMasteryLevel = vocab.masteryLevel;
    // Nếu là lần học đầu, các lựa chọn theo phút (Again/Hard/Good) sẽ không tăng mastery
    if (isFirstLearning &&
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
      if (isMinuteChoice) {
        await _vocabularyRepository.updateMasteryLevel(
          vocabularyId,
          newMasteryLevel,
        );
      } else {
        await _vocabularyRepository.updateMasteryLevel(
          vocabularyId,
          newMasteryLevel,
          nextReview: due,
        );
      }
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
    preview.forEach((choice, due) {
      labels[choice] = _intervalLabel(due.difference(DateTime.now()));
    });
    return labels;
  }

  Map<SrsChoice, DateTime> previewChoiceDue(Vocabulary v) {
    final now = DateTime.now();
    final Map<SrsChoice, DateTime> map = {};

    // Again
    map[SrsChoice.again] = now.add(const Duration(minutes: 1));

    // Hard
    if (v.srsRepetitions == 0) {
      map[SrsChoice.hard] = now.add(const Duration(minutes: 6));
    } else {
      final days =
          ((v.srsIntervalDays <= 0 ? 1 : v.srsIntervalDays) * 1.2).round();
      map[SrsChoice.hard] = _startOfDay(now.add(Duration(days: days)));
    }

    // Good
    int goodDays;
    if (v.srsRepetitions == 0) {
      // lần đầu: 10 phút
      map[SrsChoice.good] = now.add(const Duration(minutes: 10));
      goodDays = 1; // dùng để tính Easy phía dưới
    } else if (v.srsRepetitions == 1) {
      goodDays = 6;
    } else {
      final base = v.srsIntervalDays <= 0 ? 1 : v.srsIntervalDays;
      goodDays = (base * v.srsEaseFactor).round();
      if (goodDays < 1) goodDays = 1;
    }
    if (v.srsRepetitions > 0) {
      map[SrsChoice.good] = _startOfDay(now.add(Duration(days: goodDays)));
    }

    // Easy
    final easyDays = (goodDays * 1.5).round();
    map[SrsChoice.easy] = _startOfDay(now.add(Duration(days: easyDays)));

    return map;
  }

  String _intervalLabel(Duration d) {
    if (d.inMinutes < 1) return '<1ph';
    if (d.inMinutes < 60) return '${d.inMinutes}ph';
    if (d.inDays < 1) return '1ng';
    final int days = d.inDays;
    if (days > 30) {
      final double months = days / 30.0;
      final String label = months.toStringAsFixed(1).replaceAll('.', ',');
      return '${label}th';
    }
    return '${days.round()}ng';
  }
}

enum SrsChoice { again, hard, good, easy }
