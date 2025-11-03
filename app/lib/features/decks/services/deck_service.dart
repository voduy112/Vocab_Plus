import 'package:flutter/material.dart';
import '../../../core/models/deck.dart';
import '../repositories/deck_repository.dart';

class DeckService extends ChangeNotifier {
  final DeckRepository _deckRepository = DeckRepository();

  Future<int> createDeck(Deck deck) => _deckRepository.createDeck(deck);
  Future<List<Deck>> getAllDecks() => _deckRepository.getAllDecks();
  Future<Deck?> getDeckById(int id) => _deckRepository.getDeckById(id);
  Future<int> updateDeck(Deck deck) => _deckRepository.updateDeck(deck);
  Future<int> deleteDeck(int id) => _deckRepository.deleteDeck(id);
  Future<List<Deck>> searchDecks(String query) =>
      _deckRepository.searchDecks(query);
  Future<Map<String, dynamic>> getDeckStats(int deckId) =>
      _deckRepository.getDeckStats(deckId);
}
