enum CardType { basis, reverse, typing }

class Vocabulary {
  final int? id;
  final int deskId;
  final String front;
  final String back;
  // Image fields
  final String? imageUrl; // remote url (e.g., Pixabay)
  final String? imagePath; // local cached file path
  // Back side images (optional). For backward compatibility, front side uses imageUrl/imagePath
  final String? backImageUrl;
  final String? backImagePath;
  // Extra dynamic fields per face (key -> value)
  final Map<String, String>? frontExtra;
  final Map<String, String>? backExtra;
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
  final CardType cardType;

  Vocabulary({
    this.id,
    required this.deskId,
    required this.front,
    required this.back,
    this.imageUrl,
    this.imagePath,
    this.backImageUrl,
    this.backImagePath,
    this.frontExtra,
    this.backExtra,
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
    this.cardType = CardType.basis,
  });

  // Chuyển đổi từ Map (từ database) sang Vocabulary object
  factory Vocabulary.fromMap(Map<String, dynamic> map) {
    final String cardTypeRaw = (map['card_type'] ?? 'basis').toString();
    final CardType parsedCardType = CardType.values.firstWhere(
      (e) => e.toString().split('.').last == cardTypeRaw,
      orElse: () => CardType.basis,
    );
    return Vocabulary(
      id: map['id'],
      deskId: map['deck_id'],
      front: map['front'],
      back: map['back'],
      imageUrl: map['image_url'],
      imagePath: map['image_path'],
      backImageUrl: map['back_image_url'],
      backImagePath: map['back_image_path'],
      frontExtra: map['front_extra_json'] != null &&
              (map['front_extra_json'] as String).isNotEmpty
          ? {
              for (final pair in (map['front_extra_json'] as String)
                  .split('||')
                  .where((e) => e.contains('=')))
                pair.split('=')[0]: pair.split('=')[1]
            }
          : null,
      backExtra: map['back_extra_json'] != null &&
              (map['back_extra_json'] as String).isNotEmpty
          ? {
              for (final pair in (map['back_extra_json'] as String)
                  .split('||')
                  .where((e) => e.contains('=')))
                pair.split('=')[0]: pair.split('=')[1]
            }
          : null,
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
      cardType: parsedCardType,
    );
  }

  // Chuyển đổi từ Vocabulary object sang Map (để lưu vào database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deskId,
      'front': front,
      'back': back,
      'image_url': imageUrl,
      'image_path': imagePath,
      'back_image_url': backImageUrl,
      'back_image_path': backImagePath,
      'front_extra_json': frontExtra == null
          ? null
          : frontExtra!.entries.map((e) => '${e.key}=${e.value}').join('||'),
      'back_extra_json': backExtra == null
          ? null
          : backExtra!.entries.map((e) => '${e.key}=${e.value}').join('||'),
      'mastery_level': masteryLevel,
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
      'card_type': cardType.toString().split('.').last,
    };
  }

  // Tạo bản copy với các thay đổi
  Vocabulary copyWith({
    int? id,
    int? deskId,
    String? front,
    String? back,
    String? imageUrl,
    String? imagePath,
    String? backImageUrl,
    String? backImagePath,
    Map<String, String>? frontExtra,
    Map<String, String>? backExtra,
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
    CardType? cardType,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      deskId: deskId ?? this.deskId,
      front: front ?? this.front,
      back: back ?? this.back,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      backImageUrl: backImageUrl ?? this.backImageUrl,
      backImagePath: backImagePath ?? this.backImagePath,
      frontExtra: frontExtra ?? this.frontExtra,
      backExtra: backExtra ?? this.backExtra,
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
      cardType: cardType ?? this.cardType,
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
    return 'Vocabulary(id: $id, deskId: $deskId, cardType: $cardType, front: $front, back: $back, masteryLevel: $masteryLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vocabulary &&
        other.id == id &&
        other.deskId == deskId &&
        other.front == front &&
        other.back == back &&
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
        other.isActive == isActive &&
        other.cardType == cardType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        deskId.hashCode ^
        front.hashCode ^
        back.hashCode ^
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
        isActive.hashCode ^
        cardType.hashCode;
  }
}
