import 'dart:typed_data';
import 'package:video_player/video_player.dart';

class VideoPlayerState {
  final VideoPlayerController? controller;
  final Uint8List? thumbnailData;
  final bool isLoadingThumbnail;

  VideoPlayerState({
    this.controller,
    this.thumbnailData,
    this.isLoadingThumbnail = false,
  });

  VideoPlayerState copyWith({
    VideoPlayerController? controller,
    Uint8List? thumbnailData,
    bool? isLoadingThumbnail,
  }) {
    return VideoPlayerState(
      controller: controller ?? this.controller,
      thumbnailData: thumbnailData,
      isLoadingThumbnail: isLoadingThumbnail ?? this.isLoadingThumbnail,
    );
  }
}