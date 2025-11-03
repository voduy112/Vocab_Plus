import '../../../core/models/vocabulary.dart';
import 'package:flutter/material.dart';
import '../repositories/vocabulary_repository.dart';

class VocabularyService extends ChangeNotifier {
  final VocabularyRepository _vocabularyRepository = VocabularyRepository();

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
  Future<List<Vocabulary>> getVocabulariesForStudy(int deskId) =>
      _vocabularyRepository.getVocabulariesForStudy(deskId);
  Future<int> updateMasteryLevel(int vocabularyId, int newMasteryLevel,
          {DateTime? nextReview}) =>
      _vocabularyRepository.updateMasteryLevel(vocabularyId, newMasteryLevel,
          nextReview: nextReview);
  Future<int> countMinuteLearningByDesk(int deskId) =>
      _vocabularyRepository.countMinuteLearning(deskId);
  Future<int> countNewByDesk(int deskId) =>
      _vocabularyRepository.countNewVocabularies(deskId);
  Future<Map<DateTime, int>> getDueCountsByDateRange(
      {DateTime? start, DateTime? end, int? deskId}) async {
    final now = DateTime.now();
    final DateTime s = start ?? DateTime(now.year, now.month - 3, now.day);
    final DateTime e = end ?? DateTime(now.year, now.month, now.day);
    return _vocabularyRepository.getDueCountsByDateRange(
        start: s, end: e, deskId: deskId);
  }
}
