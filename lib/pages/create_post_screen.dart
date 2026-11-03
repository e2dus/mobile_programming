import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'filter_post_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final ImagePicker _picker = ImagePicker();
  AssetEntity? _selectedAsset;
  List<AssetEntity> _selectedAssets = []; // 여러 장 선택
  List<AssetEntity> _recentAssets = [];
  bool _isLoading = true;
  bool _isMultipleMode = false; // 여러 장 선택 모드
  String _selectedTab = 'GALLERY'; // 선택된 탭 (GALLERY, PHOTO, VIDEO)

  @override
  void initState() {
    super.initState();
    _loadRecentImages();
  }

  Future<void> _loadRecentImages({RequestType type = RequestType.image}) async {
    if (kIsWeb) {
      // Web에서는 photo_manager가 제한되거나 오류를 유발할 수 있으므로 건너뜀
      if (mounted) setState(() { _isLoading = false; });
      return;
    }
    // 갤러리 권한 요청
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 최근 사진/비디오 가져오기
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: type,
        onlyAll: true,
      );

      if (paths.isNotEmpty) {
        final AssetPathEntity recentAlbum = paths.first;
        final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
          start: 0,
            // 최근 100개 가져오기
          end: 100,
        );

        if (mounted) {
          setState(() {
            _recentAssets = assets;
            _selectedAsset = assets.isNotEmpty ? assets.first : null;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading assets: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _selectedTab = 'GALLERY';
    });
    await _loadRecentImages(type: RequestType.image);
  }

  Future<void> _pickFromCamera() async {
    setState(() {
      _selectedTab = 'PHOTO';
    });
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      // 카메라로 찍은 사진을 임시로 표시
      // TODO: AssetEntity로 변환 필요
    }
  }

  Future<void> _pickVideo() async {
    setState(() {
      _selectedTab = 'VIDEO';
    });
    await _loadRecentImages(type: RequestType.video);
  }

  void _selectMultiple() async {
    setState(() {
      _isMultipleMode = !_isMultipleMode;
      if (!_isMultipleMode) {
        // 여러 장 모드 해제 시 첫 번째 선택된 이미지로 설정
        _selectedAsset = _selectedAssets.isNotEmpty ? _selectedAssets.first : null;
        _selectedAssets = [];
      } else {
        // 여러 장 모드 활성화 시 현재 선택된 이미지를 선택 목록에 추가
        if (_selectedAsset != null && !_selectedAssets.contains(_selectedAsset)) {
          _selectedAssets = [_selectedAsset!];
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Recents',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 20),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: (_isMultipleMode ? _selectedAssets.isNotEmpty : _selectedAsset != null)
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FilterPostScreen(
                          asset: _isMultipleMode ? null : _selectedAsset,
                          assets: _isMultipleMode ? _selectedAssets : null,
                        ),
                      ),
                    );
                  }
                : null,
            child: Text(
              'Next',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 선택된 이미지 미리보기 (정사각형) + SELECT MULTIPLE 버튼
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width,
                      color: Colors.grey.shade100,
                      child: (!kIsWeb && _selectedAsset != null)
                          ? AssetEntityImage(
                              _selectedAsset!,
                              fit: BoxFit.cover,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize.square(1000),
                            )
                          : const Center(
                              child: Text(
                                'No image selected',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                    ),
                    // 왼쪽 하단 아이콘 (crop/rotate 등)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: 크롭/회전 기능
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.crop_rotate,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    // SELECT MULTIPLE 버튼 (우측 하단)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: _selectMultiple,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isMultipleMode ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isMultipleMode ? Icons.check_circle : Icons.layers_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isMultipleMode ? '${_selectedAssets.length} SELECTED' : 'SELECT MULTIPLE',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // 최근 이미지 그리드 (1행 4개 정사각형)
                Container(
                  height: MediaQuery.of(context).size.width / 4,
                  padding: const EdgeInsets.all(2),
                  child: (_recentAssets.isEmpty || kIsWeb)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.photo_library, size: 32, color: Colors.grey),
                              const SizedBox(height: 4),
                              Text(kIsWeb ? 'Unsupported on web' : 'No images found', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recentAssets.length > 12 ? 12 : _recentAssets.length,
                          itemBuilder: (context, index) {
                            final asset = _recentAssets[index];
                            final isSelected = _isMultipleMode
                                ? _selectedAssets.any((a) => a.id == asset.id)
                                : _selectedAsset?.id == asset.id;
                            final itemSize = MediaQuery.of(context).size.width / 4;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_isMultipleMode) {
                                    // 여러 장 선택 모드
                                    final index = _selectedAssets.indexWhere((a) => a.id == asset.id);
                                    if (index != -1) {
                                      _selectedAssets.removeAt(index);
                                    } else {
                                      _selectedAssets.add(asset);
                                    }
                                    // 선택된 첫 번째 이미지를 미리보기로 표시
                                    if (_selectedAssets.isNotEmpty) {
                                      _selectedAsset = _selectedAssets.first;
                                    } else {
                                      _selectedAsset = null;
                                    }
                                  } else {
                                    // 단일 선택 모드
                                    _selectedAsset = asset;
                                  }
                                });
                              },
                              child: Container(
                                width: itemSize,
                                height: itemSize,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (!kIsWeb)
                                      AssetEntityImage(
                                        asset,
                                        fit: BoxFit.cover,
                                        isOriginal: false,
                                        thumbnailSize: const ThumbnailSize.square(200),
                                      ),
                                    if (isSelected) ...[
                                      if (_isMultipleMode)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${_selectedAssets.indexWhere((a) => a.id == asset.id) + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                    // 비디오인 경우 재생 시간 표시
                                    if (asset.type == AssetType.video)
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _formatDuration(asset.duration),
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
          // 하단 툴바 (갤러리, 사진, 비디오 탭)
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _pickFromGallery,
                        child: Text(
                          'GALLERY',
                          style: TextStyle(
                            color: _selectedTab == 'GALLERY' 
                                ? Colors.black 
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_selectedTab == 'GALLERY')
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.black,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _pickFromCamera,
                        child: Text(
                          'PHOTO',
                          style: TextStyle(
                            color: _selectedTab == 'PHOTO' 
                                ? Colors.black 
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_selectedTab == 'PHOTO')
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.black,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _pickVideo,
                        child: Text(
                          'VIDEO',
                          style: TextStyle(
                            color: _selectedTab == 'VIDEO' 
                                ? Colors.black 
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_selectedTab == 'VIDEO')
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.black,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
