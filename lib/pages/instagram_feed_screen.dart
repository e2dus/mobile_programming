import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/widgets/post/post_widget.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/widgets/story/story_section.dart';
import 'package:individual_project/widgets/post/post_new_post_notification.dart';
import 'package:individual_project/widgets/reels/suggested_reels.dart';


class InstagramFeedScreen extends ConsumerWidget {
  const InstagramFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);
    final postsNotifier = ref.read(postsProvider.notifier);

    final stories = ref.watch(storiesProvider);
    final storiesNotifier = ref.read(storiesProvider.notifier);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              StorySection(
                stories: stories,
                notifier: storiesNotifier,
              ),
              // 새 게시물 알림 (업로드 직후에만 표시)
              const PostNewPostNotification(),
            ],
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == posts.length - 1) {
                postsNotifier.loadMorePosts();
              }
              if (index == posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text('더 이상 불러올 게시물이 없습니다.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              final postID = posts[index].id;
              if ((index + 1) % 6 == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PostWidget(postID: postID),
                    const SuggestedReels(),
                  ],
                );
              }
              return PostWidget(postID: postID);
            },
            childCount: posts.length + 1,
          ),
        ),
      ],
    );
  }
}