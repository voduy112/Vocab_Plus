import '../../../core/database/database_helper.dart';
import '../../../core/models/study_session.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/models/srs_choice.dart';
import '../services/srs_service.dart';
import '../../decks/repositories/vocabulary_repository.dart';

class StudySessionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final VocabularyRepository _vocabularyRepository = VocabularyRepository();
  final SrsService _srsService = SrsService();

  // Tạo session học mới
  Future<int> createStudySession(StudySession session) async {
    final db = await _databaseHelper.database;
    return await db.insert('study_sessions', session.toMap());
  }

  // Lấy tất cả sessions của một deck
  Future<List<StudySession>> getSessionsByDeskId(int deskId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'deck_id = ?',
      whereArgs: [deskId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return StudySession.fromMap(maps[i]);
    });
  }

  // Xem nhãn preview cho các lựa chọn SRS
  Map<SrsChoice, String> previewChoiceLabels(Vocabulary vocab) {
    return _srsService.previewChoiceLabels(vocab);
  }

  // Lấy từ vựng theo ID
  Future<Vocabulary?> getVocabularyById(int id) {
    return _vocabularyRepository.getVocabularyById(id);
  }

  // Ôn tập với lựa chọn (di chuyển từ Service sang Repository như feature desks)
  Future<Map<String, dynamic>> reviewWithChoice({
    required int vocabularyId,
    required SrsChoice choice,
    SessionType sessionType = SessionType.review,
    int timeSpentSeconds = 0,
  }) async {
    final vocab = await getVocabularyById(vocabularyId);
    if (vocab == null) return {'srsType': -1, 'dueIsMinutes': false};

    int quality;
    switch (choice) {
      case SrsChoice.again:
        quality = 1;
        break;
      case SrsChoice.hard:
        quality = 3;
        break;
      case SrsChoice.good:
        quality = 4;
        break;
      case SrsChoice.easy:
        quality = 5;
        break;
    }

    final sim = _srsService.simulateSrs(vocab, choice);
    final double ef = sim['ef'] as double;
    final int interval = sim['interval'] as int;
    final int reps = sim['reps'] as int;
    final int lapses = sim['lapses'] as int;
    final int left = sim['left'] as int;
    final int srsType = sim['srsType'] as int;
    final int srsQueue = sim['srsQueue'] as int;
    final DateTime computedDue = sim['due'] as DateTime;
    final bool isMinuteInterval = (sim['dueIsMinutes'] as bool?) ?? false;
    final DateTime? selectedDue = isMinuteInterval ? vocab.srsDue : computedDue;

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

    int newMasteryLevel = vocab.masteryLevel;
    if (srsType == 1 &&
        (choice == SrsChoice.again ||
            choice == SrsChoice.hard ||
            choice == SrsChoice.good)) {
      newMasteryLevel = vocab.masteryLevel;
    } else {
      if (choice == SrsChoice.easy) {
        newMasteryLevel = (vocab.masteryLevel + 25).clamp(0, 100);
      } else if (choice == SrsChoice.good) {
        newMasteryLevel = (vocab.masteryLevel + 15).clamp(0, 100);
      } else if (choice == SrsChoice.hard) {
        newMasteryLevel = (vocab.masteryLevel + 5).clamp(0, 100);
      }
    }

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

    return {
      'srsType': srsType,
      'dueIsMinutes': isMinuteInterval,
    };
  }
}
