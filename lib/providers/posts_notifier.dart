import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:individual_project/models/post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostsNotifier extends StateNotifier<List<PostModel>> {
  PostsNotifier(super.state);
  int _page = 0;
  bool _isLoading = false;

  Future<void> loadInitialPosts() async {
    try {
      final client = Supabase.instance.client;
      debugPrint('[PostsNotifier] Loading posts from Supabase...');
      final List<dynamic> postRows = await client
          .from('posts')
          .select(
              'id, username, isLiked, isBookmarked, caption, time, likesCount, currentPageIndex, isReel, videoUrl, postImageUrls')
          .order('time', ascending: false);
      debugPrint('[PostsNotifier] posts rows: ${postRows.length}');
      if (postRows.isNotEmpty) {
        debugPrint('[PostsNotifier] posts sample row: ${postRows.first}');
      }

      final List<dynamic> userRows =
          await client.from('users').select('username, profileImageUrl');
      debugPrint('[PostsNotifier] users rows: ${userRows.length}');
      if (userRows.isNotEmpty) {
        debugPrint('[PostsNotifier] users sample row: ${userRows.first}');
      }
      final Map<String, String> usernameToAvatar = {
        for (final u in userRows) (u['username'] as String): (u['profileImageUrl'] as String)
      };

      final List<PostModel> parsed = postRows.map<PostModel>((row) {
        final List<dynamic> imgs = (row['postImageUrls'] ?? []) as List<dynamic>;
        final String username = row['username'] as String;
        return PostModel(
          id: row['id'].toString(),
          username: username,
          profileImageUrl: usernameToAvatar[username] ?? 'assets/images/avatars/default_profile.jpg',
          postImageUrls: imgs.map((e) => e.toString()).toList(),
          isLiked: (row['isLiked'] as bool?) ?? false,
          isBookmarked: (row['isBookmarked'] as bool?) ?? false,
          caption: (row['caption'] ?? '') as String,
          // Map DB 'time' (timestamptz) to model's timeAgo string for now
          timeAgo: (row['time']?.toString() ?? ''),
          likesCount: (row['likesCount'] as int?) ?? 0,
          currentPageIndex: (row['currentPageIndex'] as int?) ?? 0,
          isReel: (row['isReel'] as bool?) ?? false,
          music: MusicInfoModel.NONE,
          videoUrl: row['videoUrl'] as String?,
        );
      }).toList();
      // Ensure newest first even if backend order changes
      DateTime _safeParse(String s) {
        try {
          return DateTime.parse(s);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
      parsed.sort((a, b) => _safeParse(b.timeAgo).compareTo(_safeParse(a.timeAgo)));
      debugPrint('[PostsNotifier] parsed posts: ${parsed.length}');
      state = parsed;
    } catch (e) {
      debugPrint('[PostsNotifier] Error loading posts from Supabase: $e');
      state = [];
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // 더 짧은 지연
      final newPosts = List.generate(5, (index) {
        _page++;
        return PostModel(
          id: 'p${state.length + index + 1}',
          username: 'NewUser$_page',
          profileImageUrl: 'assets/images/basic_image.jpg',
          postImageUrls: ['assets/images/basic_image.jpg'],
          likesCount: 100 + _page * 10,
          caption: '새로 로드된 게시물 #$_page',
          isLiked: false,
          timeAgo: '1',
        );
      });
      state = [...state, ...newPosts];
    } finally {
      _isLoading = false;
    }
  }
}