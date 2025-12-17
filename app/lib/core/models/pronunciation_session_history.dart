class PronunciationSessionHistory {
  final int? id;
  final int? deckId;
  final String deckName;
  final int totalWords;
  final int practicedWords;
  final double avgOverall;
  final double avgAccuracy;
  final double avgFluency;
  final double avgCompleteness;
  final int highCount;
  final int lowCount;
  final DateTime createdAt;

  const PronunciationSessionHistory({
    this.id,
    required this.deckId,
    required this.deckName,
    required this.totalWords,
    required this.practicedWords,
    required this.avgOverall,
    required this.avgAccuracy,
    required this.avgFluency,
    required this.avgCompleteness,
    required this.highCount,
    required this.lowCount,
    required this.createdAt,
  });

  factory PronunciationSessionHistory.fromMap(Map<String, dynamic> map) {
    return PronunciationSessionHistory(
      id: map['id'] as int?,
      deckId: map['deck_id'] as int?,
      deckName: map['deck_name'] as String? ?? 'Unknown deck',
      totalWords: map['total_words'] as int? ?? 0,
      practicedWords: map['practiced_words'] as int? ?? 0,
      avgOverall: (map['avg_overall'] as num?)?.toDouble() ?? 0,
      avgAccuracy: (map['avg_accuracy'] as num?)?.toDouble() ?? 0,
      avgFluency: (map['avg_fluency'] as num?)?.toDouble() ?? 0,
      avgCompleteness: (map['avg_completeness'] as num?)?.toDouble() ?? 0,
      highCount: map['high_count'] as int? ?? 0,
      lowCount: map['low_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'deck_name': deckName,
      'total_words': totalWords,
      'practiced_words': practicedWords,
      'avg_overall': avgOverall,
      'avg_accuracy': avgAccuracy,
      'avg_fluency': avgFluency,
      'avg_completeness': avgCompleteness,
      'high_count': highCount,
      'low_count': lowCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
