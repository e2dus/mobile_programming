import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/models/chat_model.dart';
import 'package:individual_project/widgets/chat/chat_message_bubble.dart';
import 'package:individual_project/widgets/chat/chat_typing_indicator.dart'; // TypingIndicator import
import 'package:intl/intl.dart';
import 'dart:math';

class MessageList extends ConsumerStatefulWidget {
  final ChatModel chatRoom;
  final bool isPartnerTyping; // 💡 ChatRoomPage에서 Provider 상태를 받아옵니다.

  const MessageList({
    super.key,
    required this.chatRoom,
    this.isPartnerTyping = false,
  });

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final timeFormat = DateFormat('h:mm a');
    final formattedTime = timeFormat.format(dateTime);

    if (messageDate.isAtSameMomentAs(today)) {
      return 'Today $formattedTime';
    }
    final fullFormat = DateFormat('MMM d');
    return '${fullFormat.format(dateTime)} $formattedTime';
  }

  // (시간 헤더 위젯 함수는 그대로 유지)
  Widget _buildTimeHeader(DateTime firstMessageTime) {
    String timeString = _formatMessageTime(firstMessageTime);

    const TextStyle timeTextStyle = TextStyle(
      fontSize: 14.0,
      color: Color(0xFF999999),
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      child: Center(
        child: Text(
          timeString,
          style: timeTextStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 MessageModel 리스트로 캐스팅 가정
    final messages = ref.watch(messageProvider(widget.chatRoom.chatId));
    final lastUserMessageIndex = messages.lastIndexWhere((m) => m.isMe);
    final lastPartnerMessageIndex = messages.lastIndexWhere((m) => !m.isMe);

    final hasMessages = messages.isNotEmpty;

    // 1. 2시간 이상 차이나는 메시지 사이에 타임스탬프를 표시할 인덱스 계산
    final List<int> timestampIndices = [];
    if (hasMessages) {
      timestampIndices.add(0); // 첫 메시지 위에는 항상 타임스탬프 표시
      for (int i = 1; i < messages.length; i++) {
        final currentMsg = messages[i];
        final prevMsg = messages[i - 1];
        final timeDiff = currentMsg.timestamp.difference(prevMsg.timestamp).inSeconds.abs();
        
        debugPrint('[Chat] Message $i: ${currentMsg.text.substring(0, min(20, currentMsg.text.length))}... at ${currentMsg.timestamp}');
        debugPrint('[Chat] Time diff from prev: ${timeDiff}s (${timeDiff / 3600} hours)');
        
        if (timeDiff >= 7200) { // 7200초 = 2시간
          debugPrint('[Chat] ✅ Showing timestamp for message $i (time diff: ${timeDiff}s)');
          timestampIndices.add(i); // 2시간 이상 차이나면 타임스탬프 표시
        }
      }
      debugPrint('[Chat] Total timestamp indices: $timestampIndices');
    }

    // 2. 아이템 개수 계산: 메시지 수 + 타임스탬프 수 + 타이핑 표시기 (선택적)
    int additionalItems = timestampIndices.length;
    if (widget.isPartnerTyping) {
      additionalItems += 1; // 타이핑 표시기
    }

    final totalItemCount = messages.length + additionalItems;

    return Expanded(
      // 메시지도 없고 타이핑도 없을 때: '대화를 시작해보세요!' 표시
      child: !hasMessages && !widget.isPartnerTyping
          ? const Center(
        child: Text(
          '대화를 시작해보세요!',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        reverse: true, // 메시지가 아래에서부터 쌓이도록 역순
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        itemCount: totalItemCount,
        itemBuilder: (context, index) {
          // 3. 타이핑 표시기 처리: 인덱스 0 (화면 맨 아래)에 배치
          if (index == 0 && widget.isPartnerTyping) {
            return TypingIndicator(partnerUsername: widget.chatRoom.username);
          }

          // 타이핑 표시기 오프셋 계산
          int offset = widget.isPartnerTyping ? 1 : 0;
          int adjustedIndex = index - offset;

          // 4. 타임스탬프와 메시지를 역순으로 표시하기 위한 로직
          // adjustedIndex를 역순으로 변환하여 실제 메시지 인덱스 계산
          int itemsProcessed = 0;
          for (int msgIdx = messages.length - 1; msgIdx >= 0; msgIdx--) {
            // 해당 메시지 위에 타임스탬프가 있는지 확인
            final bool hasTimestampAbove = timestampIndices.contains(msgIdx);
            
            // reverse: true이므로 메시지를 먼저 렌더링하고 타임스탬프는 그 다음에 (위에 표시됨)
            if (itemsProcessed == adjustedIndex) {
              // 메시지 버블 표시
              final message = messages[msgIdx];
              // ⭐️ LLM이 답장한 경우(lastPartnerMessageIndex > lastUserMessageIndex) 'Seen just now' 숨김
              final bool hasPartnerReplyAfterUser = 
                  lastPartnerMessageIndex != -1 && 
                  lastUserMessageIndex != -1 &&
                  lastPartnerMessageIndex > lastUserMessageIndex;
              final bool isLastSeenMessage =
                  message.isMe &&
                  message.isSeen &&
                  msgIdx == lastUserMessageIndex &&
                  !hasPartnerReplyAfterUser; // LLM 답장이 있으면 표시하지 않음
              
              final bool isLastPartnerMessage =
                  !message.isMe &&
                  msgIdx == lastPartnerMessageIndex;

              return MessageBubble(
                message: message,
                partnerUsername: widget.chatRoom.username,
                isLastUserMessage: isLastSeenMessage,
                isLastPartnerMessage: isLastPartnerMessage,
              );
            }
            itemsProcessed++;
            
            if (hasTimestampAbove) {
              if (itemsProcessed == adjustedIndex) {
                // 타임스탬프 표시 (메시지 위에)
                return _buildTimeHeader(messages[msgIdx].timestamp);
              }
              itemsProcessed++;
            }
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}