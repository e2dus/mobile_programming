import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post_model.dart';

class PostImageCarousel extends StatefulWidget {
  final PostModel post;
  final Function(int) onPageChanged;
  final VoidCallback onDoubleTapLike;

  const PostImageCarousel({
    super.key,
    required this.post,
    required this.onPageChanged,
    required this.onDoubleTapLike,
  });

  @override
  // 💡 1. 애니메이션 컨트롤러를 사용하기 위해 SingleTickerProviderStateMixin을 추가합니다.
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  late final PageController _pageController;

  // 💡 2. 하트 애니메이션을 위한 컨트롤러와 애니메이션 정의
  late final AnimationController _heartAnimationController;
  late final Animation<double> _heartScaleAnimation;
  late final Animation<double> _heartOpacityAnimation;
  late final Animation<double> _rippleScaleAnimation;
  late final Animation<double> _rippleOpacityAnimation;

  // 하트 애니메이션 중인지 확인하는 플래그
  bool _isHeartAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 💡 AnimationController 초기화 (지속 시간: 1000ms)
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 💡 크기/투명도/회전/리플 애니메이션 정의 (천천히 등장 + 길게 유지 + 빠른 소멸)
    final curved = CurvedAnimation(parent: _heartAnimationController, curve: Curves.easeOutCubic);

    // --- 💖 하트 크기 애니메이션 수정 ---
    // 총 weight: 10 + 120 + 5 + 5 + 10 = 150
    _heartScaleAnimation = TweenSequence<double>([
      // 1. 천천히 등장: weight를 줄여 느린 듯한 효과
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 30),
      // 2. 크기 유지: weight를 대폭 늘려 가장 오랜 시간 크기 유지
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.15), weight: 100),
      // 3. 빠르게 소멸: 남은 단계를 빠르게 처리
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.0), weight: 10), // 0.0으로 빠르게 소멸
    ]).animate(curved);

    // --- 💖 하트 투명도 애니메이션 수정 ---
    // 총 weight: 10 + 120 + 20 = 150
    _heartOpacityAnimation = TweenSequence<double>([
      // 1. 천천히 등장: weight를 줄여 천천히 불투명해지도록
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      // 2. 투명도 유지: weight를 대폭 늘려 불투명 상태를 길게 유지
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 100),
      // 3. 빠르게 소멸: weight를 줄여 빠르게 투명하게 사라지도록
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(curved);

    // --- 💧 리플 애니메이션 유지 (하트 등장 시 순간 효과) ---
    _rippleScaleAnimation = Tween<double>(begin: 0.6, end: 1.6).animate(
      CurvedAnimation(parent: _heartAnimationController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _rippleOpacityAnimation = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _heartAnimationController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    // 💡 애니메이션 완료 시 상태를 리셋하여 하트를 숨깁니다.
    _heartAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isHeartAnimating = false;
        });
        _heartAnimationController.reset();
      }
    });
  }

  // 💡 3. 하트 애니메이션 시작 함수
  void _startHeartAnimation() {
    if (widget.post.isLiked) {
      return; // 좋아요 취소 및 애니메이션 실행을 막습니다.
    }
    // 좋아요 토글 로직을 먼저 호출합니다.
    widget.onDoubleTapLike();

    setState(() {
      _isHeartAnimating = true;
    });
    // 애니메이션 실행
    _heartAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimationController.dispose(); // 💡 컨트롤러 해제 필수!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildImageSlider(context),
      ],
    );
  }

  Widget _buildImageSlider(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.width*(6/5),
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          // 💡 onDoubleTap에 애니메이션 시작 함수 연결
          GestureDetector(
            onDoubleTap: _startHeartAnimation, // <--- 여기서 애니메이션 시작
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.post.postImageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                widget.onPageChanged(index);
              },
              itemBuilder: (context, index) {
                final url = widget.post.postImageUrls[index];
                final isNetwork = url.startsWith('http');
                if (isNetwork) {
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image),
                    ),
                    memCacheWidth: 1080, // 메모리 최적화
                    maxWidthDiskCache: 1080, // 디스크 캐시 최적화
                  );
                } else {
                  return Image.asset(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.error));
                    },
                  );
                }
              },
            ),
          ),

          if (widget.post.postImageUrls.length > 1)
            _buildMultiplePhotoIcon(),

          // 💡 4. 하트 애니메이션 위젯 (리플 + 회전 + 오버슈트)
          if (_isHeartAnimating)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FadeTransition(
                    opacity: _rippleOpacityAnimation,
                    child: ScaleTransition(
                      scale: _rippleScaleAnimation,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _heartOpacityAnimation,
                    child: ScaleTransition(
                      scale: _heartScaleAnimation,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 150,
                        shadows: [
                          BoxShadow(color: Colors.black54, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMultiplePhotoIcon() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          '${_currentPage + 1}/${widget.post.postImageUrls.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}