

class Profile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? timezone;
  final bool? onboardingComplete;
  final String? preferredUILang;

  Profile({
    required this.id, 
    required this.displayName, 
    this.avatarUrl, 
    this.createdAt, 
    this.updatedAt, 
    this.timezone, 
    this.onboardingComplete, 
    this.preferredUILang
  });

  factory Profile.fromMap(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      if (id == null || id is! String || id.isEmpty) {
        throw ArgumentError('Profile id is required and must be a non-empty string');
      }

      // Parse and validate createdAt
      DateTime createdAt;
      if (json['created_at'] != null) {
        if (json['created_at'] is String) {
          createdAt = DateTime.parse(json['created_at']);
        } else if (json['created_at'] is DateTime) {
          createdAt = json['created_at'];
        } else {
          throw ArgumentError('created_at must be a valid DateTime string or DateTime object');
        }
      } else {
        createdAt = DateTime.now();
      }

      DateTime? updatedAt;
      if (json['updated_at'] != null) {
        if (json['updated_at'] is String) {
          updatedAt = DateTime.parse(json['updated_at']);
        } else if (json['updated_at'] is DateTime) {
          updatedAt = json['updated_at'];
        } else {
          throw ArgumentError('updated_at must be a valid DateTime string or DateTime object');
        }
      }

      return Profile(
        id: id, 
        displayName: json['display_name']?.toString() ?? 'No display name', 
        avatarUrl: json['avatar_url']?.toString(),
        createdAt: createdAt,
        updatedAt: updatedAt,
        timezone: json['timezone']?.toString(), 
        onboardingComplete: json['onboarding_complete'] ?? false, 
        preferredUILang: json['preferred_ui_lang']?.toString()
      );
    } catch (e) {
      throw FormatException('Failed to parse Profile from json: $e \nJSON: $json');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'display_name': displayName, 
      'avatar_url': avatarUrl, 
      'created_at': createdAt?.toIso8601String(), 
      'updated_at': updatedAt?.toIso8601String(), 
      'timezone': timezone, 
      'onboarding_complete': onboardingComplete, 
      'preferred_ui_lang': preferredUILang
    };
  }
}