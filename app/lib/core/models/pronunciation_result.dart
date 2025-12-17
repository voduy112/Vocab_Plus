// Models for pronunciation assessment result
class PronunciationResult {
  final double overall;
  final double accuracy;
  final double fluency;
  final double completeness;
  final List<WordResult> words;
  final List<PhonemeResult> phonemes;
  final List<Mispronunciation> mispronunciations;
  final List<String> feedback;

  PronunciationResult({
    required this.overall,
    required this.accuracy,
    required this.fluency,
    required this.completeness,
    required this.words,
    required this.phonemes,
    required this.mispronunciations,
    required this.feedback,
  });

  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    return PronunciationResult(
      overall: (json['overall'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      fluency: (json['fluency'] as num).toDouble(),
      completeness: (json['completeness'] as num).toDouble(),
      words: (json['words'] as List<dynamic>)
          .map((w) => WordResult.fromJson(w))
          .toList(),
      phonemes: (json['phonemes'] as List<dynamic>)
          .map((p) => PhonemeResult.fromJson(p))
          .toList(),
      mispronunciations: (json['mispronunciations'] as List<dynamic>?)
              ?.map((m) => Mispronunciation.fromJson(m))
              .toList() ??
          [],
      feedback: (json['feedback'] as List<dynamic>?)
              ?.map((f) => f.toString())
              .toList() ??
          [],
    );
  }
}

class WordResult {
  final String text;
  final int start;
  final int end;
  final double score;

  WordResult({
    required this.text,
    required this.start,
    required this.end,
    required this.score,
  });

  factory WordResult.fromJson(Map<String, dynamic> json) {
    return WordResult(
      text: json['text'] as String,
      start: json['start'] as int,
      end: json['end'] as int,
      score: (json['score'] as num).toDouble(),
    );
  }
}

class PhonemeResult {
  final int wordIndex;
  final String p;
  final int start;
  final int end;
  final double score;

  PhonemeResult({
    required this.wordIndex,
    required this.p,
    required this.start,
    required this.end,
    required this.score,
  });

  factory PhonemeResult.fromJson(Map<String, dynamic> json) {
    return PhonemeResult(
      wordIndex: json['wordIndex'] as int,
      p: json['p'] as String,
      start: json['start'] as int,
      end: json['end'] as int,
      score: (json['score'] as num).toDouble(),
    );
  }
}

class Mispronunciation {
  final String word;
  final String expected;
  final String observed;

  Mispronunciation({
    required this.word,
    required this.expected,
    required this.observed,
  });

  factory Mispronunciation.fromJson(Map<String, dynamic> json) {
    return Mispronunciation(
      word: json['word'] as String,
      expected: json['expected'] as String,
      observed: json['observed'] as String,
    );
  }
}

