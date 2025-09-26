class Vocabulary {
  final int? id;
  final int deskId;
  final String word;
  final String meaning;
  final String? pronunciation;
  final String? example;
  final String? translation;
  final int masteryLevel; // 0-100 (0: chưa học, 100: thuộc lòng)
  final int reviewCount;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  // SRS (SM-2)
  final double srsEaseFactor; // EF
  final int srsIntervalDays; // I (days)
  final int srsRepetitions; // repetitions count
  final DateTime? srsDue; // due date
  // Anki-like scheduler state
  final int srsType; // 0=new, 1=learning, 2=review
  final int srsQueue; // 0=new, 1=learning, 2=review
  final int srsLapses; // review again count
  final int srsLeft; // learning steps counter
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Vocabulary({
    this.id,
    required this.deskId,
    required this.word,
    required this.meaning,
    this.pronunciation,
    this.example,
    this.translation,
    this.masteryLevel = 0,
    this.reviewCount = 0,
    this.lastReviewed,
    this.nextReview,
    this.srsEaseFactor = 2.5,
    this.srsIntervalDays = 0,
    this.srsRepetitions = 0,
    this.srsDue,
    this.srsType = 0,
    this.srsQueue = 0,
    this.srsLapses = 0,
    this.srsLeft = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Chuyển đổi từ Map (từ database) sang Vocabulary object
  factory Vocabulary.fromMap(Map<String, dynamic> map) {
    return Vocabulary(
      id: map['id'],
      deskId: map['desk_id'],
      word: map['word'],
      meaning: map['meaning'],
      pronunciation: map['pronunciation'],
      example: map['example'],
      translation: map['translation'],
      masteryLevel: map['mastery_level'] ?? 0,
      reviewCount: map['review_count'] ?? 0,
      lastReviewed: map['last_reviewed'] != null
          ? DateTime.parse(map['last_reviewed'])
          : null,
      nextReview: map['next_review'] != null
          ? DateTime.parse(map['next_review'])
          : null,
      srsEaseFactor: (map['srs_ease_factor'] as num?)?.toDouble() ?? 2.5,
      srsIntervalDays: map['srs_interval'] ?? 0,
      srsRepetitions: map['srs_repetitions'] ?? 0,
      srsDue: map['srs_due'] != null ? DateTime.parse(map['srs_due']) : null,
      srsType: map['srs_type'] ?? 0,
      srsQueue: map['srs_queue'] ?? 0,
      srsLapses: map['srs_lapses'] ?? 0,
      srsLeft: map['srs_left'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isActive: map['is_active'] == 1,
    );
  }

  // Chuyển đổi từ Vocabulary object sang Map (để lưu vào database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'desk_id': deskId,
      'word': word,
      'meaning': meaning,
      'pronunciation': pronunciation,
      'example': example,
      'translation': translation,
      'mastery_level': masteryLevel,
      'review_count': reviewCount,
      'last_reviewed': lastReviewed?.toIso8601String(),
      'next_review': nextReview?.toIso8601String(),
      'srs_ease_factor': srsEaseFactor,
      'srs_interval': srsIntervalDays,
      'srs_repetitions': srsRepetitions,
      'srs_due': srsDue?.toIso8601String(),
      'srs_type': srsType,
      'srs_queue': srsQueue,
      'srs_lapses': srsLapses,
      'srs_left': srsLeft,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  // Tạo bản copy với các thay đổi
  Vocabulary copyWith({
    int? id,
    int? deskId,
    String? word,
    String? meaning,
    String? pronunciation,
    String? example,
    String? translation,
    int? masteryLevel,
    int? reviewCount,
    DateTime? lastReviewed,
    DateTime? nextReview,
    double? srsEaseFactor,
    int? srsIntervalDays,
    int? srsRepetitions,
    DateTime? srsDue,
    int? srsType,
    int? srsQueue,
    int? srsLapses,
    int? srsLeft,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      deskId: deskId ?? this.deskId,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      pronunciation: pronunciation ?? this.pronunciation,
      example: example ?? this.example,
      translation: translation ?? this.translation,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      srsEaseFactor: srsEaseFactor ?? this.srsEaseFactor,
      srsIntervalDays: srsIntervalDays ?? this.srsIntervalDays,
      srsRepetitions: srsRepetitions ?? this.srsRepetitions,
      srsDue: srsDue ?? this.srsDue,
      srsType: srsType ?? this.srsType,
      srsQueue: srsQueue ?? this.srsQueue,
      srsLapses: srsLapses ?? this.srsLapses,
      srsLeft: srsLeft ?? this.srsLeft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Tính toán mức độ thành thạo dựa trên số lần ôn tập
  double get progressPercentage => masteryLevel / 100.0;

  // Kiểm tra xem từ có cần ôn tập không
  bool get needsReview {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }

  // Lấy màu sắc dựa trên mức độ thành thạo
  String get progressColor {
    if (masteryLevel < 30) return '#F44336'; // Đỏ
    if (masteryLevel < 60) return '#FF9800'; // Cam
    if (masteryLevel < 80) return '#FFEB3B'; // Vàng
    return '#4CAF50'; // Xanh lá
  }

  @override
  String toString() {
    return 'Vocabulary(id: $id, deskId: $deskId, word: $word, meaning: $meaning, masteryLevel: $masteryLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vocabulary &&
        other.id == id &&
        other.deskId == deskId &&
        other.word == word &&
        other.meaning == meaning &&
        other.pronunciation == pronunciation &&
        other.example == example &&
        other.translation == translation &&
        other.masteryLevel == masteryLevel &&
        other.reviewCount == reviewCount &&
        other.lastReviewed == lastReviewed &&
        other.nextReview == nextReview &&
        other.srsEaseFactor == srsEaseFactor &&
        other.srsIntervalDays == srsIntervalDays &&
        other.srsRepetitions == srsRepetitions &&
        other.srsDue == srsDue &&
        other.srsType == srsType &&
        other.srsQueue == srsQueue &&
        other.srsLapses == srsLapses &&
        other.srsLeft == srsLeft &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        deskId.hashCode ^
        word.hashCode ^
        meaning.hashCode ^
        pronunciation.hashCode ^
        example.hashCode ^
        translation.hashCode ^
        masteryLevel.hashCode ^
        reviewCount.hashCode ^
        lastReviewed.hashCode ^
        nextReview.hashCode ^
        srsEaseFactor.hashCode ^
        srsIntervalDays.hashCode ^
        srsRepetitions.hashCode ^
        srsDue.hashCode ^
        srsType.hashCode ^
        srsQueue.hashCode ^
        srsLapses.hashCode ^
        srsLeft.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isActive.hashCode;
  }
}
