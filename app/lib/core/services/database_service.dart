import '../database/database_helper.dart';
import '../models/desk.dart';
import '../models/vocabulary.dart';
import '../models/study_session.dart';
import '../repositories/desk_repository.dart';
import '../repositories/vocabulary_repository.dart';
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
  Future<List<Vocabulary>> getVocabulariesForReview(int deskId) =>
      _vocabularyRepository.getVocabulariesForReview(deskId);
  Future<int> updateMasteryLevel(int vocabularyId, int newMasteryLevel,
          {DateTime? nextReview}) =>
      _vocabularyRepository.updateMasteryLevel(vocabularyId, newMasteryLevel,
          nextReview: nextReview);
  Future<List<int>> importVocabularies(List<Vocabulary> vocabularies) =>
      _vocabularyRepository.importVocabularies(vocabularies);

  // Study session operations
  Future<int> createStudySession(StudySession session) =>
      _studySessionRepository.createStudySession(session);
  Future<List<StudySession>> getSessionsByDeskId(int deskId) =>
      _studySessionRepository.getSessionsByDeskId(deskId);
  Future<Map<String, dynamic>> getStudyStats(int deskId,
          {DateTime? startDate, DateTime? endDate}) =>
      _studySessionRepository.getStudyStats(deskId,
          startDate: startDate, endDate: endDate);
  Future<int> getStudyStreak(int deskId) =>
      _studySessionRepository.getStudyStreak(deskId);

  // Utility methods
  Future<void> closeDatabase() => _databaseHelper.close();
  Future<void> deleteDatabase() => _databaseHelper.deleteDatabase();

  // Helper method để tính toán thời gian ôn tập tiếp theo
  DateTime calculateNextReview(int currentMasteryLevel,
      {bool isCorrect = true}) {
    final now = DateTime.now();

    if (!isCorrect) {
      // Nếu trả lời sai, ôn tập lại sau 1 ngày
      return now.add(const Duration(days: 1));
    }

    // Tính toán dựa trên mức độ thành thạo và độ khó
    int daysToAdd;

    if (currentMasteryLevel < 30) {
      daysToAdd = 1; // Ôn tập hàng ngày
    } else if (currentMasteryLevel < 60) {
      daysToAdd = 3; // Ôn tập 3 ngày một lần
    } else if (currentMasteryLevel < 80) {
      daysToAdd = 7; // Ôn tập hàng tuần
    } else {
      daysToAdd = 30; // Ôn tập hàng tháng
    }

    // Điều chỉnh dựa trên độ khó
    daysToAdd = (daysToAdd * (1 + (1 - 1) * 0.2)).round();

    return now.add(Duration(days: daysToAdd));
  }

  // Helper method để cập nhật mức độ thành thạo sau khi học
  Future<void> updateVocabularyAfterStudy(
    int vocabularyId,
    bool isCorrect, {
    int timeSpent = 0,
    SessionType sessionType = SessionType.learn,
  }) async {
    final vocabulary = await getVocabularyById(vocabularyId);
    if (vocabulary == null) return;

    final now = DateTime.now();
    int newMasteryLevel = vocabulary.masteryLevel;

    if (isCorrect) {
      // Tăng mức độ thành thạo
      newMasteryLevel = (vocabulary.masteryLevel + 10).clamp(0, 100);
    } else {
      // Giảm mức độ thành thạo
      newMasteryLevel = (vocabulary.masteryLevel - 5).clamp(0, 100);
    }

    // Tính thời gian ôn tập tiếp theo
    final nextReview =
        calculateNextReview(newMasteryLevel, isCorrect: isCorrect);

    // Cập nhật từ vựng
    await updateMasteryLevel(vocabularyId, newMasteryLevel,
        nextReview: nextReview);

    // Tạo session học
    final session = StudySession(
      deskId: vocabulary.deskId,
      vocabularyId: vocabularyId,
      sessionType: sessionType,
      result: isCorrect ? SessionResult.correct : SessionResult.incorrect,
      timeSpent: timeSpent,
      createdAt: now,
    );

    await createStudySession(session);
  }

  // --- Spaced Repetition (SM-2) helpers ---
  // 4-button choices like Anki: Again, Hard, Good, Easy
  // Use these to both preview due dates and commit a review decision
  // Lưu ý: Các bước "Again" và "Hard" lần học đầu có thể là phút, được lưu vào srs_due theo phút
  // trong khi srs_interval tính theo ngày vẫn có thể bằng 0

  // Các lựa chọn hiển thị trên UI
  // again: <1ph, hard: <10ph (lần đầu) hoặc tăng nhẹ, good: 1ng/6ng/EF*I, easy: >good (x1.5)

  // Enum đại diện nút
  // ignore_for_file: constant_identifier_names

  // Choices
  // again = làm lại ngay; hard = khó; good = được; easy = dễ

  // quality: 0..5 (0 worst, 5 best)
  Future<void> reviewWithSrs({
    required int vocabularyId,
    required int quality,
    SessionType sessionType = SessionType.review,
    int timeSpentSeconds = 0,
  }) async {
    final vocab = await getVocabularyById(vocabularyId);
    if (vocab == null) return;

    // Clamp quality
    final q = quality.clamp(0, 5);

    double ef = vocab.srsEaseFactor; // ease factor
    int interval = vocab.srsIntervalDays; // days
    int reps = vocab.srsRepetitions;

    final bool isLapse = q < 3;
    if (isLapse) {
      // Lapse: reset repetitions, short interval (1 day) similar to Anki default
      reps = 0;
      interval = 1;
    } else {
      // Learning / Review steps
      if (reps == 0) {
        interval = 1; // first good => 1 day
      } else if (reps == 1) {
        interval = 6; // second good => 6 days
      } else {
        interval = (interval * ef).round();
      }
      reps = reps + 1;
    }

    // Update EF per SM-2
    ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)); // SM-2 formula
    if (ef < 1.3) ef = 1.3;

    final due = DateTime.now().add(Duration(days: interval));

    // Persist SRS scheduling
    await _vocabularyRepository.updateSrsSchedule(
      vocabularyId: vocabularyId,
      easeFactor: ef,
      intervalDays: interval,
      repetitions: reps,
      due: due,
    );

    // Also create study session record
    final session = StudySession(
      deskId: vocab.deskId,
      vocabularyId: vocabularyId,
      sessionType: sessionType,
      result: q >= 3 ? SessionResult.correct : SessionResult.incorrect,
      timeSpent: timeSpentSeconds,
      createdAt: DateTime.now(),
    );
    await createStudySession(session);
  }

  // Map 4-nút sang SM-2, với bước học đầu tiên theo phút
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

    DateTime due;
    if (choice == SrsChoice.again) {
      reps = 0;
      interval = 0;
      ef = (ef + (0.1 - (5 - 1) * (0.08 + (5 - 1) * 0.02))).clamp(1.3, 3.0);
      due = DateTime.now().add(const Duration(minutes: 1));
    } else if (choice == SrsChoice.hard) {
      // lần đầu: 10 phút, các lần sau: tăng nhẹ và giảm EF một chút
      if (reps == 0) {
        due = DateTime.now().add(const Duration(minutes: 10));
        interval = 0;
        reps = 0;
      } else {
        interval = (interval * 1.2).round(); // Hard interval grows slower
        if (interval < 1) interval = 1;
        due = DateTime.now().add(Duration(days: interval));
      }
      ef = (ef - 0.15).clamp(1.3, 3.0);
    } else if (choice == SrsChoice.good) {
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 6;
      } else {
        interval = (interval * ef).round();
        if (interval < 1) interval = 1;
      }
      reps = reps + 1;
      // EF cập nhật theo quality 4
      ef = ef + (0.1 - (5 - 4) * (0.08 + (5 - 4) * 0.02));
      if (ef < 1.3) ef = 1.3;
      due = DateTime.now().add(Duration(days: interval));
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
      due = DateTime.now().add(Duration(days: interval));
    }

    await _vocabularyRepository.updateSrsSchedule(
      vocabularyId: vocabularyId,
      easeFactor: ef,
      intervalDays: interval,
      repetitions: reps,
      due: due,
    );

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
    return _vocabularyRepository.getVocabulariesForReview(deskId, limit: limit);
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
      map[SrsChoice.hard] = now.add(const Duration(minutes: 10));
    } else {
      final days =
          ((v.srsIntervalDays <= 0 ? 1 : v.srsIntervalDays) * 1.2).round();
      map[SrsChoice.hard] = now.add(Duration(days: days));
    }

    // Good
    int goodDays;
    if (v.srsRepetitions == 0) {
      goodDays = 1;
    } else if (v.srsRepetitions == 1) {
      goodDays = 6;
    } else {
      final base = v.srsIntervalDays <= 0 ? 1 : v.srsIntervalDays;
      goodDays = (base * v.srsEaseFactor).round();
      if (goodDays < 1) goodDays = 1;
    }
    map[SrsChoice.good] = now.add(Duration(days: goodDays));

    // Easy
    final easyDays = (goodDays * 1.5).round();
    map[SrsChoice.easy] = now.add(Duration(days: easyDays));

    return map;
  }

  String _intervalLabel(Duration d) {
    if (d.inMinutes < 1) return '<1ph';
    if (d.inMinutes < 10) return '<10ph';
    if (d.inDays < 1) return '${d.inHours}h';
    if (d.inDays == 1) return '1ng';
    return '${d.inDays}ng';
  }
}

enum SrsChoice { again, hard, good, easy }
