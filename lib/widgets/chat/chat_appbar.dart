import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/models/chat_model.dart';
import 'package:individual_project/components/story_icon.dart';
import 'package:individual_project/providers/app_providers.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget{
  final ChatModel chatModel;

  const ChatAppBar({super.key, required this.chatModel});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상대방의 스토리 여부를 확인하여, 없으면 그라데이션(링) 표시 안 함
    final stories = ref.watch(storiesProvider);
    final match = stories.where(
      (s) => s.username.toLowerCase() == chatModel.username.toLowerCase(),
    );
    final hasStory = match.isNotEmpty;
    final bool hasViewed = hasStory ? match.first.hasViewed : true; // 스토리 없으면 viewed 처리

    // ⭐️ users 데이터에서 name 가져오기
    final users = ref.watch(usersProvider);
    final user = users[chatModel.username] ?? 
                 ref.read(usersProvider.notifier).getUserByUsername(chatModel.username);
    final String displayName = user?.name ?? chatModel.username;

    return AppBar(

      backgroundColor: Colors.white,
      elevation: 0.5,

      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pop(context);
        },
      ),

      title: GestureDetector(
        onTap: () {

        },
        child: Row(
          children: [
            StoryIcon(
              profileImageUrl: chatModel.profileImageUrl,
              username: chatModel.username,
              hasViewed: hasViewed,
              isMyStory: false,
              size: 36,
              isMainPageStory: false,
              onTap: () {},
            ),
            const SizedBox(width: 8),

            // ⭐️ 이름과 username을 세로로 표시
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_right,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  Text(
                    chatModel.username,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 3. 우측 액션 버튼 (전화/영상 통화 아이콘 등)
      actions: [
        // 전화 통화 아이콘
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.black),
          onPressed: () {

          },
        ),

        // 영상 통화 아이콘
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.black),
          onPressed: () {

          },
        ),
        const SizedBox(width: 8), // 오른쪽 여백
      ],
    );
  }
}