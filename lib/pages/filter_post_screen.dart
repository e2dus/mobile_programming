import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'compose_post_screen.dart';

class FilterPostScreen extends StatefulWidget {
  final AssetEntity? asset;
  final List<AssetEntity>? assets; // 여러 장 지원

  const FilterPostScreen({super.key, this.asset, this.assets});

  @override
  State<FilterPostScreen> createState() => _FilterPostScreenState();
}

class _FilterPostScreenState extends State<FilterPostScreen> {

  final List<Map<String, dynamic>> _templates = [
    {
      'image': 'assets/images/A day filled with fluf.png',
      'title': 'A day filled with fluf..',
      'subtitle': '포구',
    },
    {
      'image': 'assets/images/이웃집 토토로.png',
      'title': '이웃집 토토로 とな..',
      'subtitle': '단코하꾸',
    },
    {
      'image': 'assets/images/if it\'s cute, that\'s it.png',
      'title': 'If it\'s cute, that\'s it',
      'subtitle': 'Moon Blues',
    },
  ];

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
        actions: [
          // Magic Wand/Interconnected Circles/Gallery/Text icons
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined, color: Colors.black, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.merge_type_outlined, color: Colors.black, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Colors.black, size: 28),
            onPressed: () {},
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.text_fields, color: Colors.black, size: 24),
                onPressed: () {},
              ),
              Positioned(
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Main preview area - selected image
          Expanded(
            child: Stack(
              children: [
                Container(
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: (widget.assets != null && widget.assets!.isNotEmpty)
                          ? AssetEntityImage(
                              widget.assets!.first,
                              fit: BoxFit.contain,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize.square(1000),
                            )
                          : (widget.asset != null)
                              ? AssetEntityImage(
                                  widget.asset!,
                                  fit: BoxFit.contain,
                                  isOriginal: false,
                                  thumbnailSize: const ThumbnailSize.square(1000),
                                )
                              : const Center(child: Text('No image selected')),
                ),
                // Expand icon at bottom left
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom section with templates/filters
          Container(
            height: 247,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Column(
              children: [
                // Templates scroll list
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: _templates.length + 1, // +1 for Browse button
                    itemBuilder: (context, index) {
                      // First item: Browse button
                      if (index == 0) {
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.music_note,
                                    size: 40,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Browse',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Other items: Templates
                      final templateIndex = index - 1;
                      final template = _templates[templateIndex];
                      
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.asset(
                                  template['image'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              template['title'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              template['subtitle'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Bottom buttons row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      // Edit button (gray)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Show edit options
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: MediaQuery.of(context).size.width * 0.6),
                      
                      // Next button (blue, expanded)
                      Expanded(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ComposePostScreen(
                                    asset: widget.asset,
                                    assets: widget.assets,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Next',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 13),
                              ],
                            ),
                          ),
                        ),
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
}
