import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:individual_project/providers/app_providers.dart';
// Extracted pieces
import 'package:individual_project/widgets/compose/compose_preview.dart';
import 'package:individual_project/widgets/compose/caption_input.dart';
import 'package:individual_project/widgets/compose/options_list.dart';
import 'package:individual_project/sheets/share_to_facebook_sheet.dart';
import 'package:individual_project/sheets/sharing_posts_sheet.dart';
import 'package:individual_project/services/upload_post_service.dart';

class ComposePostScreen extends ConsumerStatefulWidget {
  const ComposePostScreen({super.key, this.asset, this.assets});

  final AssetEntity? asset;
  final List<AssetEntity>? assets; // 여러 장 지원

  @override
  ConsumerState<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends ConsumerState<ComposePostScreen> {
  final TextEditingController _captionCtrl = TextEditingController();
  final FocusNode _captionFocusNode = FocusNode();
  bool _isCaptionFocused = false;

  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 자동으로 Sharing posts 시트 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showSharingPostsSheet(context);
    });
    // 포커스 상태 리스너 추가
    _captionFocusNode.addListener(() {
      setState(() {
        _isCaptionFocused = _captionFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _captionFocusNode.dispose();
    super.dispose();
  }

  void _onOkPressed() {
    // 키보드 내리기
    _captionFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New post',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          if (_isCaptionFocused)
            TextButton(
              onPressed: _onOkPressed,
              child: Text(
                'OK',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Small image preview centered
          ComposePreview(asset: widget.asset, assets: widget.assets),
          const SizedBox(height: 12),
          // Caption input + buttons
          CaptionInput(controller: _captionCtrl, focusNode: _captionFocusNode),
          const Divider(height: 0),
          const Expanded(child: OptionsList()),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onSharePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Share', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSharePressed() async {
    // Show sheet and proceed only if confirmed
    final confirmed = await showShareToFacebookSheet(
      context,
      onConfirm: () {},
    );
    if (confirmed != true) return;

    final assetsToUpload = widget.assets ?? (widget.asset != null ? [widget.asset!] : []);
    
    if (assetsToUpload.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No image selected')));
      }
      return;
    }

    // Show processing dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button from closing
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'PROCESSING',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await UploadPostService.uploadPostAndInsert(
        assets: assetsToUpload,
        caption: _captionCtrl.text.trim(),
        ref: ref,
        context: context,
      );

      // Close processing dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Trigger pause sheet on profile and navigate back to root
      ref.read(profilePauseSheetTriggerProvider.notifier).state = true;
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Close processing dialog on error
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload post: $e')),
        );
      }
    }
  }
}
