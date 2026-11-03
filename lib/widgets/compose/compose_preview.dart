import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ComposePreview extends StatelessWidget {
  const ComposePreview({super.key, required this.asset, this.assets});
  final AssetEntity? asset;
  final List<AssetEntity>? assets; // 여러 장 지원

  @override
  Widget build(BuildContext context) {
    final displayAssets = assets ?? (asset != null ? [asset!] : []);
    
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.grey.shade100,
            child: (!kIsWeb && displayAssets.isNotEmpty)
                ? Stack(
                    children: [
                      AssetEntityImage(
                        displayAssets.first,
                        fit: BoxFit.cover,
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(800),
                      ),
                      if (displayAssets.length > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${displayAssets.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(child: Icon(Icons.image, color: Colors.grey, size: 48)),
          ),
        ),
      ),
    );
  }
}
