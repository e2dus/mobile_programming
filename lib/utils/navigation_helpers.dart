import 'package:flutter/material.dart';

/// Helper function to navigate to post detail page from notification
/// 
/// Usage when user taps a comment notification:
/// ```dart
/// navigateToPostFromNotification(
///   context: context,
///   postId: 'post_123',
///   openComments: true,
/// );
/// ```
void navigateToPostFromNotification({
  required BuildContext context,
  required String postId,
  bool openComments = true,
}) {
  Navigator.pushNamed(
    context,
    '/postDetail',
    arguments: {
      'postId': postId,
      'openComments': openComments,
    },
  );
}
