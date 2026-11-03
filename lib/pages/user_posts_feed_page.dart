import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/widgets/post/post_widget.dart';
import 'package:individual_project/providers/app_providers.dart';

/// Feed page showing only posts from a specific user
/// Similar to instagram_feed_screen but filtered by username
class UserPostsFeedPage extends ConsumerStatefulWidget {
  final String username;
  final String? initialPostId; // 클릭한 게시물 ID

  const UserPostsFeedPage({
    super.key,
    required this.username,
    this.initialPostId,
  });

  @override
  ConsumerState<UserPostsFeedPage> createState() => _UserPostsFeedPageState();
}

class _UserPostsFeedPageState extends ConsumerState<UserPostsFeedPage> {
  late final ScrollController _scrollController;
  bool _hasInitializedScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToInitialPost(List<dynamic> userPosts) {
    if (widget.initialPostId == null || _hasInitializedScroll) return;
    
    final index = userPosts.indexWhere((post) => post.id == widget.initialPostId);
    if (index == -1) {
      _hasInitializedScroll = true;
      return;
    }
    
    // ListView가 빌드된 후 즉시 점프 (애니메이션 없음)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasInitializedScroll) return;
      
      // ListView가 렌더링될 시간을 주되, 애니메이션은 없음
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted || !_scrollController.hasClients || _hasInitializedScroll) return;
        
        // 각 PostWidget의 대략적인 높이를 계산 (화면 높이 기준)
        final screenHeight = MediaQuery.of(context).size.height;
        final estimatedPostHeight = screenHeight * 0.85; // 대략적인 게시물 높이
        final targetOffset = index * estimatedPostHeight;
        
        // jumpTo를 사용하여 애니메이션 없이 즉시 이동
        _scrollController.jumpTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
        _hasInitializedScroll = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final allPosts = ref.watch(postsProvider);
    
    // Filter posts by username and sort by time (same as profile screen)
    final userPosts = allPosts.where((post) => post.username == widget.username).toList();
    
    // Sort by time descending (same as profile screen)
    int _compareByTimeDesc(a, b) {
      DateTime parseSafe(String s) {
        try { return DateTime.parse(s); } catch (_) { return DateTime.fromMillisecondsSinceEpoch(0); }
      }
      return parseSafe(b.timeAgo).compareTo(parseSafe(a.timeAgo));
    }
    userPosts.sort(_compareByTimeDesc);
    
    // Jump to initial post if needed (애니메이션 없이)
    if (widget.initialPostId != null && !_hasInitializedScroll) {
      _jumpToInitialPost(userPosts);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Photo',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: userPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Posts Yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When ${widget.username} shares photos, you\'ll see them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: userPosts.length,
              itemBuilder: (context, index) {
                final post = userPosts[index];
                return PostWidget(postID: post.id);
              },
            ),
    );
  }
}
