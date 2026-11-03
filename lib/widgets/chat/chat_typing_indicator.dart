// lib/widgets/chat/typing_indicator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:individual_project/providers/app_providers.dart';

// 타이핑 인디케이터 전체 위젯 (상태 관리 및 애니메이션을 위해 StatefulWidget 사용)
class TypingIndicator extends ConsumerStatefulWidget {
  final String partnerUsername; // 상대방 username (users 테이블 조회용)

  const TypingIndicator({super.key, required this.partnerUsername});

  @override
  ConsumerState<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends ConsumerState<TypingIndicator> with SingleTickerProviderStateMixin {

  // 💡 애니메이션 컨트롤러
  late AnimationController _controller;

  // 💡 각 점의 초기 위치(Y축) 오프셋
  final double _dotBaseY = -1.5;
  final double _dotBounceAmount = 3.5; // 점이 위로 튀어오르는 최대 높이 (단일 줄 높이 유지)
  final int _dotCount = 3;

  // 💡 각 점에 대한 Animation 객체 리스트
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();

    // 1. AnimationController 초기화 (전체 애니메이션 시간 및 반복 설정)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(); // 애니메이션 반복

    // 2. 각 점에 대한 개별 Animation 설정 (시간차를 둠)
    _dotAnimations = List.generate(_dotCount, (index) {
      final begin = index * (1 / _dotCount); // 각 점의 시작 오프셋 (0.0, 0.33, 0.66)
      final end = 1.0;

      // CurvedAnimation을 사용하여 부드러운 상하 움직임 구현
      final interval = Interval(begin, end, curve: Curves.easeInOutSine);

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: interval,
        ),
      );
    });
  }

  // 💡 점 하나를 렌더링하는 위젯
  Widget _buildDot(int index) {
    // 3. Transform.translate와 Animation을 사용하여 Y축 위치 변경
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // sine 함수를 사용하여 물결처럼 움직이는 효과를 구현
        final value = _dotAnimations[index].value;
        final sineValue = 1 - (2 * value - 1).abs();
        final translateY = _dotBaseY + _dotBounceAmount * sineValue;

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Container(
            width: 6.0,
            height: 6.0,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Supabase users에서 상대방 프로필 이미지 가져오기
    final users = ref.watch(usersProvider);
    final partnerUser = users[widget.partnerUsername] ?? 
                        ref.read(usersProvider.notifier).getUserByUsername(widget.partnerUsername);
    final String partnerProfileUrl = partnerUser?.profileImageUrl ?? 
                                     'assets/images/basic_image.jpg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, // 프로필 사진과 정렬을 맞춥니다.
        children: [
          // 1. 상대방 프로필 사진 (assets/network 자동 구분)
          CircleAvatar(
            backgroundImage: partnerProfileUrl.startsWith('http')
                ? CachedNetworkImageProvider(partnerProfileUrl)
                : AssetImage(partnerProfileUrl) as ImageProvider,
            radius: 14,
          ),
          const SizedBox(width: 8),

          // 2. 입력 중 상태 말풍선
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 17.7),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              // ⭐️ 점 세 개를 표시
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}