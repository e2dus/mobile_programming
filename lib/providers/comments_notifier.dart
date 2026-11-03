import 'package:individual_project/models/comment_model.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsNotifier extends StateNotifier<List<CommentModel>> {
  CommentsNotifier(super.state);

  // 모든 댓글 로드
  Future<void> loadAllComments() async {
    try {
      final client = Supabase.instance.client;
      debugPrint('[CommentsNotifier] Loading all comments from Supabase');

    final List<dynamic> commentsRows = await client
      .from('comments')
      .select('id, post_id, username, content, time, heart_count, my_heart, reply')
          .order('time', ascending: true);

      final comments = commentsRows
          .map((row) => CommentModel.fromJson(row))
          .toList();

      state = comments;
      debugPrint('[CommentsNotifier] Loaded ${comments.length} comments');
    } catch (e) {
      debugPrint('[CommentsNotifier] Error loading comments: $e');
      rethrow;
    }
  }

  // 특정 포스트의 댓글만 로드
  Future<void> loadCommentsByPostId(String postId) async {
    try {
      final client = Supabase.instance.client;
      debugPrint('[CommentsNotifier] Loading comments for post: $postId');

    final List<dynamic> commentsRows = await client
      .from('comments')
      .select('id, post_id, username, content, time, heart_count, my_heart, reply')
          .eq('post_id', postId)
          .order('time', ascending: true);

      final comments = commentsRows
          .map((row) => CommentModel.fromJson(row))
          .toList();

      state = comments;
      debugPrint('[CommentsNotifier] Loaded ${comments.length} comments for post $postId');
    } catch (e) {
      debugPrint('[CommentsNotifier] Error loading comments for post: $e');
      rethrow;
    }
  }

  // 댓글 추가
  Future<void> addComment({
    required String postId,
    required String username,
    required String content,
    int? reply,
  }) async {
    // 낙관적 업데이트: 우선 로컬에 임시 댓글을 추가합니다.
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final pendingComment = CommentModel(
      id: tempId,
      postId: postId,
      username: username,
      content: content,
      time: DateTime.now(),
      heartCount: 0,
      myHeart: false,
      reply: reply,
      pending: true,
    );
    state = [...state, pendingComment];

    try {
      final client = Supabase.instance.client;
      debugPrint('[CommentsNotifier] Adding comment to post: $postId');

      final response = await client.from('comments').insert({
        'post_id': postId,
        'username': username,
        'content': content,
        'time': DateTime.now().toUtc().toIso8601String(),
        'heart_count': 0,
        'my_heart': false,
        'reply': reply,
      }).select().single();

      final serverComment = CommentModel.fromJson(response);
      // 임시 댓글을 서버 댓글로 교체
      state = state.map((c) => c.id == tempId ? serverComment : c).toList();
      debugPrint('[CommentsNotifier] Comment added successfully');
    } catch (e) {
      // 실패 시 임시 댓글 제거
      state = state.where((c) => c.id != tempId).toList();
      debugPrint('[CommentsNotifier] Error adding comment: $e');
      rethrow;
    }
  }

  // 댓글 좋아요 토글
  Future<void> toggleHeart(int commentId) async {
    try {
      final client = Supabase.instance.client;
      final commentIndex = state.indexWhere((c) => c.id == commentId);
      
      if (commentIndex == -1) return;

    final comment = state[commentIndex];
    // 전송 중 댓글은 하트 토글 불가
    if (comment.pending) return;
    final newMyHeart = !comment.myHeart;
    final newHeartCount = newMyHeart
      ? comment.heartCount + 1
      : (comment.heartCount > 0 ? comment.heartCount - 1 : 0);

      await client.from('comments').update({
        'my_heart': newMyHeart,
        'heart_count': newHeartCount,
      }).eq('id', commentId);

      final updatedComment = comment.copyWith(
        myHeart: newMyHeart,
        heartCount: newHeartCount,
      );

      state = [
        ...state.sublist(0, commentIndex),
        updatedComment,
        ...state.sublist(commentIndex + 1),
      ];

      debugPrint('[CommentsNotifier] Toggled heart for comment $commentId');
    } catch (e) {
      debugPrint('[CommentsNotifier] Error toggling heart: $e');
      rethrow;
    }
  }

  // 댓글 삭제
  Future<void> deleteComment(int commentId) async {
    try {
      final client = Supabase.instance.client;
      debugPrint('[CommentsNotifier] Deleting comment: $commentId');

      await client.from('comments').delete().eq('id', commentId);

      state = state.where((comment) => comment.id != commentId).toList();
      debugPrint('[CommentsNotifier] Comment deleted successfully');
    } catch (e) {
      debugPrint('[CommentsNotifier] Error deleting comment: $e');
      rethrow;
    }
  }

  // 특정 포스트의 댓글 개수 가져오기
  int getCommentCountByPostId(String postId) {
    return state.where((comment) => comment.postId == postId).length;
  }

  // 특정 포스트의 댓글들 가져오기
  List<CommentModel> getCommentsByPostId(String postId) {
    return state.where((comment) => comment.postId == postId).toList();
  }
}