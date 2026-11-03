import 'dart:typed_data';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart'; // 썸네일 생성 패키지
import 'package:individual_project/states/video_player_state.dart'; // 상태 import
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/foundation.dart';

class VideoPlayerNotifier extends StateNotifier<VideoPlayerState> {
  final String postID;

  VideoPlayerNotifier(this.postID) : super(VideoPlayerState());

  // 간단한 메모리 캐시 (URL -> 썸네일 바이트)
  static final Map<String, Uint8List?> _thumbnailCache = <String, Uint8List?>{};

  // 썸네일 생성 로직 (메인 isolate에서 실행)
  Future<void> _createThumbnail(String videoUrl) async {
    if (state.isLoadingThumbnail || state.thumbnailData != null) return;

    // 캐시에 있으면 즉시 사용
    if (_thumbnailCache.containsKey(videoUrl)) {
      state = state.copyWith(
        thumbnailData: _thumbnailCache[videoUrl],
        isLoadingThumbnail: false,
      );
      return;
    }

    state = state.copyWith(isLoadingThumbnail: true);

    try {
      // 지원되지 않는 플랫폼(web/desktop 등)에서는 건너뜁니다.
      final isSupportedPlatform = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

      if (!isSupportedPlatform) {
        // 지원되지 않는 경우 썸네일 없이 진행
        state = state.copyWith(isLoadingThumbnail: false);
        _thumbnailCache[videoUrl] = null;
        return;
      }

      // 메인 isolate에서 직접 생성 (MethodChannel 필요)
      final data = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        quality: 75,
      );

      state = state.copyWith(
        thumbnailData: data,
        isLoadingThumbnail: false,
      );
      _thumbnailCache[videoUrl] = data;
    } catch (e) {
      debugPrint('Video $postID - Thumbnail creation failed: $e');
      state = state.copyWith(isLoadingThumbnail: false);
    }
  }

  // 컨트롤러 초기화 및 영상 로드
  Future<void> initialize(String videoUrl) async {
    // 이미 초기화된 컨트롤러가 있고 같은 URL이면 재시도하지 않음
    if (state.controller != null && state.controller!.value.isInitialized) {
      return;
    }

    // 기존 컨트롤러가 있지만 초기화 실패한 경우 정리
    if (state.controller != null && !state.controller!.value.isInitialized) {
      try {
        await state.controller!.dispose();
      } catch (e) {
        debugPrint('Video $postID - Error disposing failed controller: $e');
      }
    }

      // 썸네일 생성은 비동기로 시작만 하고 기다리지는 않습니다.
      _createThumbnail(videoUrl);

    VideoPlayerController? controller;
      try {
      controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await controller.initialize();
        controller.setLooping(true);

        state = state.copyWith(
          controller: controller,
          isLoadingThumbnail: false,
        );
      } catch (e) {
      debugPrint('Video $postID - Controller initialization failed: $e');
      // 실패한 컨트롤러 정리
      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {}
      }
      state = state.copyWith(
        controller: null,
        isLoadingThumbnail: false,
      );
    }
  }

  // 재생
  void play() {
    if (state.controller != null && !state.controller!.value.isPlaying) {
      state.controller!.play();
    }
  }

  // 일시정지
  void pause() {
    if (state.controller != null && state.controller!.value.isPlaying) {
      state.controller!.pause();
    }
  }

  // 해제
  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}