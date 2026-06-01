/// 照片模型
class Photo {
  final String id;
  final String coupleId;
  final String imageUrl;
  final String? thumbnailUrl;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final List<String> tags;
  final DateTime takenAt;
  final DateTime createdAt;
  final String? diaryId;

  Photo({
    required this.id,
    required this.coupleId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    this.tags = const [],
    required this.takenAt,
    required this.createdAt,
    this.diaryId,
  });

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['objectId'] as String,
      coupleId: map['couple_id'] as String,
      imageUrl: map['image_url'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      locationName: map['location_name'] as String?,
      tags: List<String>.from((map['tags'] as List?) ?? []),
      takenAt: DateTime.parse(map['taken_at'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      diaryId: map['diary_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'couple_id': coupleId,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'tags': tags,
      'taken_at': takenAt.toIso8601String(),
      'diary_id': diaryId,
    };
  }
}
