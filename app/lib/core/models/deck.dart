class Deck {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isFavorite;

  Deck({
    this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isFavorite = false,
  });

  // Chuyển đổi từ Map (từ database) sang Desk object
  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isActive: map['is_active'] == 1,
      isFavorite: (map['is_favorite'] ?? 0) == 1,
    );
  }

  // Chuyển đổi từ Desk object sang Map (để lưu vào database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  // Tạo bản copy với các thay đổi
  Deck copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isFavorite,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() {
    return 'Deck(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Deck &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isActive.hashCode ^
        isFavorite.hashCode;
  }
}
