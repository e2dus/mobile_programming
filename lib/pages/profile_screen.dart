import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter; // for blur
import 'package:individual_project/models/post_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/components/story_icon.dart';
import 'package:individual_project/models/user_model.dart';
import 'package:individual_project/pages/create_post_screen.dart';
import 'package:individual_project/pages/edit_profile_page.dart';
import 'package:individual_project/pages/followers_following_screen.dart';
import 'package:individual_project/pages/user_posts_feed_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // null이면 본인 프로필, 있으면 해당 유저 프로필
  
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTab = 0; // 0: grid, 1: tagged
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoadingCounts = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  List<UserModel> _suggestions = [];
  final Set<String> _followedSuggestions = {};
  List<UserModel> _followedByUsers = []; // "Followed by" 섹션용
  int _totalFollowersCount = 0; // 전체 팔로워 수 (배지 표시용)

  @override
  void initState() {
    super.initState();
    _loadFollowCounts();
    _checkIfFollowing();
    _loadFollowedByUsers();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when widget updates
    _loadFollowCounts();
    if (widget.userId != null) {
      _checkIfFollowing();
      _loadFollowedByUsers();
    }
  }

  UserModel _getLoggedInUser(Map<String, UserModel> users) {
    return users.values.firstWhere(
        (u) => u.login == true,
        orElse: () => UserModel(
          id: 'user4',
          username: 'karina',
          profileImageUrl: 'assets/images/karina_profile.jpg',
        ),
      );
  }

  Future<void> _checkIfFollowing() async {
    if (widget.userId == null) return; // Own profile, no need to check
    
    try {
      final users = ref.read(usersProvider);
      final loggedInUser = _getLoggedInUser(users);
      final supabase = Supabase.instance.client;
      
      final result = await supabase
          .from('follows')
          .select()
          .eq('follower_id', loggedInUser.id)
          .eq('following_id', widget.userId!)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _isFollowing = result != null;
        });
        // 팔로우 상태 확인 후 "Followed by" 목록 로드 (항상 로드)
        _loadFollowedByUsers();
      }
    } catch (e) {
      debugPrint('[ProfileScreen] Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;
    
    setState(() => _isFollowLoading = true);
    
    try {
      final users = ref.read(usersProvider);
      final loggedInUser = _getLoggedInUser(users);

      // 자신을 팔로우하지 못하도록 체크
      if (loggedInUser.id == widget.userId) {
        if (mounted) {
          setState(() => _isFollowLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot follow yourself.')),
          );
        }
        return;
      }

      final supabase = Supabase.instance.client;
      
      if (_isFollowing) {
        // Unfollow: delete from follows table
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', loggedInUser.id)
            .eq('following_id', widget.userId!);
        
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followersCount = (_followersCount - 1).clamp(0, 999999);
          });
        }
        // 언팔로우해도 "Followed by" 목록은 유지하고 업데이트
        await _loadFollowedByUsers();
      } else {
        // Follow: insert into follows table
        await supabase.from('follows').insert({
          'follower_id': loggedInUser.id,
          'following_id': widget.userId!,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followersCount++;
          });
        }

        // 팔로우 직후 추천 사용자 로드 (화면 내에 표시)
        await _loadSuggestionsFor(loggedInUser.id);
        // 팔로우한 경우 "Followed by" 목록도 업데이트
        await _loadFollowedByUsers();
      }
      
      // Reload follow counts to update following count for logged in user
      await _loadFollowCounts();
    } catch (e) {
      debugPrint('[ProfileScreen] Error toggling follow: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'}. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  Future<void> _loadSuggestionsFor(String currentUserId) async {
    try {
      final suggestions = await ref
          .read(usersProvider.notifier)
          .getUnfollowedSuggestions(currentUserId, limit: 10);
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _followedSuggestions.clear();
      });
    } catch (e) {
      debugPrint('[ProfileScreen] Error loading suggestions: $e');
    }
  }

  Future<void> _followSuggestedUser(String currentUserId, String targetUserId) async {
    // 자신을 팔로우하지 못하도록 체크
    if (currentUserId == targetUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot follow yourself.')),
        );
      }
      return;
    }
    
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[ProfileScreen] Error following suggested user: $e');
    }
  }

  Future<void> _loadFollowCounts() async {
    try {
      final users = ref.read(usersProvider);
      final targetUser = _getTargetUser(users);

      final supabase = Supabase.instance.client;
      
      // Get followers count for the target user (who follows this user)
      final followersData = await supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', targetUser.id);
      
      // Get following count for the target user (who this user follows)
      final followingData = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', targetUser.id);
      
      if (mounted) {
        setState(() {
          _followersCount = (followersData as List).length;
          _followingCount = (followingData as List).length;
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      debugPrint('[ProfileScreen] Error loading follow counts: $e');
      if (mounted) {
        setState(() => _isLoadingCounts = false);
      }
    }
  }

  Future<void> _loadFollowedByUsers() async {
    // 본인 프로필인 경우 표시하지 않음
    if (widget.userId == null) {
      if (mounted) {
        setState(() {
          _followedByUsers = [];
          _totalFollowersCount = 0;
        });
      }
      return;
    }

    try {
      final users = ref.read(usersProvider);
      final loggedInUser = _getLoggedInUser(users);
      final targetUser = _getTargetUser(users);
      final supabase = Supabase.instance.client;

      // 이 프로필 사용자를 팔로우하는 사용자들 가져오기
      final followersData = await supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', targetUser.id);

      final allFollowerIds = (followersData as List)
          .map((e) => e['follower_id'] as String)
          .where((id) => id != loggedInUser.id) // 본인 제외
          .toList();

      // 전체 팔로워 수 저장
      final totalCount = allFollowerIds.length;

      // 최대 3명만 표시
      final displayFollowerIds = allFollowerIds.take(3).toList();

      if (displayFollowerIds.isEmpty) {
        if (mounted) {
          setState(() {
            _followedByUsers = [];
            _totalFollowersCount = 0;
          });
        }
        return;
      }

      // 사용자 정보 가져오기
      final followedByUsersList = <UserModel>[];
      for (final id in displayFollowerIds) {
        final user = users.values.firstWhere(
          (u) => u.id == id,
          orElse: () => UserModel(
            id: id,
            username: 'unknown',
            profileImageUrl: 'assets/images/basic_image.jpg',
          ),
        );
        followedByUsersList.add(user);
      }

      if (mounted) {
        setState(() {
          _followedByUsers = followedByUsersList;
          _totalFollowersCount = totalCount;
        });
      }
    } catch (e) {
      debugPrint('[ProfileScreen] Error loading followed by users: $e');
      if (mounted) {
        setState(() {
          _followedByUsers = [];
          _totalFollowersCount = 0;
        });
      }
    }
  }

  void _showPostPreviewOverlay(PostModel post, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // 배경 탭으로 닫기 가능
      barrierLabel: 'post-preview',
      barrierColor: Colors.black45, // slight dim
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            // Blur the background (탭 가능하도록 GestureDetector 추가)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),
              ),
            ),
            // Centered preview card: square image + white bottom bar, rounded corners
            Center(
              child: GestureDetector(
                onTap: () {}, // 카드 탭 시 닫히지 않도록 빈 핸들러
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 480,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 4),
                    ],
                  ),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top user header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        color: Colors.white,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: post.profileImageUrl.startsWith('http')
                                  ? CachedNetworkImageProvider(post.profileImageUrl)
                                  : AssetImage(post.profileImageUrl) as ImageProvider,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                post.username,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Square image
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: imageUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                ),
                              )
                            : Image.asset(imageUrl, fit: BoxFit.cover),
                      ),
                      // Bottom white action bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.favorite_border, color: Colors.black, size: 26),
                              const Icon(Icons.mode_comment_outlined, color: Colors.black, size: 26),
                              const Icon(Icons.send_outlined, color: Colors.black, size: 26),
                              const Icon(Icons.more_vert, color: Colors.black, size: 26),
                            ],
                          ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved), child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 180),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Divider(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CreateItem(
                      icon: Icons.movie_outlined,
                      label: 'Reel',
                      onTap: () => Navigator.of(context).pop(),
              ),
              Divider(height: 0, indent: 40, endIndent: 0),
                    _CreateItem(
                      icon: Icons.grid_on_outlined,
                      label: 'Post',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreatePostScreen(),
                          ),
                        );
                      },
              ),
              Divider(height: 0, indent: 40, endIndent: 0),
                    _CreateItem(
                      icon: Icons.post_add_outlined,
                      label: 'Share only to profile',
                      trailing: const _NewBadge(),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 0, indent: 56, endIndent: 0),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  void _showPauseMessagesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const Text(
                  'Pause these messages?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const Text(
                  "You'll stop seeing messages about sharing to Facebook for 90 days. You can turn on crossposting when you share a story, post or reel.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Pause', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'No thanks',
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  UserModel _getTargetUser(Map<String, UserModel> users) {
    if (widget.userId != null) {
      return users.values.firstWhere(
        (u) => u.id == widget.userId,
        orElse: () => UserModel(
          id: widget.userId!,
          username: 'unknown',
          profileImageUrl: 'assets/images/basic_image.jpg',
        ),
      );
    } else {
      return users.values.firstWhere(
        (u) => u.login == true,
        orElse: () => UserModel(
          id: 'user4',
          username: 'karina',
          profileImageUrl: 'assets/images/karina_profile.jpg',
        ),
      );
      }
  }

  @override
  Widget build(BuildContext context) {
    // initState가 아닌 build 시점에서 트리거 확인 후 프레임 종료 시 모달 표시
    final shouldShowPause = ref.watch(profilePauseSheetTriggerProvider);
    if (shouldShowPause) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
        if (mounted && isCurrent) {
          _showPauseMessagesSheet();
          ref.read(profilePauseSheetTriggerProvider.notifier).state = false;
        }
      });
    }
    final users = ref.watch(usersProvider);
    final stories = ref.watch(storiesProvider);
    final storiesNotifier = ref.read(storiesProvider.notifier);
    final posts = ref.watch(postsProvider);

    final loggedInUser = _getLoggedInUser(users);
    final user = _getTargetUser(users);
    final isOwnProfile = user.id == loggedInUser.id;

    final userStoryList = stories.where(
      (s) => s.username.toLowerCase() == user.username.toLowerCase(),
    ).toList();
    final userStory = userStoryList.isNotEmpty ? userStoryList.first : null;

    // 해당 사용자의 포스트 가져오기 (최신순 정렬)
    final userPosts = posts
        .where((post) => post.username.toLowerCase() == user.username.toLowerCase())
        .toList();
    int _compareByTimeDesc(a, b) {
      DateTime parseSafe(String s) {
        try { return DateTime.parse(s); } catch (_) { return DateTime.fromMillisecondsSinceEpoch(0); }
      }
      return parseSafe(b.timeAgo).compareTo(parseSafe(a.timeAgo));
    }
    userPosts.sort(_compareByTimeDesc);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title:  Row(
          children: [
            Text(
              user.username,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 24),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isOwnProfile)
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
              onPressed: _showCreateSheet,
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              // TODO: Show menu
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                  // Story-enabled avatar with "Share a note" bubble
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      StoryIcon(
                      profileImageUrl: user.profileImageUrl,
                      username: user.username,
                      hasViewed: userStory?.hasViewed ?? false,
                      isMyStory: false,
                      onTap: () {
                        if (userStory != null) storiesNotifier.markStoryAsViewed(userStory.id);
                      },
                      size: 90,
                      isMainPageStory: false,
                    ),
                      // "Share a note" 말풍선 (본인 프로필일 때만 표시)
                      if (isOwnProfile)
                        Positioned(
                          top: -8,
                          left: 12,
                          child: _ShareNoteBubble(),
                        ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Basic counts and buttons
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? user.username,
                          style: const TextStyle(color: Colors.black),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                count: userPosts.length,
                                label: 'posts',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserPostsFeedPage(username: user.username),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: _StatColumn(
                                count: _isLoadingCounts ? 0 : _followersCount,
                                label: 'followers',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FollowersFollowingScreen(
                                        userId: user.id,
                                        username: user.username,
                                        initialTab: 0, // followers tab
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: _StatColumn(
                                count: _isLoadingCounts ? 0 : _followingCount,
                                label: 'following',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FollowersFollowingScreen(
                                        userId: user.id,
                                        username: user.username,
                                        initialTab: 1, // following tab
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  user.bio ?? '',
                  style: const TextStyle(
                      fontSize: 14,
                    color: Colors.black
                  ),
                ),
              ),
              // "Followed by" 섹션 (다른 사람 프로필일 때 항상 표시)
              if (!isOwnProfile && _followedByUsers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _FollowedBySection(
                    users: _followedByUsers,
                    totalCount: _totalFollowersCount,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              Row(
                children: [
                  // Edit profile (only for own profile)
                  if (isOwnProfile) ...[
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text(
                            'Edit profile',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // Follow button (only for other's profile)
                  if (!isOwnProfile) ...[
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: _isFollowLoading ? null : _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing
                                ? Colors.grey.shade200
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: _isFollowing ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: _isFollowLoading
                              ? SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isFollowing ? Colors.black : Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (_isFollowing) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down, size: 16),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Message button (for other's profile) or Share profile (for own)
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: isOwnProfile ? null : () {
                            // TODO: Open message
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          isOwnProfile ? 'Share profile' : 'Message',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  
                  // Small invite/follow options icon (always visible)
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Material(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      child: IconButton(
                        onPressed: () async {
                          // 친구 추천 로드 (팔로우 버튼과 동일한 동작)
                          await _loadSuggestionsFor(loggedInUser.id);
                        },
                        icon: const Icon(Icons.person_add_outlined, size: 18, color: Colors.black),
                        splashRadius: 20,
                      ),
                    ),
                  ),
                ],
              ),
              // Inline suggestions section between buttons and tab icons
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Suggested for you',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to expanded suggestions screen
                        },
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, idx) {
                      final u = _suggestions[idx];
                      final isFollowed = _followedSuggestions.contains(u.id);
                      return _SuggestionCard(
                        user: u,
                        isFollowed: isFollowed,
                        onFollow: () async {
                          await _followSuggestedUser(loggedInUser.id, u.id);
                          if (mounted) {
                            setState(() => _followedSuggestions.add(u.id));
                          }
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: _suggestions.length,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
              // Tab-like icon buttons with bottom indicator
              Row(
                children: [
                  Expanded(
                    child: _ProfileTabButton(
                      icon: Icons.grid_on,
                      selected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _ProfileTabButton(
                      icon: Icons.person_outline,
                      selected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 사용자의 포스트 그리드 (+ 마지막에 플러스 박스)
              Builder(builder: (context) {
                final showPlus = _selectedTab == 0 && isOwnProfile; // 본인 프로필일 때만 플러스 노출
                final itemCount = userPosts.length + (showPlus ? 1 : 0);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: showPlus ? itemCount : userPosts.length,
                  itemBuilder: (context, index) {
                    // 마지막 타일은 플러스 박스 (본인 프로필일 때만)
                    if (showPlus && index == itemCount - 1) {
                      return GestureDetector(
                        onTap: _showCreateSheet,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, size: 36, color: Colors.black54),
                          ),
                        ),
                      );
                    }

                    final post = userPosts[index];
                    final imageUrl = post.postImageUrls.isNotEmpty
                        ? post.postImageUrls[0]
                        : 'assets/images/basic_image.jpg';

                    return GestureDetector(
                      onTap: () {
                        // Navigate to user posts feed page starting from clicked post
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserPostsFeedPage(
                              username: user.username,
                              initialPostId: post.id, // 클릭한 게시물 ID 전달
                            ),
                          ),
                        );
                      },
                      onLongPressStart: (_) => _showPostPreviewOverlay(post, imageUrl),
                      onLongPressEnd: (details) {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: ClipRRect(
                        child: imageUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 400,
                                maxWidthDiskCache: 400,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint('[ProfileGrid] Failed to load image: $imageUrl');
                                  debugPrint('[ProfileGrid] Error: $error');
                                  return Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                    ),
                                  );
                                },
                              )
                            : Image.asset(imageUrl, fit: BoxFit.cover),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;
  
  const _StatColumn({
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );

    // Full tappable box, left aligned.
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: Alignment.centerLeft,
      child: content,
    );

    if (onTap == null) {
      return box;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: box,
      ),
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileTabButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Icon(
            icon,
            size: 24,
            color: selected ? Colors.black : Colors.black54,
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: double.infinity,
            color: selected ? Colors.grey.shade400 : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _CreateItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _CreateItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4,vertical: 4),
      leading: Icon(icon, size: 22, color: Colors.black87),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: trailing,
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'New',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onFollow;
  final bool isFollowed;

  const _SuggestionCard({
    required this.user,
    required this.onFollow,
    required this.isFollowed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Dismiss icon area (visual only)
          Align(
            alignment: Alignment.topRight,
            child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: 36,
            backgroundImage: user.profileImageUrl.startsWith('http')
                ? CachedNetworkImageProvider(user.profileImageUrl)
                : AssetImage(user.profileImageUrl) as ImageProvider,
          ),
          const SizedBox(height: 10),
          Text(
            user.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            user.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: isFollowed ? null : onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowed
                    ? Colors.grey.shade200
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: isFollowed ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isFollowed ? 'Following' : 'Follow',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareNoteBubble extends StatelessWidget {
  const _ShareNoteBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
       child: CustomPaint(
         painter: _BubblePainter(),
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
           constraints: const BoxConstraints(
             minWidth: 70,
           ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Share a',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  height: 1.0,
                ),
              ),
              Text(
                'note',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 말풍선 본체 페인트 (흰색)
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final borderRadius = 10.0;
    final tailWidth = 7.0;
    final tailHeight = 6.0;
    final tailPosition = 16.0; // 말풍선 꼬리 위치 (왼쪽에서 16px)

    // 말풍선 본체 (둥근 사각형) - 꼬리 부분을 제외한 영역
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    path.addRRect(bodyRect);

    // 말풍선 꼬리 (왼쪽 아래에서 프로필 사진의 왼쪽 위 모서리 방향으로)
    // 꼬리는 본체 아래쪽 왼쪽에서 시작하여 왼쪽 아래로 향함
    final tailStartX = tailPosition;
    final tailStartY = size.height;
    final tailEndX = tailStartX - 4; // 왼쪽으로 기울어짐
    final tailEndY = size.height + tailHeight;
    
    // 꼬리 부분을 본체에서 제외하기 위해 먼저 본체를 그리고
    // 꼬리를 별도로 추가
    path.moveTo(tailStartX - tailWidth / 2, tailStartY);
    path.lineTo(tailEndX, tailEndY);
    path.lineTo(tailStartX + tailWidth / 2, tailStartY);
    path.close();

    // 말풍선 본체와 꼬리 그리기
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FollowedBySection extends StatelessWidget {
  final List<UserModel> users;
  final int totalCount; // 전체 팔로워 수

  const _FollowedBySection({
    required this.users,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    // 최대 3명만 표시
    final displayUsers = users.take(3).toList();
    final hasMore = totalCount > displayUsers.length;

    return Row(
      children: [
        // 프로필 사진들 (겹쳐서 표시)
        SizedBox(
          width: 20.0 * displayUsers.length - 8.0 * (displayUsers.length - 1), // 겹치는 부분 계산
          height: 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...displayUsers.asMap().entries.map((entry) {
                final index = entry.key;
                final user = entry.value;
                return Positioned(
                  left: index * 12.0, // 각 사진이 12px씩 겹치도록
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundImage: user.profileImageUrl.startsWith('http')
                          ? CachedNetworkImageProvider(user.profileImageUrl)
                          : AssetImage(user.profileImageUrl) as ImageProvider,
                    ),
                  ),
                );
              }),
              // 여러 개일 때 오른쪽 위에 배지 표시
              if (hasMore && displayUsers.isNotEmpty)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '+${totalCount - displayUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 텍스트 (사용자 이름은 bold 처리)
        Expanded(
          child: _buildFollowedByText(displayUsers),
        ),
      ],
    );
  }

  Widget _buildFollowedByText(List<UserModel> displayUsers) {
    final textSpans = <TextSpan>[
      const TextSpan(
        text: 'Followed by ',
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    ];

    for (int i = 0; i < displayUsers.length; i++) {
      // 사용자 이름 (bold)
      textSpans.add(
        TextSpan(
          text: displayUsers[i].username,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      // 구분자 추가
      if (i < displayUsers.length - 1) {
        if (i == displayUsers.length - 2) {
          // 마지막에서 두 번째: " and "
          textSpans.add(
            const TextSpan(
              text: ' and ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          );
        } else {
          // 그 외: ", "
          textSpans.add(
            const TextSpan(
              text: ', ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          );
        }
      }
    }

    return RichText(
      text: TextSpan(children: textSpans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}