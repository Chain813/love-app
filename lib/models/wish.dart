/// 心愿模型
class Wish {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? completedAt;
  final String createdBy;

  Wish({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.completedAt,
    required this.createdBy,
  });

  factory Wish.fromMap(Map<String, dynamic> map) {
    return Wish(
      id: map['objectId'] as String,
      coupleId: map['couple_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as bool?) ?? false,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdBy: map['created_by'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'couple_id': coupleId,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Wish copyWith({
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Wish(
      id: id,
      coupleId: coupleId,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy,
    );
  }
}
