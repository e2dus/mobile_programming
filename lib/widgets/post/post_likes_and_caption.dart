import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/models/post_model.dart';
import 'package:individual_project/utils/time_ago_en.dart';
import 'package:individual_project/providers/app_providers.dart';

class PostLikesAndCaption extends ConsumerWidget {
  final PostModel post;

  const PostLikesAndCaption({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 해당 게시물의 댓글 가져오기
    final allComments = ref.watch(commentsProvider);
    final postComments = allComments
        .where((comment) => comment.postId == post.id)
        .toList();
    
    // 시간순 정렬 (최신순)
    postComments.sort((a, b) => b.time.compareTo(a.time));
    final latestComment = postComments.isNotEmpty ? postComments.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 텍스트를 왼쪽 정렬
        children: [

          // 1. 좋아요 수
          _buildLikesCount(context),
          const SizedBox(height: 4),

          // 2. 사용자 이름 및 캡션 (캡션이 있을 때만 표시)
          if (post.caption.isNotEmpty) _buildCaption(context),
          if (post.caption.isNotEmpty) const SizedBox(height: 4),

          // 3. 가장 최근 댓글 표시
          if (latestComment != null) _buildLatestComment(latestComment),
          if (latestComment != null) const SizedBox(height: 4),

          // 4. 시간 표시
          _buildTimestamp(),
          const SizedBox(height: 8), // 다음 게시물과의 간격
        ],
      ),
    );
  }

  // --- 보조 위젯 ---

  // 1. 좋아요 수 표시
  Widget _buildLikesCount(BuildContext context) {
    // 좋아요 수를 콤마(,)로 포맷하는 로직 적용
    final formattedLikes = NumberFormat.decimalPattern().format(post.likesCount);

    return Text(
      '$formattedLikes likes',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontSize: 14,
      ),
    );
  }

  // 2. 사용자 이름과 캡션 표시
  Widget _buildCaption(BuildContext context) {
    // 사용자 이름과 캡션을 RichText로 연결하여 각각 다른 스타일을 적용
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(color: Colors.black, fontSize: 14),
        children: [
          // 사용자 이름 (볼드체)
          TextSpan(
            text: '${post.username} ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          // 캡션 내용
          TextSpan(
            text: post.caption,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),

        ],
      ),
    );
  }

  // 3. 가장 최근 댓글 표시
  Widget _buildLatestComment(comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 14),
              children: [
                // 댓글 작성자 (볼드)
                TextSpan(
                  text: '${comment.username} ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // 댓글 내용
                TextSpan(
                  text: comment.content,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.favorite_border,
          size: 16,
          color: Colors.grey[600],
        ),
      ],
    );
  }

  // 4. 시간 표시
  Widget _buildTimestamp() {
    final text = _formatTime(post.timeAgo);
    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      // raw is ISO string from DB 'time'
      final dt = DateTime.parse(raw).toLocal();
      return formatTimeAgoEnLong(dt);
    } catch (e) {
      // If parsing fails, try to return a short format
      debugPrint('[PostLikesAndCaption] Failed to parse time: $raw, error: $e');
      return raw;
    }
  }
}