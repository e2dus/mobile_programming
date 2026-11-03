import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/components/story_icon.dart';
import 'package:individual_project/models/story_model.dart';
import 'package:individual_project/pages/profile_screen.dart';

class FollowersFollowingScreen extends ConsumerStatefulWidget {
  final String userId;
  final String username;
  final int initialTab; // 0: followers, 1: following

  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTab = 0,
  });

  @override
  ConsumerState<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends ConsumerState<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  List<UserModel> _filteredFollowers = [];
  List<UserModel> _filteredFollowing = [];
  
  bool _isLoading = true;
  Set<String> _iFollowIds = {}; // 내가 팔로우한 사용자 ID 세트 (로그인 사용자 기준)
  Set<String> _loadingFollowIds = {}; // 팔로우 진행 중인 타겟 ID 세트
  String? _loggedInUserId; // 로그인 사용자 ID

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, // Changed to 4 tabs
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      // 로그인 사용자 파악
      final usersMap = ref.read(usersProvider);
      final loggedIn = usersMap.values.where((u) => u.login == true).toList();
      _loggedInUserId = loggedIn.isNotEmpty ? loggedIn.first.id : null;
      
      // Load followers: users who follow this user (follower_id -> user)
      final followersData = await supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', widget.userId);
      
      final followerIds = (followersData as List)
          .map((e) => e['follower_id'] as String)
          .toList();
      
      if (followerIds.isNotEmpty) {
        final followersUsersData = await supabase
            .from('users')
            .select()
            .inFilter('id', followerIds);
        
        _followers = (followersUsersData as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
      }
      
      // Load following: users this user follows (following_id -> user)
      final followingData = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', widget.userId);
      
      final followingIds = (followingData as List)
          .map((e) => e['following_id'] as String)
          .toList();
      
      if (followingIds.isNotEmpty) {
        final followingUsersData = await supabase
            .from('users')
            .select()
            .inFilter('id', followingIds);
        
        _following = (followingUsersData as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
      }
      
      // 내 팔로잉 목록 (로그인 사용자 기준)도 세트로 보관
      if (_loggedInUserId != null) {
        final myFollowingRows = await supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', _loggedInUserId!);
        _iFollowIds = (myFollowingRows as List)
            .map((e) => e['following_id'] as String)
            .toSet();
      } else {
        _iFollowIds = {};
      }
      
      _filteredFollowers = List.from(_followers);
      _filteredFollowing = List.from(_following);
      
    } catch (e) {
      debugPrint('[FollowersFollowing] Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFollowers = _followers
          .where((u) => 
              u.username.toLowerCase().contains(query) ||
              (u.name?.toLowerCase().contains(query) ?? false))
          .toList();
      
      _filteredFollowing = _following
          .where((u) => 
              u.username.toLowerCase().contains(query) ||
              (u.name?.toLowerCase().contains(query) ?? false))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.username,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.black,
              indicatorWeight: 1.0,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 15,
              ),
              tabs: [
                Tab(text: '${_followers.length} followers'),
                Tab(text: '${_following.length} following'),
                const Tab(text: '0 subscriptions'),
                const Tab(text: 'Flagged'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_filteredFollowers, stories),
                _buildUserList(_filteredFollowing, stories),
                _buildEmptyTab('No subscriptions yet'),
                _buildEmptyTab('No flagged accounts'),
              ],
            ),
    );
  }

  Widget _buildUserList(List<UserModel> users, List<StoryModel> stories) {
    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        
        // Sync contacts banner
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.contact_page_outlined, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync contacts',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Find people you know',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Sync',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.close, color: Colors.grey.shade600, size: 20),
              ],
            ),
          ),
        ),
        
        // Sorted by header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sorted by Default',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Icon(Icons.sort, color: Colors.black, size: 24),
              ],
            ),
          ),
        ),
        
        // User list
        users.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Text(
                    _searchController.text.isNotEmpty
                        ? 'No users found'
                        : 'No users yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = users[index];
                    return _buildUserTile(user, stories);
                  },
                  childCount: users.length,
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user, List<StoryModel> stories) {
    // Check if user has story
    final userStory = stories.where(
      (s) => s.username.toLowerCase() == user.username.toLowerCase()
    ).toList().isNotEmpty
        ? stories.firstWhere(
            (s) => s.username.toLowerCase() == user.username.toLowerCase())
        : null;
    
    final bool hasStory = userStory != null;
    
    return GestureDetector(
      onTap: () {
        // Navigate to user's profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: user.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.transparent,
        child: Row(
          children: [
            // Use StoryIcon component - only shows ring if hasStory
            StoryIcon(
              profileImageUrl: user.profileImageUrl,
              username: user.username,
              hasViewed: hasStory ? (userStory.hasViewed) : true, // If no story, treat as "viewed" (gray border)
              isMyStory: false,
              onTap: () {
                // Navigate to user's profile
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: user.id),
                  ),
                );
              },
              size: 60,
              isMainPageStory: false, // Don't show username label below
            ),
            const SizedBox(width: 12),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (user.username == 'imwinter') ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          color: Theme.of(context).colorScheme.primary,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  if (user.name != null)
                    Text(
                      user.name!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            
            // Follow or Message button (내가 팔로우 안한 사람은 Follow 버튼)
            // 자신의 경우 버튼을 표시하지 않음
            if (_loggedInUserId != user.id)
              Builder(builder: (context) {
                final isFollowedByMe = _iFollowIds.contains(user.id);
                final isLoading = _loadingFollowIds.contains(user.id);
                if (isFollowedByMe) {
                  // Message 버튼
                  return GestureDetector(
                    onTap: () {
                      // TODO: Open message
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Message',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                // Follow 버튼 (인스타 블루)
                return GestureDetector(
                  onTap: isLoading || _loggedInUserId == null
                      ? null
                      : () async {
                          setState(() => _loadingFollowIds.add(user.id));
                          try {
                            await Supabase.instance.client.from('follows').insert({
                              'follower_id': _loggedInUserId,
                              'following_id': user.id,
                              'created_at': DateTime.now().toUtc().toIso8601String(),
                            });
                            setState(() {
                              _iFollowIds.add(user.id);
                            });
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to follow. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _loadingFollowIds.remove(user.id));
                            }
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Follow',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                );
              }),
            const SizedBox(width: 8),
            
            // More options
            GestureDetector(
              onTap: () {
                // TODO: Show more options
              },
              child: Icon(Icons.more_vert, color: Colors.black, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
