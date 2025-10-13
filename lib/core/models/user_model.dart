import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? avatar;
  
  @HiveField(3)
  final String? bannerImage;
  
  @HiveField(4)
  final String? about;
  
  @HiveField(5)
  final DateTime? createdAt;
  
  @HiveField(6)
  final DateTime? updatedAt;
  
  @HiveField(7)
  final bool displayAdultContent;

  UserModel({
    required this.id,
    required this.name,
    this.avatar,
    this.bannerImage,
    this.about,
    this.createdAt,
    this.updatedAt,
    this.displayAdultContent = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar']?['large'] as String?,
      bannerImage: json['bannerImage'] as String?,
      about: json['about'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] * 1000)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] * 1000)
          : null,
      displayAdultContent: json['options']?['displayAdultContent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'bannerImage': bannerImage,
      'about': about,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'displayAdultContent': displayAdultContent,
    };
  }

  /// Convert to JSON for Supabase sync (snake_case matching database schema)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'banner_image': bannerImage, // snake_case для Supabase
      'about': about,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // display_adult_content не сохраняется в users таблице
    };
  }
}
