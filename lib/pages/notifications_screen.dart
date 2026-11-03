import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:individual_project/models/notification_item.dart';
import 'package:individual_project/providers/notifications_provider.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/utils/navigation_helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _relativeTime(DateTime time) {
    final localTime = time.toLocal(); // UTC → 로컬 시간 변환
    final diff = DateTime.now().difference(localTime);
    
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final weeks = (diff.inDays / 7).floor();
    return '${weeks}w';
  }

  @override
  void initState() {
    super.initState();
    // 알림 화면을 열 때마다 최신 알림 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(notificationsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: asyncItems.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('알림이 없습니다.', style: TextStyle(color: Colors.grey)));
          }
          
          final now = DateTime.now();
          
          // 24시간 이내는 Recents
          final recents = items.where((n) {
            final localTime = n.time.toLocal();
            final diff = now.difference(localTime);
            return diff.inHours < 24;
          }).toList();
          
          // 24시간 이후 ~ 30일 이내는 Last 30 days
          final last30 = items.where((n) {
            final localTime = n.time.toLocal();
            final diff = now.difference(localTime);
            return diff.inHours >= 24 && diff.inDays <= 30;
          }).toList();

          return ListView(
            children: [
              if (recents.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Recents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ...recents.map((n) => _NotificationTile(item: n, relative: _relativeTime(n.time))),
              ],
              if (last30.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Last 30 days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ...last30.map((n) => _NotificationTile(item: n, relative: _relativeTime(n.time))),
              ],
              // Accounts Center notification (hardcoded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEDEDED), width: 0.5))),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.info_outline, color: Colors.black, size: 20),
                  ),
                  title: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(text: 'You have 2 new accounts in your Accounts Center. '),
                        TextSpan(text: '2w', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류 발생: $e')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerStatefulWidget {
  final NotificationItem item;
  final String relative;
  const _NotificationTile({required this.item, required this.relative});

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == NotificationType.follow) {
      _checkFollowStatus();
    }
  }

  Future<void> _checkFollowStatus() async {
    final client = Supabase.instance.client;
    final users = ref.read(usersProvider);
    final myUser = users.values.firstWhere((u) => u.login == true);
    
    try {
      final result = await client
          .from('follows')
          .select('follower_id')
          .eq('follower_id', myUser.username)
          .eq('following_id', widget.item.actorUsername)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _isFollowing = result != null;
        });
      }
    } catch (e) {
      debugPrint('[NotificationTile] Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    final client = Supabase.instance.client;
    final users = ref.read(usersProvider);
    final myUser = users.values.firstWhere((u) => u.login == true);
    
    // 자신을 팔로우하지 못하도록 체크
    if (myUser.username == widget.item.actorUsername) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot follow yourself.')),
        );
      }
      return;
    }
    
    try {
      if (_isFollowing) {
        await client
            .from('follows')
            .delete()
            .eq('follower_id', myUser.username)
            .eq('following_id', widget.item.actorUsername);
        
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _isLoading = false;
          });
        }
      } else {
        await client.from('follows').insert({
          'follower_id': myUser.username,
          'following_id': widget.item.actorUsername,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[NotificationTile] Error toggling follow: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String subtitle;
    switch (widget.item.type) {
      case NotificationType.comment:
        subtitle = 'commented: ${widget.item.commentText ?? ''}';
        break;
      case NotificationType.like:
        subtitle = 'liked your photo.';
        break;
      case NotificationType.follow:
        subtitle = 'started following you.';
        break;
    }

    Widget? trailing;
    
    if (widget.item.type == NotificationType.follow) {
      trailing = _isLoading
          ? const SizedBox(
              width: 100,
              height: 32,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : OutlinedButton(
              onPressed: _toggleFollow,
              style: OutlinedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey[200] : Theme.of(context).colorScheme.primary,
                foregroundColor: _isFollowing ? Colors.black : Colors.white,
                side: BorderSide(
                  color: _isFollowing ? Colors.grey[300]! : Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                minimumSize: const Size(100, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            );
    } else if (widget.item.postThumbnailUrl != null) {
      trailing = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          widget.item.postThumbnailUrl!,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 42,
            height: 42,
            child: ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEDEDED), width: 0.5))),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () {
          // Navigate to post detail when tapping comment/like notifications
          if (widget.item.postId != null && 
              (widget.item.type == NotificationType.comment || widget.item.type == NotificationType.like)) {
            navigateToPostFromNotification(
              context: context,
              postId: widget.item.postId!,
              openComments: widget.item.type == NotificationType.comment,
            );
          }
        },
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: (widget.item.actorAvatarUrl != null && widget.item.actorAvatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(widget.item.actorAvatarUrl!)
                  : null,
              child: (widget.item.actorAvatarUrl == null || widget.item.actorAvatarUrl!.isEmpty)
                  ? Text(widget.item.actorUsername.isNotEmpty ? widget.item.actorUsername[0].toUpperCase() : '?')
                  : null,
            ),
            // 좋아요 알림만 하트 아이콘 표시
            if (widget.item.type == NotificationType.like)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.favorite, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              TextSpan(text: widget.item.actorUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' '),
              TextSpan(text: subtitle),
              const TextSpan(text: ' '),
              TextSpan(text: widget.relative, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
            if (widget.item.type == NotificationType.comment) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO: Like comment functionality
                    },
                    child: const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // TODO: Reply to comment functionality
                    },
                    child: const Text('Reply', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: trailing,
      ),
    );
  }
}
