# Post Detail Page & Notification Navigation

## Overview
When a user receives a comment notification and taps it, they are taken directly to the post detail page with the comments bottom sheet automatically opened.

## Files Created/Modified

### New Files
1. **`lib/pages/post_detail_page.dart`** - Single post detail page
2. **`lib/utils/navigation_helpers.dart`** - Navigation helper functions

### Modified Files
1. **`lib/main.dart`** - Added `/postDetail` route
2. **`lib/pages/notifications_screen.dart`** - Added onTap navigation for comment/like notifications

## Usage

### From Notification Screen
When a user taps a comment or like notification, the app automatically:
1. Navigates to the post detail page (`/postDetail`)
2. Opens the comments bottom sheet (for comment notifications)

This is already integrated in `notifications_screen.dart`:
```dart
onTap: () {
  if (widget.item.postId != null && 
      (widget.item.type == NotificationType.comment || widget.item.type == NotificationType.like)) {
    navigateToPostFromNotification(
      context: context,
      postId: widget.item.postId!,
      openComments: widget.item.type == NotificationType.comment,
    );
  }
}
```

### Manual Navigation (from anywhere in the app)
```dart
import 'package:individual_project/utils/navigation_helpers.dart';

// Navigate to post with comments opened
navigateToPostFromNotification(
  context: context,
  postId: 'your-post-id',
  openComments: true,
);

// Navigate to post without opening comments
navigateToPostFromNotification(
  context: context,
  postId: 'your-post-id',
  openComments: false,
);
```

### Using Navigator directly
```dart
Navigator.pushNamed(
  context,
  '/postDetail',
  arguments: {
    'postId': 'your-post-id',
    'openComments': true,
  },
);
```

## Features

### PostDetailPage
- Displays a single post using the existing `PostWidget`
- App bar with back button and "Photo" title
- Scrollable if post content is long
- Auto-opens comments sheet when `openComments: true`

### Auto-open Comments
The comments bottom sheet automatically opens after the page loads using:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _openCommentsSheet();
});
```

This ensures the UI is fully rendered before showing the sheet.

## Route Configuration

Added in `main.dart`:
```dart
case '/postDetail':
  final args = settings.arguments as Map<String, dynamic>?;
  final postId = args?['postId'] as String? ?? '';
  final openComments = args?['openComments'] as bool? ?? false;
  builder = (_) => PostDetailPage(postId: postId, openComments: openComments);
  return FullSlidePageRoute(builder: builder, settings: settings, duration: const Duration(milliseconds: 420));
```

## Example Flow

1. User receives comment: "haetbaaan commented: so cute!!"
2. Notification appears in notifications screen
3. User taps the notification
4. App navigates to `/postDetail` with `postId` and `openComments: true`
5. Post detail page loads, showing the full post
6. Comments bottom sheet automatically opens after frame renders
7. User sees all comments and can reply immediately
