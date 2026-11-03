import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/models/story_model.dart';
import 'package:individual_project/providers/stories_notifier.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/components/story_icon.dart';

class StorySection extends ConsumerWidget {
  final List<StoryModel> stories;
  final StoriesNotifier notifier;

  const StorySection({
    super.key,
    required this.stories,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 로그인한 사용자 정보 가져오기
    final users = ref.watch(usersProvider);
    
    // users가 비어있으면 빈 컨테이너 반환
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final loggedInUser = users.values.firstWhere(
      (user) => user.login == true,
      orElse: () => users.values.first,
    );

    return Container(
      height: 110,
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];

          return StoryIcon(
            username: story.isMyStory ? 'Your story' : story.username,
            profileImageUrl: story.isMyStory ? loggedInUser.profileImageUrl : story.profileImageUrl,
            hasViewed: story.hasViewed,
            isMyStory: story.isMyStory,
            onTap: () {
              if (story.isMyStory) {
              } else {
                notifier.markStoryAsViewed(story.id);
              }
            },
          );
        },
      ),
    );
  }
}