/// A photograph shared in a private birthday event gallery.
class BirthdaySharedPhoto {
  final String id;
  final String eventId;
  final String? uploaderId;
  final String uploaderName;
  final String uploaderRole; // 'host', 'guest', 'photographer', 'admin'
  final String imageUrl;
  final String? storagePath;
  final String caption;
  final int likesCount;
  final DateTime createdAt;

  const BirthdaySharedPhoto({
    required this.id,
    required this.eventId,
    this.uploaderId,
    required this.uploaderName,
    this.uploaderRole = 'guest',
    required this.imageUrl,
    this.storagePath,
    this.caption = '',
    this.likesCount = 0,
    required this.createdAt,
  });

  factory BirthdaySharedPhoto.fromJson(Map<String, dynamic> json) {
    return BirthdaySharedPhoto(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      uploaderId: json['uploader_id'] as String?,
      uploaderName: json['uploader_name'] as String? ?? 'Guest',
      uploaderRole: json['uploader_role'] as String? ?? 'guest',
      imageUrl: json['image_url'] as String? ?? '',
      storagePath: json['storage_path'] as String?,
      caption: json['caption'] as String? ?? '',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_id': eventId,
        'uploader_id': uploaderId,
        'uploader_name': uploaderName,
        'uploader_role': uploaderRole,
        'image_url': imageUrl,
        'storage_path': storagePath,
        'caption': caption,
        'likes_count': likesCount,
        'created_at': createdAt.toIso8601String(),
      };
}
