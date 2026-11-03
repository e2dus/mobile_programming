import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelPlayerItem extends StatefulWidget {
  final String url;
  final bool isActive;
  final bool shouldPreload; // 현재 ±1개만 로드
  final VoidCallback? onEnded;

  const ReelPlayerItem({
    super.key, 
    required this.url, 
    required this.isActive, 
    this.shouldPreload = false,
    this.onEnded,
  });

  @override
  State<ReelPlayerItem> createState() => _ReelPlayerItemState();
}

class _ReelPlayerItemState extends State<ReelPlayerItem> {
  VideoPlayerController? _controller;
  bool _completedNotified = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    // shouldPreload가 true일 때만 초기화 (현재 ±1개만)
    if (widget.shouldPreload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureInitialized();
      });
    }
  }

  Future<void> _ensureInitialized() async {
    if (_controller != null || _isInitializing) return;
    _isInitializing = true;
    
    // 네트워크 URL이 아닌, 프로젝트 assets 경로일 수도 있음
    late final VideoPlayerController c;
    final src = widget.url;
    if (src.startsWith('assets/')) {
      // Flutter assets 동영상
      c = VideoPlayerController.asset(src);
    } else if (src.startsWith('http')) {
      // 원격 URL 동영상
      c = VideoPlayerController.networkUrl(Uri.parse(src));
    } else {
      // 기본: 네트워크 URL로 시도 (형식이 명확하지 않은 경우)
      c = VideoPlayerController.networkUrl(Uri.parse(src));
    }
    
    try {
      await c.initialize();
      c.setLooping(false);
      c.addListener(_onTick);
      if (mounted) {
        setState(() => _controller = c);
        // 활성 상태라면 즉시 재생 시작
        if (widget.isActive) {
          _completedNotified = false;
          c.play();
        }
      }
    } catch (e) {
      debugPrint('[ReelPlayerItem] Error initializing video: $e');
    } finally {
      _isInitializing = false;
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null) return;
    final v = c.value;
    if (!v.isInitialized) return;
    if (!_completedNotified && !v.isPlaying && v.position >= v.duration && widget.onEnded != null) {
      _completedNotified = true;
      widget.onEnded!();
    }
  }

  @override
  void didUpdateWidget(covariant ReelPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // shouldPreload가 true로 변경되면 초기화 시작
    if (widget.shouldPreload && !oldWidget.shouldPreload && _controller == null) {
      _ensureInitialized();
    }
    
    // 컨트롤러가 있으면 isActive 상태에 따라 재생/일시정지만 제어
    // dispose는 절대 하지 않음 (썸네일 유지)
    if (_controller != null) {
      if (widget.isActive && !_controller!.value.isPlaying) {
        _completedNotified = false;
        _controller!.play();
      } else if (!widget.isActive && _controller!.value.isPlaying) {
        _controller!.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_controller == null || !_controller!.value.isInitialized)
          Container(color: const Color(0xFFEDEDED))
        else
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        // gradient top for menu dots aesthetics
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x00000000)],
                ),
              ),
              child: SizedBox(height: 40),
            ),
          ),
        ),
        const Positioned(
          top: 8,
          right: 8,
          child: Icon(Icons.more_vert, color: Colors.white),
        )
      ],
    );
  }
}
