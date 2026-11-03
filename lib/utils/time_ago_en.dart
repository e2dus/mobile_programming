import 'package:intl/intl.dart';

/// Returns human readable relative time in English, e.g. "5 seconds ago", "3 minutes ago".
String formatTimeAgoEnLong(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);

  if (diff.inSeconds < 60) {
    final s = diff.inSeconds.clamp(0, 59);
    return s == 1 ? '1 second ago' : '$s seconds ago';
  }
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? '1 minute ago' : '$m minutes ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? '1 hour ago' : '$h hours ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return d == 1 ? '1 day ago' : '$d days ago';
  }
  // 7+ days: show date in "September 19" format
  return DateFormat('MMMM d').format(timestamp);
}

/// Returns short English relative time, e.g. "now", "45s ago", "3m ago", "2h ago", "5d ago", "3w ago".
String formatTimeAgoEnShort(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);

  if (diff.inSeconds < 5) return 'just now';
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '${weeks}w ago';

  // Older: concise date
  return DateFormat('MMM d').format(timestamp);
}

/// Returns very short English relative time without "ago", e.g. "1s", "3m", "2h", "5d", "3w".
String formatTimeAgoEnVeryShort(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);

  if (diff.inSeconds < 5) return 'now';
  if (diff.inSeconds < 60) return '${diff.inSeconds}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';

  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '${weeks}w';

  // Older: concise date
  return DateFormat('MMM d').format(timestamp);
}