import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/models/chat_model.dart';
import 'package:individual_project/widgets/chat/chat_appbar.dart'; // AppBar 위젯
import 'package:individual_project/widgets/chat/chat_message_list.dart'; // 메시지 목록 위젯
import 'package:individual_project/widgets/chat/chat_message_input.dart'; // 메시지 입력창 위젯
import 'package:individual_project/providers/app_providers.dart';

class ChatRoomPage extends ConsumerWidget {
  final ChatModel chatRoom;

  const ChatRoomPage({super.key, required this.chatRoom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTyping = ref.watch(isTypingProvider(chatRoom.chatId));
    return Scaffold(
      // 1. AppBar (이전에 구현)
      appBar: ChatAppBar(chatModel: chatRoom),

      body: Column(
        children: [
          // 2. 메시지 목록
          MessageList(chatRoom: chatRoom, isPartnerTyping: isTyping,),

          MessageInput(chatId: chatRoom.chatId),
        ],
      ),
      // 키보드가 올라올 때 body가 리사이즈되도록 설정
      resizeToAvoidBottomInset: true,
    );
  }
}