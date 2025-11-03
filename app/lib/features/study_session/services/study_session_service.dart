import '../../../core/models/study_session.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/models/srs_choice.dart';
import '../repositories/study_session_repository.dart';

class StudySessionService {
  final StudySessionRepository _studySessionRepository =
      StudySessionRepository();

  Map<SrsChoice, String> previewChoiceLabels(Vocabulary vocab) {
    return _studySessionRepository.previewChoiceLabels(vocab);
  }

  Future<Vocabulary?> getVocabularyById(int id) {
    return _studySessionRepository.getVocabularyById(id);
  }

  Future<Map<String, dynamic>> reviewWithChoice({
    required int vocabularyId,
    required SrsChoice choice,
    SessionType sessionType = SessionType.review,
    int timeSpentSeconds = 0,
  }) {
    return _studySessionRepository.reviewWithChoice(
      vocabularyId: vocabularyId,
      choice: choice,
      sessionType: sessionType,
      timeSpentSeconds: timeSpentSeconds,
    );
  }
}
