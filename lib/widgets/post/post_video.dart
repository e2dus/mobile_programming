import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:individual_project/providers/video_player_notifier.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PostVideo extends StatefulWidget {
  final String postID;
  final VideoPlayerController controller;
  final VoidCallback function;
  final VideoPlayerNotifier notifier;

  const PostVideo({
    super.key,
    required this.postID,
    required this.controller,
    required this.notifier,
    required this.function,
  });

  @override
  State<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo> {
  @override
  void initState() {
    super.initState();
    // 첫 로드 시에도 자동 재생 시도
    if (widget.controller.value.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.notifier.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('feed-video-post-${widget.postID}'),
      onVisibilityChanged: (visibilityInfo) {
        final visiblePercentage = visibilityInfo.visibleFraction * 100;

        if (widget.controller.value.isInitialized) {
          if (visiblePercentage > 70) {
            widget.notifier.play();
          } else if (visiblePercentage < 30) {
            widget.notifier.pause();
          }
        }
      },
      child: _VideoPlayerContent(
        postID: widget.postID,
        controller: widget.controller,
        notifier: widget.notifier,
        onDoubleTap: widget.function,
      ),
    );
  }
}

class _VideoPlayerContent extends StatefulWidget {
  final String postID;
  final VideoPlayerController controller;
  final VideoPlayerNotifier notifier;
  final VoidCallback onDoubleTap;

  const _VideoPlayerContent({
    required this.postID,
    required this.controller,
    required this.notifier,
    required this.onDoubleTap,
  });

  @override
  State<_VideoPlayerContent> createState() => _VideoPlayerContentState();
}

class _VideoPlayerContentState extends State<_VideoPlayerContent> {
  bool _hasAutoPlayed = false;

  @override
  void initState() {
    super.initState();
    // 컨트롤러가 이미 초기화되어 있으면 자동 재생
    if (widget.controller.value.isInitialized) {
      _scheduleAutoPlay();
    } else {
      // 초기화 대기
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void didUpdateWidget(_VideoPlayerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 컨트롤러가 변경되었거나 새로 초기화된 경우
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      if (widget.controller.value.isInitialized && !_hasAutoPlayed) {
        widget.controller.addListener(_onControllerUpdate);
        _scheduleAutoPlay();
      } else if (!widget.controller.value.isInitialized) {
        widget.controller.addListener(_onControllerUpdate);
      }
    } else if (widget.controller.value.isInitialized && !oldWidget.controller.value.isInitialized && !_hasAutoPlayed) {
      // 같은 컨트롤러지만 이제 초기화됨
      _scheduleAutoPlay();
    }
  }

  void _scheduleAutoPlay() {
    if (!_hasAutoPlayed && widget.controller.value.isInitialized && mounted) {
      // 여러 단계로 재생 시도
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasAutoPlayed && widget.controller.value.isInitialized) {
          widget.notifier.play();
          _hasAutoPlayed = true;
        }
      });
      // 백업: 약간의 지연 후에도 재생 시도
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_hasAutoPlayed && widget.controller.value.isInitialized) {
          widget.notifier.play();
          _hasAutoPlayed = true;
        }
      });
    }
  }

  void _onControllerUpdate() {
    if (widget.controller.value.isInitialized && !_hasAutoPlayed && mounted) {
      widget.controller.removeListener(_onControllerUpdate);
      _scheduleAutoPlay();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // build에서도 자동 재생 시도 (컨트롤러가 초기화되었는데 아직 재생 안 된 경우)
    if (widget.controller.value.isInitialized && !_hasAutoPlayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasAutoPlayed && widget.controller.value.isInitialized) {
          widget.notifier.play();
          _hasAutoPlayed = true;
        }
      });
    }

    if (widget.controller.value.isInitialized) {
      return GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          height: MediaQuery.of(context).size.width,
          width: double.infinity,
          color: Colors.black,
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: VideoPlayer(widget.controller),
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

