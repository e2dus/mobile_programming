import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'reel_player_item.dart';

class SuggestedReels extends StatefulWidget {
  const SuggestedReels({super.key});

  @override
  State<SuggestedReels> createState() => _SuggestedReelsState();
}

class _SuggestedReelsState extends State<SuggestedReels> {
  late final Future<List<String>> _reelsFuture;
  final Map<int, double> _visibleFractions = {};
  int? _currentIndex;

  @override
  void initState() {
    super.initState();
    _reelsFuture = _fetchReels();
    _currentIndex = 0; // 초기값 설정
  }

  Future<List<String>> _fetchReels() async {
    // 로컬 비디오 파일만 사용
    return const [
      'assets/images/video1.mp4',
      'assets/images/video2.mp4',
      'assets/images/video3.mp4',
    ];
  }

  void _updateActiveFromVisibility() {
    if (_visibleFractions.isEmpty) return;
    // fully visible (>= 0.98). choose smallest index (leftmost)
  final candidates = _visibleFractions.entries
    .where((e) => e.value >= 0.8)
        .map((e) => e.key)
        .toList()
      ..sort();
    if (candidates.isEmpty) return;
    final leftMost = candidates.first;
    if (_currentIndex != leftMost) {
      setState(() => _currentIndex = leftMost);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Suggested reels', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Icon(Icons.more_vert),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: FutureBuilder<List<String>>(
              future: _reelsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
                }
                if (snapshot.hasError) {
                  debugPrint('[Reels] snapshot error: ${snapshot.error}');
                }
                var urls = snapshot.data ?? const [
                  'assets/images/video1.mp4',
                  'assets/images/video2.mp4',
                  'assets/images/video3.mp4',
                ];
                // 초기 활성 인덱스는 0으로
                _currentIndex ??= 0;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final url = urls[index];
                    final isActive = _currentIndex == index;
                    // 모든 릴스를 미리 로드 (썸네일 표시)
                    final shouldPreload = true;
                    
                    return AspectRatio(
                      aspectRatio: 9 / 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: VisibilityDetector(
                          key: Key('reel-$index'),
                          onVisibilityChanged: (info) {
                            _visibleFractions[index] = info.visibleFraction;
                            _updateActiveFromVisibility();
                          },
                          child: ReelPlayerItem(
                            url: url,
                            isActive: isActive,
                            shouldPreload: shouldPreload,
                            onEnded: () {
                              // 마지막 영상이면 처음으로, 아니면 다음으로
                              if (index == urls.length - 1) {
                                setState(() => _currentIndex = 0);
                              } else {
                                // 다음 인덱스로 순서대로 이동
                                setState(() => _currentIndex = index + 1);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
