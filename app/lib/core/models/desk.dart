class Desk {
  final int? id;
  final String name;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Desk({
    this.id,
    required this.name,
    this.color = '#2196F3',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Chuyển đổi từ Map (từ database) sang Desk object
  factory Desk.fromMap(Map<String, dynamic> map) {
    return Desk(
      id: map['id'],
      name: map['name'],
      color: map['color'] ?? '#2196F3',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isActive: map['is_active'] == 1,
    );
  }

  // Chuyển đổi từ Desk object sang Map (để lưu vào database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  // Tạo bản copy với các thay đổi
  Desk copyWith({
    int? id,
    String? name,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Desk(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Desk(id: $id, name: $name, color: $color, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Desk &&
        other.id == id &&
        other.name == name &&
        other.color == color &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        color.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isActive.hashCode;
  }
}
