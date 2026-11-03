import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/widgets/post/post_header.dart';
import 'package:individual_project/widgets/post/post_action_bar.dart';
import 'package:individual_project/widgets/post/post_image_carousel.dart';
import 'package:individual_project/widgets/post/post_likes_and_caption.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/widgets/post/post_video.dart';
import 'package:individual_project/widgets/post/post_comments_bottom_sheet.dart';

class PostWidget extends ConsumerStatefulWidget {
  final String postID;

  const PostWidget({super.key, required this.postID});

  @override
  ConsumerState<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends ConsumerState<PostWidget> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // 다음 프레임에 초기화 실행 (위젯 빌드가 끝난 후)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final post = ref.read(postNotifierProvider(widget.postID));
        final isVideoPost = post.isReel || post.videoUrl != null;

        if (isVideoPost && post.videoUrl != null) {
          final videoPlayerNotifier = ref.read(
              videoPlayerProvider(widget.postID).notifier);
          videoPlayerNotifier.initialize(post.videoUrl!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(postNotifierProvider(widget.postID));
    final postNotifier = ref.read(postNotifierProvider(widget.postID).notifier);

    final onLikeTap = postNotifier.toggleLike;
    final onBookmarkTap = postNotifier.toggleBookmark;
    final onPageChangedCallback = postNotifier.changeCarouselPage;

    // 댓글 버튼 클릭 시 Bottom Sheet 띄우기
    void onCommentTap() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => PostCommentsBottomSheet(
            postId: widget.postID,
          ),
        ),
      );
    }

    final bool isVideoPost = post.isReel || post.videoUrl != null;

    final videoPlayerNotifier = ref.read(
        videoPlayerProvider(widget.postID).notifier);

    final videoPlayerState = ref.watch(videoPlayerProvider(widget.postID));

    final videoController = videoPlayerState.controller;
    final thumbnailData = videoPlayerState.thumbnailData;

    final Widget loadingOrThumbnailWidget = Container(
      height: MediaQuery
          .of(context)
          .size
          .width,
      color: Colors.black,
      child: thumbnailData != null
          ? Image.memory(
        thumbnailData,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      )
          : const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final Widget mainContent = isVideoPost
        ? (videoController != null && videoController.value.isInitialized
        ? PostVideo(
        postID: widget.postID,
        controller: videoController,
        notifier: videoPlayerNotifier,
        function: onLikeTap
    )
        : loadingOrThumbnailWidget
    )
        : PostImageCarousel(
      post: post,
      onPageChanged: onPageChangedCallback,
      onDoubleTapLike: onLikeTap,
    );

    if (post.isReel) {
      // ⭐️ 수정: Expanded 대신 고정 높이를 가지는 Container나 SizedBox 사용
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              height: MediaQuery
                  .of(context)
                  .size
                  .width*(6/5),
              width: double.infinity,
              child: Stack(
                children: [
                  // A. 영상/이미지 콘텐츠 (가장 아래에 배치, 부모 공간 차지)
                  SizedBox.expand(child: mainContent),

                  // 왼쪽 하단 사람 아이콘
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 18,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  // 오른쪽 하단 음소거 아이콘
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 18,
                      child: Icon(Icons.volume_off, color: Colors.white),
                    ),
                  ),

                  // B. PostHeader (상단에 겹쳐 배치)
                  Align(
                    alignment: Alignment.topLeft,
                    child: PostHeader(post: post),
                  ),
                ],
              )
          ),
          PostActionBar(
            post: post,
            currentPage: post.currentPageIndex,
            onLikeTap: onLikeTap,
            onBookmarkTap: onBookmarkTap,
            onCommentTap: onCommentTap,
          ),

          // 3. 캡션 및 구분선 (수직으로 계속 쌓임)
          PostLikesAndCaption(post: post),
        ],
      );
    } else {
      // 4. 일반 피드 형식일 경우 (기존 Column 구조 유지)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(post: post),
          mainContent,
          PostActionBar(
            post: post,
            currentPage: post.currentPageIndex,
            onLikeTap: onLikeTap,
            onBookmarkTap: onBookmarkTap,
            onCommentTap: onCommentTap,
          ),
          PostLikesAndCaption(post: post),
        ],
      );
    }
  }
}