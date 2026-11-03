import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/post_model.dart';
import 'post_indicator.dart'; // 새로 만든 인디케이터 위젯
import 'package:individual_project/components/like_button.dart';

class PostActionBar extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLikeTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback? onCommentTap;
  final int currentPage;

  const PostActionBar({
    super.key,
    required this.post,
    required this.currentPage,
    required this.onLikeTap,
    required this.onBookmarkTap,
    this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 10.0, top: 2.0, bottom: 2.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 중앙 인디케이터 (최상위에 배치하여 완전 중앙)
          Center(
            child: PostIndicator(
              totalPages: post.postImageUrls.length,
              currentPage: post.currentPageIndex,
            ),
          ),
          
          // 왼쪽, 오른쪽 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. 왼쪽 액션 버튼 그룹
              Row(
                children: [
                  // 좋아요 (하트) 버튼 - 토글 상태 반영 필요
                  LikeButton(
                    isLiked: post.isLiked,
                    onTap: onLikeTap,
                  ),
                  SizedBox(width: 15.w),
                  // 댓글 버튼: 이미지 에셋 대신 아이콘 사용
                  IconButton(
                    onPressed: onCommentTap,
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.black,
                      size: 28,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: 3.w),
                  // 리포스트 버튼
                  Transform.flip(
                    flipY: true,
                    child: IconButton(
                      icon: const Icon(Icons.repeat, color: Colors.black, size: 28),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  // 공유/DM 버튼
                  IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      'assets/icons/dm_instagram.svg',
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              // 2. 오른쪽 저장(북마크) 버튼
              IconButton(
                onPressed: onBookmarkTap,
                icon: SvgPicture.asset(
                  post.isBookmarked ? 'assets/icons/ic_bookmark_clicked.svg' : 'assets/icons/ic_bookmark.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}