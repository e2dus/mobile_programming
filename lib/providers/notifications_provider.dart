import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:individual_project/models/notification_item.dart';
import 'package:individual_project/providers/app_providers.dart';

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  final client = Supabase.instance.client;
  final users = ref.read(usersProvider);
  
  // login == true인 사용자를 현재 로그인 사용자로 간주
  final userModel = users.values.firstWhere(
    (u) => u.login == true,
    orElse: () => throw Exception('No logged in user found'),
  );
  final myUsername = userModel.username;

  final List<NotificationItem> items = [];
  try {
    // 1. 내 게시물 ID 먼저 가져오기
    final myPosts = await client
        .from('posts')
        .select('id, postImageUrls')
        .eq('username', myUsername);
    
    final myPostIds = myPosts.map((p) => p['id'].toString()).toSet();
    final myPostThumbs = <String, String?>{};
    for (final p in myPosts) {
      if (p['postImageUrls'] is List && (p['postImageUrls'] as List).isNotEmpty) {
        myPostThumbs[p['id'].toString()] = (p['postImageUrls'] as List).first as String?;
      }
    }
    
    if (myPostIds.isEmpty) return items;

    // 2. Comments on my posts (한 번에 가져오기) - 내 댓글 포함
    final comments = await client
        .from('comments')
        .select('id, post_id, username, content, time')
        .inFilter('post_id', myPostIds.toList())
        .order('time', ascending: false)
        .limit(100);

    for (final c in comments) {
      final postId = c['post_id'].toString();
      final avatar = users.values.firstWhere(
        (u) => u.username == c['username'],
        orElse: () => userModel,
      ).profileImageUrl;
      
      items.add(NotificationItem(
        type: NotificationType.comment,
        actorUsername: c['username'] ?? 'unknown',
        commentText: c['content'],
        time: DateTime.tryParse(c['time'].toString()) ?? DateTime.now(),
        postThumbnailUrl: myPostThumbs[postId],
        postId: postId,
        actorAvatarUrl: avatar,
      ));
    }
    
    // 3. Likes on my posts (한 번에 가져오기) - 내 좋아요 포함
    final likes = await client
        .from('likes')
        .select('id, user_id, post_id, time')
        .inFilter('post_id', myPostIds.toList())
        .order('time', ascending: false)
        .limit(100);

    for (final l in likes) {
      final postId = l['post_id'].toString();
      String likeUserName = (l['user_id'] ?? 'unknown').toString();
      
      final likeUser = users.values.firstWhere(
        (u) => u.username == likeUserName || u.id == likeUserName,
        orElse: () => userModel,
      );
      
      items.add(NotificationItem(
        type: NotificationType.like,
        actorUsername: likeUser.username,
        time: DateTime.tryParse(l['time'].toString()) ?? DateTime.now(),
        postThumbnailUrl: myPostThumbs[postId],
        postId: postId,
        actorAvatarUrl: likeUser.profileImageUrl,
      ));
    }
    
    // New followers (someone followed me)
    // follows 테이블은 id 기반이므로 userModel.id로 조회
    final follows = await client
        .from('follows')
        .select('follower_id, following_id, created_at')
        .eq('following_id', userModel.id) // username이 아닌 id로 조회
        .order('created_at', ascending: false)
        .limit(100);
    for (final f in follows) {
      final followerId = f['follower_id'] as String;
      // follower_id도 user id이므로 id로 찾기
      final follower = users.values.firstWhere(
        (u) => u.id == followerId,
        orElse: () => userModel,
      );
      
      items.add(NotificationItem(
        type: NotificationType.follow,
        actorUsername: follower.username,
        time: DateTime.tryParse(f['created_at'].toString()) ?? DateTime.now(),
        actorAvatarUrl: follower.profileImageUrl,
      ));
    }
  } catch (e, st) {
    debugPrint('[Notifications] ❌ Error: $e\n$st');
    rethrow;
  }

  items.sort((a, b) => b.time.compareTo(a.time));
  return items;
});