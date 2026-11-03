import 'package:flutter/material.dart';

class PostIndicator extends StatelessWidget {
  final int totalPages;
  final int currentPage;

  const PostIndicator({
    super.key,
    required this.totalPages,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    // 이미지가 한 장일 때는 인디케이터를 표시하지 않습니다.
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // 필요한 만큼만 공간을 차지하게 함
      children: List.generate(
        totalPages,
            (index) => Container(
          width: 6.0,
          height: 6.0,
          margin: const EdgeInsets.symmetric(horizontal: 3.0), // 간격 줄임
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index
                ? Theme.of(context).colorScheme.primary // 현재 페이지는 파란색
                : Colors.grey.withOpacity(0.4), // 나머지는 흐릿한 회색
          ),
        ),
      ),
    );
  }
}