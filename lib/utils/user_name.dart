import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/models/user_model.dart';

String getCurrentUserName(WidgetRef ref) {
  final authUser = Supabase.instance.client.auth.currentUser;
  final usersMap = ref.read(usersProvider);

  UserModel? dbUser;
  if (authUser != null) {
    dbUser = usersMap[authUser.id];
  }
  dbUser ??= () {
    try {
      return usersMap.values.firstWhere((u) => u.login == true);
    } catch (_) {
      return null;
    }
  }();

  if (dbUser != null && dbUser.username.trim().isNotEmpty) {
    return dbUser.username;
  }

  if (authUser == null) return 'You';
  final meta = authUser.userMetadata ?? {};
  for (final key in ['name', 'full_name', 'username', 'display_name']) {
    final v = meta[key];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return authUser.email?.split('@').first ?? 'You';
}
