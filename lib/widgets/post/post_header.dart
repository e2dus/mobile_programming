import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/models/post_model.dart';
import 'package:individual_project/components/story_icon.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/models/story_model.dart';
import 'package:individual_project/pages/profile_screen.dart';

class PostHeader extends ConsumerWidget {
  final PostModel post;

  const PostHeader({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isReel = post.isReel;
    final Color contentColor = isReel ? Colors.white : Colors.black;
    final Color backgroundColor = isReel ? Colors.transparent : Colors.white;

    final List<Shadow>? shadows = isReel
        ? [const Shadow(color: Colors.black54, blurRadius: 5.0)]
        : null;

    final stories = ref.watch(storiesProvider);
    final matching = stories.where((s) => s.username == post.username);
    final StoryModel? storyForUser = matching.isNotEmpty ? matching.first : null;

    final bool authorHasStory = storyForUser != null;

    return Container(
      // 릴스일 경우 투명, 아닐 경우 흰색 배경
      color: backgroundColor,

      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),

      child: Row(
        children: [
          StoryIcon(
            profileImageUrl: post.profileImageUrl,
            username: post.username,
            hasViewed: storyForUser?.hasViewed ?? true, // 스토리 없으면 viewed 처리
            // 포스트 헤더에서는 내 게시물이라도 '+' 배지를 표시하지 않도록 고정
            isMyStory: false,
            onTap: authorHasStory ? () {
              // 스토리를 읽음으로 표시
              final storiesNotifier = ref.read(storiesProvider.notifier);
              if (!storyForUser.hasViewed) {
                storiesNotifier.markStoryAsViewed(storyForUser.id);
              }
              // TODO: 스토리 뷰어로 네비게이션 처리 (추가 구현 필요)
              // Navigator.of(context).push(...);
            } : () {},
            isMainPageStory: false, // 피드에서는 항상 false
            size: 50, // 포스트 헤더에서는 작은 크기 사용
          ),

          const SizedBox(width: 10),

          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navigate to user profile
                final users = ref.read(usersProvider);
                final user = users.values.firstWhere(
                  (u) => u.username == post.username,
                  orElse: () => users.values.first,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: user.id),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: contentColor, // 릴스에선 흰색, 피드에선 검은색
                      shadows: shadows,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 릴스 전용: 음악 정보
                  if (isReel && post.music != MusicInfoModel.NONE)
                    Text(
                      '${post.music.artist} • ${post.music.title}',
                      style: TextStyle(
                        fontSize: 12,
                        color: contentColor,
                        shadows: shadows,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),

          // 더보기 아이콘
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: contentColor, // 릴스에선 흰색, 피드에선 검은색
              size: 24,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}