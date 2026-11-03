import 'package:flutter_riverpod/flutter_riverpod.dart' show FutureProvider;
import 'package:flutter_riverpod/legacy.dart';
import 'package:individual_project/models/chat_model.dart';
import 'package:individual_project/models/comment_model.dart';
import 'package:individual_project/models/message_model.dart';
import 'package:individual_project/models/post_model.dart';
import 'package:individual_project/models/story_model.dart';
import 'package:individual_project/models/user_model.dart';
import 'package:individual_project/providers/chats_notifier.dart';
import 'package:individual_project/providers/comments_notifier.dart';
import 'package:individual_project/providers/message_notifier.dart';
import 'package:individual_project/providers/post_notifier.dart';
import 'package:individual_project/providers/posts_notifier.dart';
import 'package:individual_project/providers/stories_notifier.dart';
import 'package:individual_project/providers/typing_notifier.dart';
import 'package:individual_project/providers/users_notifier.dart';
import 'package:individual_project/providers/video_player_notifier.dart';
import 'package:individual_project/states/video_player_state.dart';

final appInitializationProvider = FutureProvider<bool>((ref) async {
  await Future.wait([
    ref.read(usersProvider.notifier).loadUsers(),
    ref.read(postsProvider.notifier).loadInitialPosts(),
    ref.read(storiesProvider.notifier).loadInitialStories(),
    ref.read(chatsProvider.notifier).loadInitialChats(),
    ref.read(commentsProvider.notifier).loadAllComments(),
  ]);
  return true;
});

final postsProvider = StateNotifierProvider<PostsNotifier, List<PostModel>>((ref) {
  return PostsNotifier([]);
});

final storiesProvider = StateNotifierProvider<StoriesNotifier, List<StoryModel>>((ref) {
  return StoriesNotifier([]);
});

final usersProvider = StateNotifierProvider<UsersNotifier, Map<String, UserModel>>((ref) {
  return UsersNotifier(ref);
});

final chatsProvider = StateNotifierProvider<ChatsNotifier, List<ChatModel>>((ref) {
  return ChatsNotifier([]);
});

final commentsProvider = StateNotifierProvider<CommentsNotifier, List<CommentModel>>((ref) {
  return CommentsNotifier([]);
});

final postNotifierProvider =
    StateNotifierProvider.family<PostNotifier, PostModel, String>((ref, id) {
  final postsList = ref.watch(postsProvider);

  final initialPost = postsList.firstWhere(
    (post) => post.id == id,
    orElse: () => PostModel(
      id: id,
      username: 'Unknown',
      profileImageUrl: 'assets/images/avatars/default_profile.jpg',
      postImageUrls: const [],
      likesCount: 0,
      caption: '',
      timeAgo: '',
    ),
  );

  return PostNotifier(initialPost);
});

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

final videoPlayerProvider =
    StateNotifierProvider.family<VideoPlayerNotifier, VideoPlayerState, String>(
  (ref, postID) => VideoPlayerNotifier(postID),
);

final messageProvider =
    StateNotifierProvider.family<MessageNotifier, List<MessageModel>, String>(
  (ref, chatId) {
    final notifier = MessageNotifier(ref, chatId, []);
    notifier.loadMessages();
    return notifier;
  },
);

final isTypingProvider =
    StateNotifierProvider.family<TypingNotifier, bool, String>(
  (ref, chatId) => TypingNotifier(),
);

final profilePauseSheetTriggerProvider = StateProvider<bool>((ref) => false);

final newPostUploadedProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'shouldShow': false,
  'imageUrl': null,
});

