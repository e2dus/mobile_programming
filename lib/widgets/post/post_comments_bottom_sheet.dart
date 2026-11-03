import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/providers/notifications_provider.dart';
import 'package:individual_project/models/comment_model.dart';
import 'package:individual_project/utils/time_ago_en.dart';
import 'package:individual_project/components/like_button.dart';

class PostCommentsBottomSheet extends ConsumerStatefulWidget {
  final String postId;
  const PostCommentsBottomSheet({super.key, required this.postId});
  @override
  ConsumerState<PostCommentsBottomSheet> createState() => _PostCommentsBottomSheetState();
}

class _PostCommentsBottomSheetState extends ConsumerState<PostCommentsBottomSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _hintMessage;
  String? _replyingToUsername;
  int? _replyingToCommentId;
  final GlobalKey _stackKey = GlobalKey();
  final Map<int, GlobalKey> _heartKeys = {}; // commentId -> GlobalKey for heart
  Offset? _hintOffset; // relative to Stack (top-left of heart icon)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    // Text listener
    _commentController.addListener(() {
      setState(() => _hasText = _commentController.text.trim().isNotEmpty);
    });

    // 댓글을 열 때마다 최신 댓글 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 전체 댓글을 다시 로드하여 최신 상태 유지
      ref.read(commentsProvider.notifier).loadAllComments().catchError((e) {
        debugPrint('[PostCommentsBottomSheet] Error loading comments: $e');
        // 에러가 발생해도 UI는 계속 표시됨 (기존 댓글 표시)
      });
    });

    // Show initial bubble after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      setState(() {
        _hintMessage = 'Comments on public content can now be shared by others in their stories and reels.';
        _hintOffset = null; // initial style
      });
      _animationController.forward(from: 0);
      // auto hide
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _animationController.reverse();
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted && _hintOffset == null) {
            setState(() => _hintMessage = null);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      final users = ref.read(usersProvider);
      final currentUser = users.values.firstWhere((u) => u.login == true, orElse: () => users.values.first);
      await ref.read(commentsProvider.notifier).addComment(
        postId: widget.postId,
        username: currentUser.username,
        content: text,
        reply: _replyingToCommentId,
      );
      // 알림 provider 새로고침하여 댓글 알림이 즉시 반영되도록
      ref.invalidate(notificationsProvider);
      _commentController.clear();
      setState(() {
        _replyingToUsername = null;
        _replyingToCommentId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _replyToComment(String username, int commentId) {
    setState(() {
      _replyingToUsername = username;
      _replyingToCommentId = commentId;
      _commentController.text = '@$username ';
      _commentController.selection = TextSelection.fromPosition(TextPosition(offset: _commentController.text.length));
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              // header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text('Comments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    Positioned(
                      right: -10,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // For you dropdown (only for own posts with comments)
              Consumer(
                builder: (context, ref, child) {
                  final posts = ref.watch(postsProvider);
                  final post = posts.firstWhere((p) => p.id == widget.postId, orElse: () => posts.first);
                  final users = ref.watch(usersProvider);
                  final currentUser = users.values.firstWhere((u) => u.login == true, orElse: () => users.values.first);
                  final allComments = ref.watch(commentsProvider);
                  final postComments = allComments.where((c) => c.postId == widget.postId).toList();
                  final isMyPost = post.username == currentUser.username;
                  final hasComments = postComments.isNotEmpty;
                  
                  if (isMyPost && hasComments) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text('For you', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(child: _buildCommentsList()),

              // Replying banner (above emoji row)
              if (_replyingToUsername != null)
                Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        'Replying to $_replyingToUsername',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final mention = '@$_replyingToUsername ';
                            if (_commentController.text.startsWith(mention)) {
                              _commentController.text = _commentController.text.substring(mention.length);
                              _commentController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _commentController.text.length),
                              );
                            }
                            _replyingToUsername = null;
                            _replyingToCommentId = null;
                          });
                        },
                        child: Icon(Icons.close, size: 18, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              // emoji bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                ),
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEmojiButton('❤️'),
                    _buildEmojiButton('🙌'),
                    _buildEmojiButton('🔥'),
                    _buildEmojiButton('👏'),
                _buildEmojiButton('😢'),
                _buildEmojiButton('😍'),
                _buildEmojiButton('😮'),
                _buildEmojiButton('😂'),
                  ],
                ),
              ),
              // input
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Row(
                  children: [
                    Consumer(builder: (context, ref, child) {
                      final users = ref.watch(usersProvider);
                      final currentUser = users.values.firstWhere((u) => u.login == true, orElse: () => users.values.first);
                      return CircleAvatar(
                        radius: 18,
                        backgroundImage: currentUser.profileImageUrl.startsWith('http')
                            ? CachedNetworkImageProvider(currentUser.profileImageUrl) as ImageProvider
                            : AssetImage(currentUser.profileImageUrl),
                      );
                    }),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _commentController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendComment(),
                          ),
                        ],
                      ),
                    ),
                    _hasText
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4438F0),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 0,
                            ),
                            onPressed: _sendComment,
                            child: const Icon(Icons.arrow_upward, color: Colors.white, size: 24),
                          )
                        : IconButton(
                            icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600], size: 26),
                            onPressed: () {},
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_hintMessage != null) _buildHintBubbleOverlay(context),
      ],
    );
  }

  // 단일 이모지 버튼 생성
  Widget _buildEmojiButton(String emoji) {
    return GestureDetector(
        onTap: () {
          _commentController.text += emoji;
          _commentController.selection = TextSelection.fromPosition(
            TextPosition(offset: _commentController.text.length),
          );
          setState(() => _hasText = _commentController.text.trim().isNotEmpty);
        },
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildHintBubbleOverlay(BuildContext context) {
    // initial bubble
    if (_hintOffset == null) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 96,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width - 32,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _hintMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3, fontWeight: FontWeight.w500),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CustomPaint(size: const Size(14, 8), painter: _BubbleArrowPainter()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // heart bubble
    const bubbleWidth = 260.0;
    const arrowHeight = 8.0;
    final heartX = _hintOffset!.dx;
    final heartY = _hintOffset!.dy;
    double heartWidth = 28.0;
    final heartEntry = _heartKeys[_heartKeys.keys.firstWhere((id) => _heartKeys[id]!.currentContext != null, orElse: () => _heartKeys.keys.first)];
    final rb = heartEntry?.currentContext?.findRenderObject() as RenderBox?;
    if (rb != null) heartWidth = rb.size.width;
    final heartCenterX = heartX + heartWidth / 2;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final stackWidth = stackBox?.size.width ?? MediaQuery.of(context).size.width;
    double left = heartCenterX - bubbleWidth / 2;
    left = left.clamp(8.0, stackWidth - bubbleWidth - 8.0);
    const bubbleHeightEstimate = 52.0;
    final top = heartY - bubbleHeightEstimate - arrowHeight - 6;
    return Positioned(
      left: left,
      top: top,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: bubbleWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _hintMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.25, fontWeight: FontWeight.w500),
              ),
            ),
            Positioned(
              left: heartCenterX - left - 7,
              bottom: -arrowHeight,
              child: CustomPaint(size: const Size(14, 8), painter: _BubbleArrowPainter()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    final allComments = ref.watch(commentsProvider);
    final postComments = allComments.where((c) => c.postId == widget.postId).toList();
    if (postComments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No comments yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 8),
            Text('Start the conversation.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
    }
    final topLevel = postComments.where((c) => c.reply == null).toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: topLevel.length,
      itemBuilder: (context, index) {
        final comment = topLevel[index];
        final replies = postComments.where((c) => c.reply == comment.id).toList();
        return Column(
          children: [
            _buildCommentItem(comment, isReply: false),
            ...replies.map((r) => _buildCommentItem(r, isReply: true)),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(CommentModel comment, {bool isReply = false}) {
    final timeAgo = _getTimeAgo(comment.time);
    final users = ref.watch(usersProvider);
    final userProfile = users[comment.username];
    final profileImageUrl = userProfile?.profileImageUrl ?? 'assets/images/basic_image.jpg';
    final currentUser = users.values.firstWhere((u) => u.login == true, orElse: () => users.values.first);
    final isMyPost = comment.username != currentUser.username;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 64 : 16, right: 16, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: profileImageUrl.startsWith('http')
                    ? CachedNetworkImageProvider(profileImageUrl) as ImageProvider
                    : AssetImage(profileImageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(timeAgo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        Consumer(builder: (context, ref, child) {
                          final posts = ref.watch(postsProvider);
                          final post = posts.firstWhere((p) => p.id == widget.postId, orElse: () => posts.first);
                          if (comment.username == post.username) {
                            return Row(
                              children: [
                                const SizedBox(width: 4),
                                Text('•', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                const SizedBox(width: 4),
                                const Text('Author', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        if (comment.myHeart && comment.username != currentUser.username) ...[
                          const SizedBox(width: 4),
                          Text('•', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(width: 4),
                          const Icon(Icons.favorite, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          CircleAvatar(
                            radius: 6,
                            backgroundImage: currentUser.profileImageUrl.startsWith('http')
                                ? CachedNetworkImageProvider(currentUser.profileImageUrl) as ImageProvider
                                : AssetImage(currentUser.profileImageUrl),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _replyToComment(comment.username, comment.id),
                          child: Text('Reply', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        if (comment.myHeart) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              // TODO: Reply with a reel functionality
                            },
                            child: Text('Reply with a reel', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    key: _heartKeys[comment.id] ??= GlobalKey(),
                    width: 28,
                    height: 28,
                    child: LikeButton(
                      isLiked: comment.myHeart,
                      onTap: () {
                        if (!comment.myHeart) {
                          _showHintForHeart('Now you can double tap a comment to like it.', comment.id);
                        }
                        ref.read(commentsProvider.notifier).toggleHeart(comment.id);
                      },
                    ),
                  ),
                  SizedBox(
                    height: 16,
                    child: comment.heartCount > 0
                        ? Text('${comment.heartCount}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
          if (isMyPost && !isReply && !_hasReplies(comment.id))
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: GestureDetector(
                onTap: () => _replyToComment(comment.username, comment.id),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: currentUser.profileImageUrl.startsWith('http')
                          ? CachedNetworkImageProvider(currentUser.profileImageUrl) as ImageProvider
                          : AssetImage(currentUser.profileImageUrl),
                    ),
                    const SizedBox(width: 8),
                    Text('Reply to ${comment.username}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasReplies(int commentId) {
    final allComments = ref.read(commentsProvider);
    final users = ref.read(usersProvider);
    final currentUser = users.values.firstWhere((u) => u.login == true, orElse: () => users.values.first);
    return allComments.any((c) => c.reply == commentId && c.username == currentUser.username);
  }

  String _getTimeAgo(DateTime dt) => formatTimeAgoEnVeryShort(dt.toLocal());

  void _showHintForHeart(String message, int commentId, {Duration visible = const Duration(seconds: 2)}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final heartKey = _heartKeys[commentId];
      final stackContext = _stackKey.currentContext;
      final heartContext = heartKey?.currentContext;
      final heartBox = heartContext?.findRenderObject() as RenderBox?;
      final stackBox = stackContext?.findRenderObject() as RenderBox?;
      Offset? relative;
      if (heartBox != null && stackBox != null) {
        final heartGlobal = heartBox.localToGlobal(Offset.zero);
        final stackGlobal = stackBox.localToGlobal(Offset.zero);
        relative = heartGlobal - stackGlobal;
      }
      if (!mounted) return;
      setState(() {
        _hintOffset = relative;
        _hintMessage = message;
      });
      _animationController.forward(from: 0);
    });
    Future.delayed(visible, () {
      if (!mounted) return;
      _animationController.reverse();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _hintMessage == message) {
          setState(() {
            _hintMessage = null;
            _hintOffset = null;
          });
        }
      });
    });
  }
}

class _BubbleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 4, true);
    final paintFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paintFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}