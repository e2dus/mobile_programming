import 'package:individual_project/models/chat_model.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsNotifier extends StateNotifier<List<ChatModel>> {
  ChatsNotifier(super.state);

  // Helper: sort by lastMessageTime desc; nulls last
  void _sortByLatest() {
    final List<ChatModel> sorted = [...state];
    sorted.sort((a, b) {
      final ta = a.lastMessageTime;
      final tb = b.lastMessageTime;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1; // null last
      if (tb == null) return -1;
      return tb.compareTo(ta); // desc
    });
    state = sorted;
  }

  Future<void> loadInitialChats() async {
    try {
      final client = Supabase.instance.client;
      debugPrint('[ChatsNotifier] Loading chats from Supabase...');

      final List<dynamic> chatRows = await client
          .from('chats')
          .select('id, userId, username, lastMessageTime, hasUnreadMessage')
          .order('lastMessageTime', ascending: false);
      debugPrint('[ChatsNotifier] chats rows: ${chatRows.length}');
      if (chatRows.isNotEmpty) {
        debugPrint('[ChatsNotifier] chats sample row: ${chatRows.first}');
      }

      // fetch users to map profileImageUrl by username
      final List<dynamic> userRows = await client
          .from('users')
          .select('username, profileImageUrl');
      debugPrint('[ChatsNotifier] users rows (for chats avatar map): ${userRows.length}');
      if (userRows.isNotEmpty) {
        debugPrint('[ChatsNotifier] users sample row: ${userRows.first}');
      }

      final Map<String, String> usernameToAvatar = {
        for (final u in userRows)
          (u['username'] as String? ?? ''): (u['profileImageUrl']?.toString() ??
              'assets/images/basic_image.jpg')
      }..removeWhere((k, v) => k.isEmpty);

      final List<ChatModel> parsed = [];
      for (final row in chatRows) {
        try {
          final String username = (row['username'] ?? '').toString();
          DateTime? _parseTime(dynamic v) {
            if (v == null) return null;
            if (v is DateTime) return v;
            if (v is String) {
              try { return DateTime.parse(v); } catch (_) { return null; }
            }
            return null;
          }
          parsed.add(ChatModel(
            chatId: row['id'].toString(),
            userId: row['userId'].toString(),
            username: username,
            profileImageUrl: usernameToAvatar[username] ?? 'assets/images/basic_image.jpg',
            lastMessageTime: _parseTime(row['lastMessageTime']),
            hasUnreadMessage: (row['hasUnreadMessage'] as bool?) ?? false,
          ));
        } catch (e, st) {
          debugPrint('[ChatsNotifier] Error parsing chat entry ${row['id']}: $e');
          debugPrint('$st');
        }
      }

      if (parsed.isNotEmpty) {
        parsed.sort((a, b) {
          final ta = a.lastMessageTime;
          final tb = b.lastMessageTime;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });
        state = parsed;
        return;
      }
      debugPrint('[ChatsNotifier] Supabase chats empty.');
    } catch (e) {
      debugPrint('[ChatsNotifier] Error loading chats from Supabase: $e');
    }

    // Safe minimal fallback when Supabase is empty or errors
    state = [];
  }

  void markChatAsRead(String chatId) {
    state = [
      for (final chat in state)
        if (chat.chatId == chatId)
          chat.copyWith(hasUnreadMessage: false)
        else
          chat,
    ];
    _sortByLatest();
  }

  // Update a chat's meta locally and keep list ordered by most recent first
  void updateChatMetaLocal({
    required String chatId,
    DateTime? lastMessageTime,
    bool? hasUnreadMessage,
  }) {
    state = [
      for (final chat in state)
        if (chat.chatId == chatId)
          chat.copyWith(
            lastMessageTime: lastMessageTime ?? chat.lastMessageTime,
            hasUnreadMessage: hasUnreadMessage ?? chat.hasUnreadMessage,
          )
        else
          chat,
    ];
    _sortByLatest();
  }
}