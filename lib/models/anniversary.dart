/// 纪念日模型
class Anniversary {
  final String id;
  final String coupleId;
  final String title;
  final DateTime date;
  final bool isLunar;
  final List<int> remindDays;
  final String icon;

  Anniversary({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.date,
    this.isLunar = false,
    this.remindDays = const [1, 3, 7],
    required this.icon,
  });

  factory Anniversary.fromMap(Map<String, dynamic> map) {
    return Anniversary(
      id: map['objectId'] as String,
      coupleId: map['couple_id'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      isLunar: (map['is_lunar'] as bool?) ?? false,
      remindDays: List<int>.from((map['remind_days'] as List?) ?? [1, 3, 7]),
      icon: map['icon'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'couple_id': coupleId,
      'title': title,
      'date': date.toIso8601String(),
      'is_lunar': isLunar,
      'remind_days': remindDays,
      'icon': icon,
    };
  }

  /// 距离下一个纪念日的天数
  int get daysUntilNext {
    final now = DateTime.now();
    var nextDate = DateTime(now.year, date.month, date.day);
    if (nextDate.isBefore(now)) {
      nextDate = DateTime(now.year + 1, date.month, date.day);
    }
    return nextDate.difference(now).inDays;
  }
}
