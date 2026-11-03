class MusicInfoModel {
  final String artist;
  final String title;
  static const MusicInfoModel NONE = MusicInfoModel(artist: 'None', title: '');

  const MusicInfoModel({required this.artist, required this.title});

  MusicInfoModel copyWith({
    String? artist,
    String? title,
  }) {
    return MusicInfoModel(
      artist: artist ?? this.artist,
      title: title ?? this.title,
    );
  }
}
class PostModel {
  final String id;
  final String username;
  final String profileImageUrl;
  final List<String> postImageUrls;
  final bool isLiked;
  final bool isBookmarked;
  final String caption;
  final String timeAgo;
  final int likesCount;
  final int currentPageIndex;
  final bool isReel;
  final MusicInfoModel music;
  final String? videoUrl;

  PostModel({
    required this.id,
    required this.username,
    required this.profileImageUrl,
    required this.postImageUrls,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.caption,
    required this.timeAgo,
    required this.likesCount,
    this.currentPageIndex = 0,
    this.isReel = false,
    this.music = MusicInfoModel.NONE,
    this.videoUrl,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      postImageUrls: (json['postImageUrls'] as List).cast<String>(),
      isLiked: json['isLiked'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      caption: json['caption'] as String,
      timeAgo: json['timeAgo'] as String,
      likesCount: json['likesCount'] as int,
      currentPageIndex: json['currentPageIndex'] as int? ?? 0,
      isReel: json['isReel'] as bool? ?? false,
      music: json['music'] != null
          ? MusicInfoModel(
              artist: json['music']['artist'] as String,
              title: json['music']['title'] as String,
            )
          : MusicInfoModel.NONE,
      videoUrl: json['videoUrl'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'profileImageUrl': profileImageUrl,
    'postImageUrls': postImageUrls,
    'isLiked': isLiked,
    'isBookmarked': isBookmarked,
    'caption': caption,
    'timeAgo': timeAgo,
    'likesCount': likesCount,
    'currentPageIndex': currentPageIndex,
    'isReel': isReel,
    'music': {
      'artist': music.artist,
      'title': music.title,
    },
    'videoUrl': videoUrl,
  };

  PostModel copyWith({
    String? id,
    String? username,
    String? profileImageUrl,
    List<String>? postImageUrls,
    int? likesCount,
    String? caption,
    String? timeAgo,
    bool? isLiked,
    bool? isBookmarked,
    int? currentPageIndex,
    bool? isReel,
    MusicInfoModel? music,
    String? videoUrl
  }) {
    return PostModel(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      postImageUrls: postImageUrls ?? this.postImageUrls,
      likesCount: likesCount ?? this.likesCount,
      caption: caption ?? this.caption,
      timeAgo: timeAgo ?? this.timeAgo,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isReel: isReel ?? this.isReel,
      music: music ?? this.music,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}