import '../../../core/models/vocabulary.dart';
import 'package:flutter/material.dart';
import '../repositories/vocabulary_repository.dart';

class VocabularyService extends ChangeNotifier {
  final VocabularyRepository _vocabularyRepository = VocabularyRepository();

  Future<int> createVocabulary(Vocabulary vocabulary) =>
      _vocabularyRepository.createVocabulary(vocabulary);
  // Primary deck-first API
  Future<List<Vocabulary>> getVocabulariesByDeckId(int deckId) =>
      _vocabularyRepository.getVocabulariesByDeskId(deckId);
  Future<Vocabulary?> getVocabularyById(int id) =>
      _vocabularyRepository.getVocabularyById(id);
  Future<int> updateVocabulary(Vocabulary vocabulary) =>
      _vocabularyRepository.updateVocabulary(vocabulary);
  Future<int> deleteVocabulary(int id) =>
      _vocabularyRepository.deleteVocabulary(id);
  Future<List<Vocabulary>> getVocabulariesForStudyByDeck(int deckId) =>
      _vocabularyRepository.getVocabulariesForStudy(deckId);
  Future<int> updateMasteryLevel(int vocabularyId, int newMasteryLevel,
          {DateTime? nextReview}) =>
      _vocabularyRepository.updateMasteryLevel(vocabularyId, newMasteryLevel,
          nextReview: nextReview);
  Future<int> countMinuteLearningByDeck(int deckId) =>
      _vocabularyRepository.countMinuteLearning(deckId);
  Future<int> countNewByDeck(int deckId) =>
      _vocabularyRepository.countNewVocabularies(deckId);
  Future<Map<DateTime, int>> getDueCountsByDateRange({
    DateTime? start,
    DateTime? end,
    int? deckId,
    int? deskId, // legacy param name supported for compatibility
  }) async {
    final now = DateTime.now();
    final DateTime s = start ?? DateTime(now.year, now.month - 3, now.day);
    final DateTime e = end ?? DateTime(now.year, now.month, now.day);
    final int? effectiveDeckId = deckId ?? deskId;
    return _vocabularyRepository.getDueCountsByDateRange(
        start: s, end: e, deskId: effectiveDeckId);
  }

  // Legacy aliases (desk) — prefer deck-named methods above
  @deprecated
  Future<List<Vocabulary>> getVocabulariesByDeskId(int deskId) =>
      getVocabulariesByDeckId(deskId);
  @deprecated
  Future<List<Vocabulary>> getVocabulariesForStudy(int deskId) =>
      getVocabulariesForStudyByDeck(deskId);
  @deprecated
  Future<int> countMinuteLearningByDesk(int deskId) =>
      countMinuteLearningByDeck(deskId);
  @deprecated
  Future<int> countNewByDesk(int deskId) => countNewByDeck(deskId);
}
