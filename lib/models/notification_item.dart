import 'package:flutter/foundation.dart';

enum NotificationType { comment, like, follow }

@immutable
class NotificationItem {
  final NotificationType type;
  final String actorUsername; // 행동한 사용자
  final String? actorAvatarUrl; // 프로필 이미지
  final String? postThumbnailUrl; // 관련 게시물 썸네일 (like/comment 시)
  final String? commentText; // 댓글 내용 (comment 시)
  final DateTime time; // 발생 시각
  final String? postId; // 관련 post id (like/comment) - String으로 변경

  const NotificationItem({
    required this.type,
    required this.actorUsername,
    required this.time,
    this.actorAvatarUrl,
    this.postThumbnailUrl,
    this.commentText,
    this.postId,
  });
}
