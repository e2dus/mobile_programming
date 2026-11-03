import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Performs a tiny query to verify that Supabase is reachable and credentials are valid.
/// Logs the outcome to the console. Safe to call on app startup.
Future<void> supabaseConnectivityCheck() async {
  final client = Supabase.instance.client;
  try {
    // Try minimal selects to confirm connectivity and permissions
    final users = await client.from('users').select('id').limit(1);
    final posts = await client.from('posts').select('id').limit(1);

    debugPrint('[Supabase] Connectivity OK. users: ${users.length}, posts: ${posts.length}');
  } catch (e, st) {
    debugPrint('[Supabase] Connectivity ERROR: $e');
    debugPrint('$st');
  }
}

/// Fetches a few rows from users and posts and prints them so you can verify schema/data.
Future<void> supabaseDumpTables({int limit = 3}) async {
  final client = Supabase.instance.client;
  try {
    debugPrint('[SupabaseDump] Fetching first $limit rows from users and posts...');
    final users = await client.from('users').select().limit(limit);
    final posts = await client.from('posts').select().limit(limit);

    debugPrint('[SupabaseDump] users count=${users.length}');
    for (var i = 0; i < users.length; i++) {
      debugPrint('[SupabaseDump] users[$i]: ${users[i]}');
    }

    debugPrint('[SupabaseDump] posts count=${posts.length}');
    for (var i = 0; i < posts.length; i++) {
      debugPrint('[SupabaseDump] posts[$i]: ${posts[i]}');
    }
  } catch (e, st) {
    debugPrint('[SupabaseDump] ERROR: $e');
    debugPrint('$st');
  }
}
