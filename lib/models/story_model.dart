class StoryModel {
  final String id;
  final String username;
  final String profileImageUrl;
  final bool hasViewed;
  final bool isMyStory;
  final bool isMainPageStory;

  StoryModel({
    required this.id,
    required this.username,
    required this.profileImageUrl,
    this.hasViewed = false,
    this.isMyStory = false,
    this.isMainPageStory = true,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      hasViewed: json['hasViewed'] as bool? ?? false,
      isMyStory: json['isMyStory'] as bool? ?? false,
      isMainPageStory: json['isMainPageStory'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'profileImageUrl': profileImageUrl,
    'hasViewed': hasViewed,
    'isMyStory': isMyStory,
    'isMainPageStory': isMainPageStory,
  };

  StoryModel copyWith({
    bool? hasViewed,
  }) {
    return StoryModel(
      id: id,
      username: username,
      profileImageUrl: profileImageUrl,
      hasViewed: hasViewed ?? this.hasViewed,
      isMyStory: isMyStory,
      isMainPageStory: isMainPageStory,
    );
  }
}