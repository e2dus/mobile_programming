import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/widgets/post/post_widget.dart';
import 'package:individual_project/widgets/post/post_comments_bottom_sheet.dart';

/// Single post detail page - shown when user taps a comment notification
class PostDetailPage extends ConsumerStatefulWidget {
  final String postId;
  final bool openComments; // true if coming from notification

  const PostDetailPage({
    super.key,
    required this.postId,
    this.openComments = false,
  });

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  @override
  void initState() {
    super.initState();
    // Auto-open comments bottom sheet if coming from notification
    if (widget.openComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCommentsSheet();
      });
    }
  }

  void _openCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => PostCommentsBottomSheet(
          postId: widget.postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Photo',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: PostWidget(postID: widget.postId),
      ),
    );
  }
}
