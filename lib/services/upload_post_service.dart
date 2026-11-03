import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/utils/user_name.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class UploadPostService {
  static Future<void> uploadPostAndInsert({
    AssetEntity? asset,
    List<AssetEntity>? assets,
    required String caption,
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    // 여러 장 우선, 없으면 단일 장
    final assetsToUpload = assets ?? (asset != null ? [asset] : []);
    
    if (assetsToUpload.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No images selected')));
      }
      return;
    }
    debugPrint('[SharePost] ===== START =====');
    debugPrint('[SharePost] Uploading ${assetsToUpload.length} image(s)');

    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id ?? 'anonymous';
    debugPrint('[SharePost] uid=$uid, caption="${caption.replaceAll('\n', ' ')}"');
    
    // 동영상 여부 확인 (첫 번째 asset 기준)
    final firstAsset = assetsToUpload.first;
    final isVideo = firstAsset.type == AssetType.video;
      debugPrint('[SharePost] isVideo=$isVideo');
    
    // 여러 장 이미지 업로드
    List<String> imageUrls = [];
    String? videoUrl;
    String? thumbnailUrl;

    for (int i = 0; i < assetsToUpload.length; i++) {
      final asset = assetsToUpload[i];
        debugPrint('[SharePost] Processing image ${i + 1}/${assetsToUpload.length}: id=${asset.id}');
      
      // 1️⃣ Read bytes
      Uint8List? bytes;
      try {
          debugPrint('[SharePost] 1️⃣ Reading origin bytes...');
        bytes = await asset.originBytes;
        if (bytes == null) {
          throw Exception('originBytes returned null');
        }
            debugPrint('[SharePost] ✅ Read bytes length=${bytes.length}');
      } catch (e, stack) {
            debugPrint('[SharePost] ❌ ERROR reading bytes for image ${i + 1}: $e');
            debugPrint('[SharePost] Stack: $stack');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to read image ${i + 1}: $e')));
        }
        continue; // 다음 이미지로 계속
      }

      // 2️⃣ Upload to storage
      final fileExtension = isVideo ? 'mp4' : 'jpg';
      final contentType = isVideo ? 'video/mp4' : 'image/jpeg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${i}.$fileExtension';
      final storagePath = '$uid/$fileName';
      
      try {
          debugPrint('[SharePost] 2️⃣ Uploading to bucket=post_images, path=$storagePath, type=$contentType');
        await client.storage.from('post_images').uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(contentType: contentType, upsert: true),
            );
            debugPrint('[SharePost] ✅ Upload complete');

            debugPrint('[SharePost] 3️⃣ Getting public URL...');
        final publicUrl = client.storage.from('post_images').getPublicUrl(storagePath);
              debugPrint('[SharePost] ✅ Public URL=$publicUrl');
        
        if (isVideo) {
          videoUrl = publicUrl;
          // 동영상인 경우 썸네일 생성 및 업로드
                debugPrint('[SharePost] 📸 Generating video thumbnail...');
          try {
            final videoFile = await asset.file;
            if (videoFile != null) {
              final thumbnailBytes = await VideoThumbnail.thumbnailData(
                video: videoFile.path,
                imageFormat: ImageFormat.JPEG,
                maxWidth: 640,
                quality: 85,
              );
              
              if (thumbnailBytes != null) {
                final thumbnailFileName = '${timestamp}_thumb.jpg';
                final thumbnailPath = '$uid/$thumbnailFileName';
                
                    debugPrint('[SharePost] 📤 Uploading thumbnail...');
                await client.storage.from('post_images').uploadBinary(
                      thumbnailPath,
                      thumbnailBytes,
                      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
                    );
                
                thumbnailUrl = client.storage.from('post_images').getPublicUrl(thumbnailPath);
                      debugPrint('[SharePost] ✅ Thumbnail URL=$thumbnailUrl');
              }
            }
          } catch (e) {
                debugPrint('[SharePost] ⚠️ Thumbnail generation failed (non-critical): $e');
          }
        } else {
          imageUrls.add(publicUrl);
        }
      } catch (e, stack) {
          debugPrint('[SharePost] ❌ ERROR during upload for image ${i + 1}: $e');
          debugPrint('[SharePost] Stack: $stack');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed for image ${i + 1}: $e')));
        }
        continue; // 다음 이미지로 계속
      }
    }

    if (imageUrls.isEmpty && videoUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload any images')));
      }
      return;
    }

    // 4️⃣ Insert row to posts
    try {
      final username = getCurrentUserName(ref);
      final now = DateTime.now().toUtc();
      final payload = isVideo
          ? {
              // 동영상인 경우
              'username': username,
              'caption': caption,
              'postImageUrls': thumbnailUrl != null ? [thumbnailUrl] : [],
              'videoUrl': videoUrl,
              'likesCount': 0,
              'time': now.toIso8601String(),
              'isLiked': false,
              'isBookmarked': false,
              'currentPageIndex': 0,
              'isReel': true,
            }
          : {
              // 이미지인 경우
              'username': username,
              'caption': caption,
              'postImageUrls': imageUrls, // 여러 장 이미지 URL 저장
              'likesCount': 0,
              'time': now.toIso8601String(),
              'isLiked': false,
              'isBookmarked': false,
              'currentPageIndex': 0,
              'isReel': false,
            };
      debugPrint('[SharePost] 4️⃣ Inserting row into posts...');
      debugPrint('[SharePost] Payload: $payload');
      final inserted = await client.from('posts').insert(payload).select('id');
        debugPrint('[SharePost] ✅ Insert result: $inserted');
      
      // 게시물 ID 추출
      String? postId;
      if (inserted.isNotEmpty) {
        postId = inserted[0]['id']?.toString();
      }
      
      // 4️⃣-1️⃣ enuheu 계정으로 10초 후 댓글 달기
      if (postId != null) {
        // 10초 후 댓글 추가 (비동기로 실행, 게시물 업로드에 영향 없음)
        Future.delayed(const Duration(seconds: 10), () async {
          try {
            debugPrint('[SharePost] 4️⃣-1️⃣ Adding comment from enuheu after 10 seconds...');
            
            // 댓글 추가
            await client.from('comments').insert({
              'post_id': postId,
              'username': 'enuheu',
              'content': 'hi',
              'time': DateTime.now().toUtc().toIso8601String(),
              'heart_count': 0,
              'my_heart': false,
            });
            
            debugPrint('[SharePost] ✅ Comment added by enuheu');
          } catch (e, stack) {
            debugPrint('[SharePost] ⚠️ ERROR adding comment (non-critical): $e');
            debugPrint('[SharePost] Stack: $stack');
            // 댓글 추가 실패는 게시물 업로드에 영향을 주지 않도록 함
          }
        });
      }
    } catch (e, stack) {
        debugPrint('[SharePost] ❌ ERROR during insert: $e');
        debugPrint('[SharePost] Stack: $stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insert failed: $e')));
      }
      return;
    }

    // 5️⃣ Reload posts
    if (context.mounted) {
      try {
          debugPrint('[SharePost] 5️⃣ Reloading posts...');
        await ref.read(postsProvider.notifier).loadInitialPosts();
            debugPrint('[SharePost] ✅ Reload complete');
        
        // 업로드 성공 플래그 설정 (피드 화면에서 알림 표시용)
        final firstImageUrl = imageUrls.isNotEmpty ? imageUrls.first : thumbnailUrl;
        ref.read(newPostUploadedProvider.notifier).state = {
          'shouldShow': true,
          'imageUrl': firstImageUrl,
        };
          debugPrint('[SharePost] 🔔 Notification flag set: shouldShow=true, imageUrl=$firstImageUrl');
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post shared')));
      } catch (e, stack) {
          debugPrint('[SharePost] ⚠️ ERROR during reload (non-critical): $e');
          debugPrint('[SharePost] Stack: $stack');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post shared (reload failed)')));
      }
    }
    debugPrint('[SharePost] ===== END =====');
  }
}
