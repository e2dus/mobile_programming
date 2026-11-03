import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/components/story_icon.dart';
import 'package:individual_project/models/chat_model.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/models/story_model.dart';
import 'package:individual_project/utils/time_ago_en.dart';

class DmChatListItem extends ConsumerWidget {
  final ChatModel chatModel;
  final VoidCallback onChatTap;
  final VoidCallback onIconTap;

  const DmChatListItem({
    super.key,
    required this.chatModel,
    required this.onChatTap,
    required this.onIconTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 스토리 상태 확인
    final stories = ref.watch(storiesProvider);
    final matching = stories.where((s) => s.username == chatModel.username);
    final StoryModel? storyForUser = matching.isNotEmpty ? matching.first : null;
    final bool userHasStory = storyForUser != null;
    final String profileUrl = storyForUser?.profileImageUrl ?? chatModel.profileImageUrl;

    // Supabase users 테이블에서 이름 가져오기
    final users = ref.watch(usersProvider);
    final user = users[chatModel.username] ?? 
                 ref.read(usersProvider.notifier).getUserByUsername(chatModel.username);
    final String displayName = user?.name ?? chatModel.username;

    return InkWell(
      onTap: onChatTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            StoryIcon(
              profileImageUrl: profileUrl,
              username: chatModel.username,
              hasViewed: storyForUser?.hasViewed ?? true,
              isMyStory: storyForUser?.isMyStory ?? false,
              onTap: userHasStory ? () {
                final storiesNotifier = ref.read(storiesProvider.notifier);
                if (!storyForUser.hasViewed) {
                  storiesNotifier.markStoryAsViewed(storyForUser.id);
                }
                onIconTap();
              } : onIconTap,
              isMainPageStory: false,
              size: 70,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: _buildTextContent(displayName, ref),
            ),
            _buildActionIcon(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(String displayName, WidgetRef ref) {
    // 마지막 메시지 가져오기
    final messages = ref.watch(messageProvider(chatModel.chatId));
    String displayText = '';
    
    if (messages.isNotEmpty) {
      final lastMessage = messages.last;
      String timeAgoText = formatTimeAgoEnShort(lastMessage.timestamp.toLocal());
      // "just now"를 "now"로 변경
      if (timeAgoText == 'just now') {
        timeAgoText = 'now';
      }
      final isJustNow = timeAgoText == 'now';
      
      // 방금 전에 보낸 경우에만 "메시지 · now" 형식으로 표시
      if (isJustNow) {
        String lastMessageText = '';
        if (lastMessage.text.isNotEmpty) {
          lastMessageText = lastMessage.text.length > 10 
              ? '${lastMessage.text.substring(0, 10)}...' 
              : lastMessage.text;
        } else if (lastMessage.images != null && lastMessage.images!.isNotEmpty) {
          // 사진 메시지인 경우
          lastMessageText = 'Photo';
        } else {
          lastMessageText = 'Photo'; // 빈 텍스트이고 이미지도 없으면 Photo로 표시
        }
        displayText = '$lastMessageText · now';
      } else {
        // 그 외의 경우: "Sent 3m ago" 또는 "Seen" 형식
        if (chatModel.hasUnreadMessage) {
          displayText = 'Sent $timeAgoText';
        } else {
          displayText = 'Seen';
        }
      }
    } else {
      // 메시지가 없는 경우: 기존 형식
      if (chatModel.lastMessageTime != null) {
        final timeAgoText = formatTimeAgoEnShort(chatModel.lastMessageTime!.toLocal());
        if (chatModel.hasUnreadMessage) {
          displayText = 'Sent $timeAgoText';
        } else {
          displayText = 'Seen';
        }
      } else {
        displayText = '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          displayName, // ⭐️ 표시 이름을 사용
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black,
          ),
        ),
        Text(
          displayText,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.camera_alt_outlined,
        color: Colors.black,
        size: 28,
      ),
      onPressed: () {},
    );
  }
}