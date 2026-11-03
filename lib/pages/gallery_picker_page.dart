import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/utils/user_name.dart';

class GalleryPickerPage extends ConsumerStatefulWidget {
  const GalleryPickerPage({super.key});

  @override
  ConsumerState<GalleryPickerPage> createState() => _GalleryPickerPageState();
}

class _GalleryPickerPageState extends ConsumerState<GalleryPickerPage> {
  List<AssetEntity> _mediaList = [];
  AssetEntity? _selectedMedia;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    if (kIsWeb) {
      setState(() { _isLoading = false; });
      return;
    }

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    debugPrint('Permission state: ${ps.isAuth}');
    
    if (!ps.isAuth) {
      debugPrint('Permission denied, opening settings');
      await PhotoManager.openSetting();
      return;
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    debugPrint('Found ${albums.length} albums');

    if (albums.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final List<AssetEntity> media = await albums[0].getAssetListRange(
      start: 0,
      end: 100, // Load first 100 images
    );

    debugPrint('Loaded ${media.length} images');

    setState(() {
      _mediaList = media;
      if (media.isNotEmpty) {
        _selectedMedia = media[0]; // Select first image by default
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recents',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _selectedMedia == null
                ? null
                : () async {
                    try {
                      // Processing 로딩 대화상자 표시
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(width: 20),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      // 선택한 이미지 파일 가져오기
                      final file = await _selectedMedia!.file;
                      if (file == null) {
                        if (mounted) Navigator.pop(context); // 로딩 닫기
                        return;
                      }

                      // 현재 로그인한 사용자 가져오기
                      final currentUserName = getCurrentUserName(ref);
                      final users = ref.read(usersProvider);
                      final currentUser = users.values.firstWhere(
                        (u) => u.username == currentUserName,
                      );

                      // 프로필 이미지 업로드
                      final newImageUrl = await ref
                          .read(usersProvider.notifier)
                          .uploadProfileImage(currentUser.id, file.path);

                      if (mounted) {
                        Navigator.pop(context); // 로딩 닫기
                        
                        if (newImageUrl != null) {
                          // 성공 - 결과와 함께 돌아가기
                          Navigator.pop(context, newImageUrl);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile picture updated!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          // 실패
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update profile picture'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // 로딩 닫기
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
          child: Text(
            'Done',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Large circular preview at top
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Center(
            child: (kIsWeb || _selectedMedia == null)
                          ? const Text('No image selected')
                          : Container(
                              width: 510,
                              height: 510,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                  child: AssetEntityImage(
                                    _selectedMedia!,
                                    isOriginal: false,
                                    thumbnailSize: const ThumbnailSize.square(1000),
                                    fit: BoxFit.cover,
                                  ),
                              ),
                            ),
                    ),
                  ),
                ),
                // Shadow divider
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 4,
                        spreadRadius: 3,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    color: Colors.grey.shade300,
                  ),
                ),
                // Circular thumbnails at bottom (2 rows)
                Container(
                  height: 200,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
          child: (kIsWeb || _mediaList.isEmpty)
                      ? const Center(child: Text('No images found'))
                      : GridView.builder(
                          scrollDirection: Axis.vertical,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemCount: _mediaList.length,
                          itemBuilder: (context, index) {
                            final media = _mediaList[index];
                            final isSelected = _selectedMedia?.id == media.id;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMedia = media;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: AssetEntityImage(
                                    media,
                                    isOriginal: false,
                                    thumbnailSize: const ThumbnailSize.square(300),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
