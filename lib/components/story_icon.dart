import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryIcon extends StatelessWidget {
  final String profileImageUrl;
  final String username;
  final bool hasViewed;
  final bool isMyStory;
  final VoidCallback onTap;
  final double size;
  final bool isMainPageStory;

  const StoryIcon({
    super.key,
    required this.profileImageUrl,
    required this.username,
    this.hasViewed = false,
    this.isMyStory = false,
    required this.onTap,
    this.isMainPageStory = true,
    this.size = 70,
  });

  static const List<Color> _unviewedGradientColors = [
    Color(0xFFfeda75),
    Color(0xFFfa7e1e),
    Color(0xFFd62976),
    Color(0xFF962fbf),
    Color(0xFF4f5bd5),
  ];

  // 🚨 기본 이미지 경로 설정 (프로젝트 경로에 맞게 수정 필요)
  static const String _defaultAssetPath = 'assets/images/basic_image.jpg';

  @override
  Widget build(BuildContext context) {
    final bool applyGradient = !hasViewed && !isMyStory;

    // Outer size is configurable by `size`
    final double outerSize = size;

    // ----------------------------------------------------
    // ✨ 핵심 1: 두께 및 간격 정의
    // ----------------------------------------------------
    const double borderThickness = 2.5;     // 그라데이션/회색 선의 두께
    const double whiteGapThickness = 3.0;   // 테두리와 사진 사이의 흰색 간격 두께

    // ✨ 핵심 2: Avatar Radius 재계산
    // 전체 크기에서 테두리 두께와 흰색 간격 두께를 모두 제외
    final double avatarRadius =
        (outerSize - (borderThickness * 2) - (whiteGapThickness * 2)) / 2;

    // 프로필 사진 로직을 담는 위젯 정의
    final Widget profileContent = SizedBox(
      width: outerSize,
      height: outerSize,

      // 3. 바깥쪽 Container: 테두리 역할
      child: Container(
        padding: const EdgeInsets.all(borderThickness),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 회색 테두리 또는 투명 테두리 (Gradient 아닐 때)
          border: !applyGradient
              ? Border.all(
            color: (hasViewed || isMyStory) ? Colors.grey.shade400 : Colors.transparent,
            width: borderThickness,
          )
              : null,
          // 그라데이션 테두리 (Gradient 일 때)
          gradient: applyGradient
              ? const LinearGradient(
            colors: _unviewedGradientColors,
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          )
              : null,
        ),

        // 4. 내부 Container: 흰색 간격의 배경
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white, // 흰색 간격을 만들어 주는 배경색
          ),

          // 5. Padding: 흰색 간격 두께 결정
          child: Padding(
            padding: EdgeInsets.all((hasViewed || isMyStory)?whiteGapThickness*0.2:whiteGapThickness),

            // 6. 실제 프로필 사진 렌더링 (CircleAvatar 대신 ClipOval과 Image 위젯 조합)
            child: ClipOval( // 이미지를 원형으로 자르기
              child: profileImageUrl.startsWith('http')
                  ? CachedNetworkImage( // 네트워크 이미지일 경우 로딩 상태 제어
                imageUrl: profileImageUrl,
                fit: BoxFit.cover,
                width: avatarRadius * 2,
                height: avatarRadius * 2,

                // ✨ 로딩 중 Assets 기본 이미지 띄우기
                placeholder: (context, url) => Image.asset(
                  _defaultAssetPath,
                  fit: BoxFit.cover,
                ),

                // ✨ 로딩 실패 시 Assets 기본 이미지 띄우기
                errorWidget: (context, url, error) => Image.asset(
                  _defaultAssetPath,
                  fit: BoxFit.cover,
                ),
              )
                  : Image.asset( // Assets 이미지일 경우
                profileImageUrl,
                fit: BoxFit.cover,
                width: avatarRadius * 2,
                height: avatarRadius * 2,
              ),
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: outerSize,
              height: outerSize,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  profileContent,
                  if (isMyStory)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),

            if (isMainPageStory) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: outerSize,
                child: Text(
                  username,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}