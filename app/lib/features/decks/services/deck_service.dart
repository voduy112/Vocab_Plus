import 'package:flutter/material.dart';
import '../../../core/models/deck.dart';
import '../repositories/deck_repository.dart';

class DeckService extends ChangeNotifier {
  final DeckRepository _deskRepository = DeckRepository();

  Future<int> createDesk(Deck desk) => _deskRepository.createDesk(desk);
  Future<List<Deck>> getAllDesks() => _deskRepository.getAllDesks();
  Future<Deck?> getDeskById(int id) => _deskRepository.getDeskById(id);
  Future<int> updateDesk(Deck desk) => _deskRepository.updateDesk(desk);
  Future<int> deleteDesk(int id) => _deskRepository.deleteDesk(id);
  Future<List<Deck>> searchDesks(String query) =>
      _deskRepository.searchDesks(query);
  Future<Map<String, dynamic>> getDeskStats(int deskId) =>
      _deskRepository.getDeskStats(deskId);
}
