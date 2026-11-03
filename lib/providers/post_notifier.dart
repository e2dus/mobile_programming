
import 'package:flutter_riverpod/legacy.dart';
import '../models/post_model.dart';

class PostNotifier extends StateNotifier<PostModel> {
  PostNotifier(super.state);

  // 1. 좋아요 상태 토글 로직
  void toggleLike() {
    state = state.copyWith(
      isLiked: !state.isLiked,
      likesCount: state.isLiked ? state.likesCount - 1 : state.likesCount + 1,
    );
  }
  // 2. 북마크 상태 토글 로직
  void toggleBookmark() {
    state = state.copyWith(
      isBookmarked: !state.isBookmarked,
    );
  }

  // 3. 캐러셀 페이지 변경 로직
  void changeCarouselPage(int newIndex) {
    state = state.copyWith(
      currentPageIndex: newIndex,
    );
  }

}