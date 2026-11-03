import 'package:individual_project/models/story_model.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoriesNotifier extends StateNotifier<List<StoryModel>> {
  StoriesNotifier(super.state);

  Future<void> loadInitialStories() async {
    try {
      final client = Supabase.instance.client;
      debugPrint('[StoriesNotifier] Loading stories from Supabase...');

      // fetch stories rows
      final List<dynamic> storyRows = await client
          .from('stories')
          .select('id, username, hasViewed, isMyStory, isMainPageStory');
      debugPrint('[StoriesNotifier] stories rows: ${storyRows.length}');
      if (storyRows.isNotEmpty) {
        debugPrint('[StoriesNotifier] stories sample row: ${storyRows.first}');
      }

      final List<dynamic> userRows = await client
          .from('users')
          .select('id, username, profileImageUrl');
      debugPrint('[StoriesNotifier] users rows (for avatar map): ${userRows.length}');
      if (userRows.isNotEmpty) {
        debugPrint('[StoriesNotifier] users sample row: ${userRows.first}');
      }

      final Map<String, String> usernameToAvatar = {
        for (final u in userRows)
          (u['username'] as String? ?? ''): (u['profileImageUrl']?.toString() ??
              'assets/images/basic_image.jpg')
      }..removeWhere((k, v) => k.isEmpty);

      final List<StoryModel> parsed = storyRows.map<StoryModel>((row) {
        final String username = (row['username'] ?? '').toString();
        return StoryModel(
          id: row['id'].toString(),
          username: username,
          profileImageUrl:
              usernameToAvatar[username] ?? 'assets/images/basic_image.jpg',
          hasViewed: (row['hasViewed'] as bool?) ?? false,
          isMyStory: (row['isMyStory'] as bool?) ?? false,
          isMainPageStory: (row['isMainPageStory'] as bool?) ?? true,
        );
      }).toList();

      if (parsed.isNotEmpty) {
        state = parsed;
        return;
      }
      debugPrint('[StoriesNotifier] Supabase stories empty.');
    } catch (e) {
      debugPrint('[StoriesNotifier] Error loading stories from Supabase: $e');
    }

    // Safe minimal fallback when Supabase is empty or errors
    state = [
      StoryModel(
        id: '',
        username: 'Your story',
        profileImageUrl: 'assets/images/basic_image.jpg',
        hasViewed: false,
        isMyStory: true,
        isMainPageStory: true,
      )
    ];
  }

  // ⭐️ 스토리가 클릭되었을 때 읽음 상태를 업데이트하는 함수
  void markStoryAsViewed(String storyId) {
    state = [
      for (final story in state)
        if (story.id == storyId)
        // 해당 ID의 스토리만 상태를 '읽음(true)'으로 변경
          story.copyWith(hasViewed: true)
        else
          story,
    ];
  }
}