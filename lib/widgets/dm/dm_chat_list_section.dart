// lib/widgets/dm/dm_chat_list_section.dart (수정 완료)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/providers/app_providers.dart'; // chatsProvider
import 'package:individual_project/widgets/dm/dm_chat_list_item.dart';
import 'package:individual_project/models/story_model.dart';
import 'package:collection/collection.dart';
import 'package:individual_project/pages/chat_room_page.dart'; // ⭐️ 상세 페이지 임포트

class DmChatListSection extends ConsumerWidget {
  const DmChatListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final stories = ref.watch(storiesProvider);
    final storiesNotifier = ref.read(storiesProvider.notifier);

    final chats = ref.watch(chatsProvider);
    final chatsNotifier = ref.read(chatsProvider.notifier);

    return Column(
      // ⭐️ chat list를 DmChatListItem 리스트로 변환
      children: chats.map((chat) {

        final StoryModel? userStory = stories.firstWhereOrNull(
              (story) => story.username == chat.username,
        );

        final String? storyIdToMark = userStory?.id;

        // ⭐️ DmChatListItem의 생성자 시그니처에 맞게 chatModel 전체를 전달합니다.
        return DmChatListItem(
          chatModel: chat, // ⭐️ ChatModel 객체 전체를 전달하여 오류를 해결합니다.

          // ⭐️ onChatTap 로직: 읽음 처리 후 상세 페이지로 이동
          onChatTap: () {
            // 1. Riverpod Notifier를 통해 읽음 처리
            chatsNotifier.markChatAsRead(chat.chatId);

            // 2. ⭐️ ChatDetailPage로 이동 및 데이터 전달
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => ChatRoomPage(chatRoom: chat),
                transitionDuration: const Duration(milliseconds: 420),
                reverseTransitionDuration: const Duration(milliseconds: 420),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(parent: animation, curve: Curves.linear);
                  // 새 화면: 오른쪽 → 중앙 (수평만)
                  final incoming = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curved);
                  // 기존 화면: 중앙 → 왼쪽으로 10% (push), pop 시 -0.10 → 0 으로 복귀
                  final outgoingSlightLeft = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.10, 0.0))
                      .chain(CurveTween(curve: Curves.linear))
                      .animate(secondaryAnimation);
                  return SlideTransition(
                    position: outgoingSlightLeft, // 기존 화면을 10% 왼쪽으로
                    child: SlideTransition(
                      position: incoming, // 새 화면은 오른쪽에서 수평으로 진입
                      child: child,
                    ),
                  );
                },
              ),
            );
          },

          // onIconTap 로직 (스토리 읽음 처리)
          onIconTap: (){
            if (storyIdToMark != null) {
              storiesNotifier.markStoryAsViewed(storyIdToMark);
            }
          },
        );
      }).toList(),
    );
  }
}