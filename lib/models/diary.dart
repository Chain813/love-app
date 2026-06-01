/// 日记模型
class Diary {
  final String id;
  final String coupleId;
  final String? title;
  final String content;
  final List<String> images;
  final String? videoUrl;
  final String weather;
  final String weatherText;
  final String mood;
  final String moodText;
  final List<String> tags;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String authorId;
  final String? lastEditorId;
  final DateTime diaryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Diary({
    required this.id,
    required this.coupleId,
    this.title,
    required this.content,
    this.images = const [],
    this.videoUrl,
    this.weather = '☀️',
    this.weatherText = '晴天',
    this.mood = '😊',
    this.moodText = '开心',
    this.tags = const [],
    this.locationName,
    this.latitude,
    this.longitude,
    required this.authorId,
    this.lastEditorId,
    required this.diaryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['objectId'] as String,
      coupleId: map['couple_id'] as String,
      title: map['title'] as String?,
      content: map['content'] as String,
      images: List<String>.from((map['images'] as List?) ?? []),
      videoUrl: map['video_url'] as String?,
      weather: (map['weather'] as String?) ?? '☀️',
      weatherText: (map['weather_text'] as String?) ?? '晴天',
      mood: (map['mood'] as String?) ?? '😊',
      moodText: (map['mood_text'] as String?) ?? '开心',
      tags: List<String>.from((map['tags'] as List?) ?? []),
      locationName: map['location_name'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      authorId: map['author_id'] as String,
      lastEditorId: map['last_editor_id'] as String?,
      diaryDate: DateTime.parse(map['diary_date'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'couple_id': coupleId,
      'title': title,
      'content': content,
      'images': images,
      'video_url': videoUrl,
      'weather': weather,
      'weather_text': weatherText,
      'mood': mood,
      'mood_text': moodText,
      'tags': tags,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'author_id': authorId,
      'last_editor_id': lastEditorId,
      'diary_date': diaryDate.toIso8601String(),
    };
  }
}
