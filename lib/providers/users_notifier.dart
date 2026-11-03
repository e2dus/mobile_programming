import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';
import 'package:individual_project/models/user_model.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersNotifier extends StateNotifier<Map<String, UserModel>> {
  final Ref ref;

  UsersNotifier(this.ref) : super({});

  Future<void> loadUsers() async {
    try {
      final client = Supabase.instance.client;
      debugPrint('[UsersNotifier] Loading users from Supabase...');
      final List<dynamic> rows = await client
          .from('users')
          .select('id, username, profileImageUrl, login, name, bio');
      debugPrint('[UsersNotifier] users rows: ${rows.length}');
      if (rows.isNotEmpty) {
        debugPrint('[UsersNotifier] First row sample: ${rows.first}');
      }

      final Map<String, UserModel> usersMap = {
        for (final row in rows)
          (row['id'] as String): UserModel(
            id: row['id'] as String,
            username: row['username'] as String,
            profileImageUrl: row['profileImageUrl'] as String,
            login: row['login'] as bool? ?? false,
            name: row['name'] as String?,
            pronouns: null,
            bio: row['bio'] as String?,
          ),
      };

      if (usersMap.isNotEmpty) {
        final firstUser = usersMap.values.first;
        debugPrint(
            '[UsersNotifier] First user parsed: username=${firstUser.username}, name=${firstUser.name}, bio=${firstUser.bio}');
      }

      state = usersMap;
    } catch (e) {
      debugPrint('[UsersNotifier] Error loading users from Supabase: $e');
      state = {};
    }
  }

  void updateUser(
    String userId, {
    String? newProfileImageUrl,
    bool? login,
    String? name,
    String? pronouns,
    String? bio,
  }) {
    if (!state.containsKey(userId)) return;

    final user = state[userId]!;
    state = {
      ...state,
      userId: UserModel(
        id: user.id,
        username: user.username,
        profileImageUrl: newProfileImageUrl ?? user.profileImageUrl,
        login: login ?? user.login,
        name: name ?? user.name,
        pronouns: pronouns ?? user.pronouns,
        bio: bio ?? user.bio,
      ),
    };
  }

  Future<String?> uploadProfileImage(String userId, String imagePath) async {
    try {
      final client = Supabase.instance.client;

      final user = state[userId];
      if (user == null || !user.login) {
        debugPrint('[UsersNotifier] User is not logged in or not found');
        return null;
      }

      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final fileExt = imagePath.split('.').last;
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'profile_images/$fileName';

      debugPrint('[UsersNotifier] Uploading image to: $filePath');

      await client.storage.from('profiles').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          client.storage.from('profiles').getPublicUrl(filePath);
      debugPrint('[UsersNotifier] Image uploaded, public URL: $publicUrl');

      await client.from('users').update({
        'profileImageUrl': publicUrl,
      }).eq('id', userId).eq('login', true);

      debugPrint('[UsersNotifier] Database updated for user: $userId');

      updateUser(userId, newProfileImageUrl: publicUrl);
      await _updateStoriesAndPostsProfileImage(user.username, publicUrl);

      return publicUrl;
    } catch (e) {
      debugPrint('[UsersNotifier] Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> _updateStoriesAndPostsProfileImage(
      String username, String newProfileImageUrl) async {
    try {
      final storiesNotifier = ref.read(storiesProvider.notifier);
      final postsNotifier = ref.read(postsProvider.notifier);

      debugPrint(
          '[UsersNotifier] Reloading stories and posts for username: $username');

      await Future.wait<void>([
        storiesNotifier.loadInitialStories(),
        postsNotifier.loadInitialPosts(),
      ]);

      debugPrint('[UsersNotifier] Stories and posts reloaded successfully');
    } catch (e) {
      debugPrint('[UsersNotifier] Error updating stories and posts: $e');
    }
  }

  Future<bool> updateUserName(String userId, String newName) async {
    try {
      final client = Supabase.instance.client;

      final user = state[userId];
      if (user == null || !user.login) {
        debugPrint('[UsersNotifier] User is not logged in or not found');
        return false;
      }

      debugPrint('[UsersNotifier] Updating name for user: $userId to: $newName');

      await client.from('users').update({
        'name': newName,
      }).eq('id', userId).eq('login', true);

      debugPrint('[UsersNotifier] Database updated successfully');

      updateUser(userId, name: newName);

      return true;
    } catch (e) {
      debugPrint('[UsersNotifier] Error updating user name: $e');
      return false;
    }
  }

  Future<bool> updateUserBio(String userId, String? newBio) async {
    try {
      final client = Supabase.instance.client;

      final user = state[userId];
      if (user == null || !user.login) {
        debugPrint('[UsersNotifier] User is not logged in or not found');
        return false;
      }

      debugPrint(
          '[UsersNotifier] Updating bio for user: $userId to: ${newBio ?? '(null)'}');

      await client.from('users').update({'bio': newBio}).eq('id', userId).eq('login', true);

      debugPrint('[UsersNotifier] Bio updated in database successfully');

      updateUser(userId, bio: newBio);

      return true;
    } catch (e) {
      debugPrint('[UsersNotifier] Error updating user bio: $e');
      return false;
    }
  }

  Future<List<UserModel>> getUnfollowedSuggestions(String userId,
      {int limit = 10}) async {
    try {
      final client = Supabase.instance.client;

      if (state.isEmpty) {
        await loadUsers();
      }

      final List<dynamic> followsRows = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      final followedIds =
          followsRows.map((r) => r['following_id'] as String).toSet();

      final exclude = <String>{userId, ...followedIds};

      final candidates =
          state.values.where((u) => !exclude.contains(u.id)).toList();

      candidates.shuffle();
      if (limit > 0 && candidates.length > limit) {
        return candidates.sublist(0, limit);
      }
      return candidates;
    } catch (e) {
      debugPrint('[UsersNotifier] Error fetching unfollowed suggestions: $e');
      return [];
    }
  }

  UserModel? getUserById(String userId) => state[userId];

  UserModel? getUserByUsername(String username) {
    try {
      return state.values.firstWhere(
        (user) => user.username == username,
      );
    } catch (e) {
      return null;
    }
  }
}
