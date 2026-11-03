// lib/widgets/message_bubble.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:individual_project/models/message_model.dart'; // MessageModel 임포트
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:individual_project/providers/app_providers.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final MessageModel message;
  final String partnerUsername; // 상대방 username (users 테이블 조회용)
  final bool isLastUserMessage;
  final bool isLastPartnerMessage; // 상대방이 보낸 마지막 메시지인지 여부

  const MessageBubble({
    super.key,
    required this.message,
    required this.partnerUsername,
    this.isLastUserMessage = false,
    this.isLastPartnerMessage = false,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  final GlobalKey _bubbleKey = GlobalKey();
  Color _bubbleColor = const Color(0xFF6328A5); // 기본 색상
  bool _tracking = false; // 스크롤/프레임 추적 여부
  bool _showReactHint = true; // 'Tap and hold to react' 표시 여부
  Timer? _reactHintTimer; // 5초 타이머

  @override
  void initState() {
    super.initState();
    // 첫 프레임 이후 추적 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTracking();
    });
    // 상대방의 마지막 메시지면 5초 후 힌트 숨기기
    if (!widget.message.isMe && widget.isLastPartnerMessage) {
      _startReactHintTimer();
    }
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 상대방의 마지막 메시지가 새로 도착했거나 변경되었을 때 타이머 재시작
    if (!widget.message.isMe && widget.isLastPartnerMessage) {
      // 이전에 마지막 메시지가 아니었거나, 메시지가 변경되었을 때 (timestamp 비교)
      if (!oldWidget.isLastPartnerMessage || 
          oldWidget.message.timestamp != widget.message.timestamp) {
        // 이전 타이머 취소
        _reactHintTimer?.cancel();
        // 상태 초기화 및 새 타이머 시작
        setState(() {
          _showReactHint = true;
        });
        _startReactHintTimer();
      }
    } else {
      // 더 이상 마지막 메시지가 아니면 타이머 취소 및 힌트 숨기기
      _reactHintTimer?.cancel();
      if (_showReactHint) {
        setState(() {
          _showReactHint = false;
        });
      }
    }
  }

  void _startReactHintTimer() {
    _reactHintTimer?.cancel();
    _reactHintTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showReactHint = false;
        });
      }
    });
  }

  void _startTracking() {
    if (_tracking) return;
    _tracking = true;
    _updateBubbleColor();
  }

  void _scheduleNextFrame() {
    if (!mounted || !_tracking) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBubbleColor());
  }

  void _updateBubbleColor() {
    if (!mounted) return;
    // 상대방 메시지에는 그라데이션 적용하지 않음
    if (!widget.message.isMe) {
      _tracking = false;
      return;
    }

    final renderBox = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      _scheduleNextFrame();
      return;
    }

    // 버블 중심 Y 위치 (글로벌)
    final bubblePosition = renderBox.localToGlobal(Offset.zero);
    final bubbleHeight = renderBox.size.height;
    final bubbleCenterGlobal = bubblePosition.dy + bubbleHeight / 2;

    // 뷰포트(스크롤 영역) 기준 좌표 계산
    final scrollableState = Scrollable.of(context);
    final viewportBox = scrollableState.context.findRenderObject() as RenderBox?;
    double ratio;
    if (viewportBox != null) {
      final viewportTopGlobal = viewportBox.localToGlobal(Offset.zero).dy;
      final viewportHeight = viewportBox.size.height;
      final centerInViewport = bubbleCenterGlobal - viewportTopGlobal;
      ratio = (centerInViewport / viewportHeight).clamp(0.0, 1.0);
    } else {
      // fallback: 전체 화면 기준
      final screenHeight = MediaQuery.of(context).size.height;
      ratio = (bubbleCenterGlobal / screenHeight).clamp(0.0, 1.0);
    }

    const topColor = Color(0xFF960097); // 화면 상단 색
    const bottomColor = Color(0xFF4438F0); // 화면 하단 색

    final newColor = Color.lerp(topColor, bottomColor, ratio) ?? topColor;
    if (newColor != _bubbleColor) {
      setState(() {
        _bubbleColor = newColor;
      });
    }

    // 다음 프레임 다시 계산 (스크롤/애니메이션 대응)
    _scheduleNextFrame();
  }

  @override
  void dispose() {
    _tracking = false;
    _reactHintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.message.isMe;

    // Supabase users에서 상대방 프로필 이미지 가져오기
    final users = ref.watch(usersProvider);
    final partnerUser = users[widget.partnerUsername] ?? 
                        ref.read(usersProvider.notifier).getUserByUsername(widget.partnerUsername);
    final String partnerProfileUrl = partnerUser?.profileImageUrl ?? 
                                     'assets/images/basic_image.jpg';

  final bool hasImages = (!kIsWeb) && (widget.message.images != null && widget.message.images!.isNotEmpty);
    
    // ⭐️ 사진 메시지 판별: text가 비어있고 현재 images가 없으면 "Photo" 표시
    // (앱 재시작이나 10분 경과로 AssetEntity가 사라진 경우)
    final bool isPhotoMessage = widget.message.text.isEmpty;
    final bool shouldShowPhotoText = isPhotoMessage && !hasImages;

    // 1. 메시지 버블 스타일 정의
    // 보라색 (사용자) 또는 밝은 회색 (상대방/Gemini)
    final Color bubbleColor = (hasImages || shouldShowPhotoText)
        ? (shouldShowPhotoText 
            ? (isMe ? _bubbleColor : Colors.grey[200]!)
            : Colors.transparent)
        : (isMe ? _bubbleColor : Colors.grey[200]!);
    final Color textColor = isMe ? Colors.white : Colors.black;

    // 2. 메시지 정렬 (Row의 MainAxisAlignment)
    final MainAxisAlignment alignment = isMe
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;

    // 3. 버블 모서리 둥글기 설정 (인스타그램 DM 스타일의 꼬리)
    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
      // 상대방 메시지 꼬리
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(
          18), // 내 메시지 꼬리
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        // 💡 Column 정렬: 사용자 메시지는 오른쪽, 상대방 메시지는 왼쪽
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment
            .start,
        children: [
          // 2. 메시지 버블과 시간 표시를 위한 기존 Row (주요 콘텐츠)
          Row(
            mainAxisAlignment: alignment, // 이전에 정의된 alignment 사용
            // 세로로 긴 이미지에서도 아이콘과 버블의 하단이 맞닿도록 정렬
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 4. 상대방 메시지일 경우에만 프로필 사진 표시
              if (!isMe) ...[
                CircleAvatar(
                  backgroundImage: partnerProfileUrl.startsWith('http')
                      ? CachedNetworkImageProvider(partnerProfileUrl)
                      : AssetImage(partnerProfileUrl) as ImageProvider,
                  radius: 14,
                ),
                const SizedBox(width: 8),
              ],

              // 5. 메시지 내용 (버블)
              Flexible(
                child: (hasImages && !shouldShowPhotoText && isMe)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ⭐️ 내가 보낸 사진 메시지일 경우 사진 왼쪽에 DM 아이콘 표시
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.send,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            key: _bubbleKey,
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: borderRadius,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _ImagesGrid(images: widget.message.images!),
                          ),
                        ],
                      )
                    : Container(
                        key: isMe ? _bubbleKey : null,
                        constraints: BoxConstraints(
                          // 화면 너비의 최대 75%만 사용
                          maxWidth: MediaQuery
                              .of(context)
                              .size
                              .width * 0.75,
                        ),
                        padding: (hasImages && !shouldShowPhotoText)
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: borderRadius, // 이전에 정의된 borderRadius 사용
                        ),
                        clipBehavior: (hasImages && !shouldShowPhotoText) ? Clip.antiAlias : Clip.none,
                        child: (hasImages && !shouldShowPhotoText)
                  ? _ImagesGrid(images: widget.message.images!)
                      : shouldShowPhotoText
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: textColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Photo',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              widget.message.text,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                ),
              ),


              // 상대방 메시지일 경우, 오른쪽에 여백을 추가하여 정렬을 맞춥니다.
              if (!isMe) const SizedBox(width: 40),
            ],
          ), // Row 끝

          // 3. ⭐️ 'Seen just now' 텍스트 표시 (내가 보낸 메시지)
          // 내가 보낸 메시지(isMe)이면서, 읽음 상태(widget.message.isSeen)이며,
          // 사용자 메시지 중 가장 마지막 메시지(widget.isLastUserMessage)일 때만 표시
          if (isMe && widget.message.isSeen && widget.isLastUserMessage)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 4.0, right: 8.0),
              // 오른쪽 정렬을 위해 right padding 사용
              child: Text(
                'Seen just now',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // 4. ⭐️ 'Tap and hold to react' 텍스트 표시 (상대방 메시지)
          // 상대방이 보낸 마지막 메시지(!isMe && widget.isLastPartnerMessage)일 때만 표시
          // 5초 후 자동으로 사라짐
          if (!isMe && widget.isLastPartnerMessage && _showReactHint)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 4.0, left: 50.0),
              // 프로필 사진 너비(28) + 간격(8) + 여백(14) = 약 50
              child: Text(
                'Tap and hold to react',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  final List images; // List<AssetEntity>
  const _ImagesGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || images.isEmpty) {
      return const SizedBox();
    }

    if (images.length == 1) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 250, // 최대 너비 250
          maxHeight: 250, // 최대 높이 250
        ),
        child: AspectRatio(
          aspectRatio: 9/14,
          child: AssetEntityImage(
            images.first,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(500),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // 2~4장 그리드 미리보기
    final int crossAxisCount = images.length == 2 ? 2 : 3;
    final int itemCount = images.length.clamp(0, 9); // 최대 9장 미리보기

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 250, // 최대 너비 250
        maxHeight: 250, // 최대 높이 250
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AssetEntityImage(
            images[index],
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(300),
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}