import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/providers/app_providers.dart';

class PostNewPostNotification extends ConsumerStatefulWidget {
  const PostNewPostNotification({super.key});

  @override
  ConsumerState<PostNewPostNotification> createState() => _PostNewPostNotificationState();
}

class _PostNewPostNotificationState extends ConsumerState<PostNewPostNotification> {
  bool _hasShownOnce = false;
  int? _lastSeenTabIndex;

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(newPostUploadedProvider);
    final shouldShow = uploadState['shouldShow'] as bool? ?? false;
    final imageUrl = uploadState['imageUrl'] as String?;
    final currentTabIndex = ref.watch(bottomNavIndexProvider);

    debugPrint('[PostNotification] Building... shouldShow=$shouldShow, imageUrl=$imageUrl, currentTab=$currentTabIndex, _hasShownOnce=$_hasShownOnce, _lastSeenTabIndex=$_lastSeenTabIndex');

    // 탭이 변경되었는지 확인 (피드 탭=0)
    if (_lastSeenTabIndex != null && _lastSeenTabIndex != 0 && currentTabIndex == 0) {
      // 다른 탭에서 피드로 돌아온 경우
      if (_hasShownOnce) {
        // 이미 한 번 표시했으면 플래그 초기화
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(newPostUploadedProvider.notifier).state = {
            'shouldShow': false,
            'imageUrl': null,
          };
          debugPrint('[PostNotification] 🔄 Flag cleared (returned to feed after showing notification)');
        });
      }
    }
    _lastSeenTabIndex = currentTabIndex;

    // shouldShow=true이고 아직 표시 안 했으면 표시
    if (shouldShow && imageUrl != null && currentTabIndex == 0) {
      if (!_hasShownOnce) {
        _hasShownOnce = true;
        debugPrint('[PostNotification] ✅ Showing notification!');
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // 왼쪽 썸네일 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 36,
                    height: 36,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 18, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // 텍스트
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Posted! Way to go.',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Want to send it to friends?',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 오른쪽 Send 버튼
            ElevatedButton(
              onPressed: () {
                // TODO: 친구에게 전송 기능
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Send',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // shouldShow=false이거나 이미 표시했으면 숨김
    if (!shouldShow && _hasShownOnce) {
      _hasShownOnce = false; // 다음 업로드를 위해 리셋
      _lastSeenTabIndex = null;
      debugPrint('[PostNotification] 🔄 Reset state for next upload');
    }
    
    return const SizedBox.shrink();
  }
}
