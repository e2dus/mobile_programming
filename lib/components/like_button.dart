import 'package:flutter/material.dart';

class LikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 💡 애니메이션 컨트롤러 초기화 (지속 시간은 인스타그램과 유사하게 짧게 설정)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // 💡 크기 애니메이션 정의 (1.0 -> 1.2 -> 1.0으로 커졌다 돌아오는 효과)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 33),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.5), weight: 33),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 33),// 1.0 -> 1.2 (커짐)// 1.2 -> 1.0 (돌아옴)
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runAnimationInternal() {
    _controller.forward(from: 0.0);
  }

  // 💡 버튼 탭 시 실행되는 로직
  void _handleTap() {
    widget.onTap();
  }

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 💡 이전 상태가 '좋아요 아님'이고 새 상태가 '좋아요'일 때만 애니메이션 실행
    final wasNotLiked = oldWidget.isLiked; // 이전 상태: false
    final isNowLiked = widget.isLiked;      // 현재 상태: true

    if ((!wasNotLiked && isNowLiked) || (wasNotLiked && !isNowLiked)) {
      _runAnimationInternal();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 ScaleTransition을 사용하여 아이콘을 감쌉니다.
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: Icon(
          widget.isLiked ? Icons.favorite : Icons.favorite_border,
          color: widget.isLiked ? Colors.red : Colors.black,
          size: 28,
        ),
      ),
    );
  }
}