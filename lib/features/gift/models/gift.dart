/// 礼物模型 — 积分赠礼系统
///
/// 情侣双方可上架礼物，对方用积分兑换。
/// 积分通过完成「心诺」任务获得。
class Gift {
  final String id;
  final String coupleId;
  final String title;
  final String description;
  final int points;
  final String icon;
  final String createdBy;
  final String? redeemedBy;
  final DateTime? redeemedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Gift({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description = '',
    required this.points,
    this.icon = '🎁',
    required this.createdBy,
    this.redeemedBy,
    this.redeemedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRedeemed => redeemedBy != null;

  Map<String, dynamic> toJson() => {
        'objectId': id,
        'couple_id': coupleId,
        'title': title,
        'description': description,
        'points': points,
        'icon': icon,
        'created_by': createdBy,
        'redeemed_by': redeemedBy,
        'redeemed_at': redeemedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Gift.fromJson(Map<String, dynamic> json) => Gift(
        id: json['objectId']?.toString() ?? '',
        coupleId: json['couple_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
        icon: json['icon']?.toString() ?? '🎁',
        createdBy: json['created_by']?.toString() ?? '',
        redeemedBy: json['redeemed_by']?.toString(),
        redeemedAt: json['redeemed_at'] != null
            ? DateTime.tryParse(json['redeemed_at'].toString())
            : null,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );

  Gift copyWith({
    String? redeemedBy,
    DateTime? redeemedAt,
  }) =>
      Gift(
        id: id,
        coupleId: coupleId,
        title: title,
        description: description,
        points: points,
        icon: icon,
        createdBy: createdBy,
        redeemedBy: redeemedBy ?? this.redeemedBy,
        redeemedAt: redeemedAt ?? this.redeemedAt,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
