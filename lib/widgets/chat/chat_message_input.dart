// lib/widgets/message_input.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
// 💡 프로젝트 구조에 맞게 provider 경로를 맞춰주세요.
import 'package:individual_project/providers/app_providers.dart';

class MessageInput extends ConsumerStatefulWidget {
  final String chatId;

  const MessageInput({super.key, required this.chatId});

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTextEmpty = true;

  @override
  void initState() {
    super.initState();
    // ⭐️ 텍스트 변경 리스너를 붙여 _isTextEmpty 상태를 실시간으로 업데이트합니다.
    _controller.addListener(_updateTextState);
  }

  void _updateTextState() {
    final isTextEmptyNow = _controller.text.trim().isEmpty;
    // 상태가 실제로 변했을 때만 setState를 호출하여 불필요한 재빌드를 최소화합니다.
    if (_isTextEmpty != isTextEmptyNow) {
      setState(() {
        _isTextEmpty = isTextEmptyNow;
      });
    }
  }

  // 💡 메시지 전송 로직 (키보드 유지)
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final messageNotifier = ref.read(messageProvider(widget.chatId).notifier);
    // Gemini API 호출 함수 실행 (사용자 메시지 추가 및 Gemini 응답 요청)
    messageNotifier.sendUserMessageAndGetGeminiResponse(text);

    _controller.clear();
    // ⭐️ 텍스트가 지워진 후에도 포커스를 유지하여 키보드가 내려가는 것을 방지합니다.
    _focusNode.requestFocus();
  }

  // ⭐️ [해결 핵심] 카메라/돋보기 아이콘을 포함하는 Container (항상 반환됨)
  Widget _buildLeadingIconContainer(bool canSend) {
    final Color backgroundColor = canSend ? Colors.white : const Color(0xFF6328A5);
    final Color iconColor = canSend ? const Color(0xFF6328A5) : Colors.white;

    return Container(
      key: const ValueKey('leadingIconContainer'),
      width: 50,
      height: 40,
      alignment: Alignment.center,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Center(
          child: Icon(
            canSend? Icons.search : Icons.camera_alt_rounded,
            color: iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ⭐️ 텍스트가 없을 때 우측 아이콘 그룹 위젯
  Widget _buildTrailingActionIcons() {
    Widget outlined(IconData icon, VoidCallback? onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 2.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2F2F2F), size: 18),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        outlined(Icons.mic_none_rounded, () {}),
        outlined(Icons.image_rounded, _openMediaPickerBottomSheet),
        outlined(Icons.emoji_emotions_outlined, () {}),
        outlined(Icons.add, () {}),
      ],
    );
  }

  // ⭐️ 텍스트가 있을 때 우측 전송 버튼 위젯
  Widget _buildTrailingSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        width: 50,
        height: 36,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.0), // 👈 원형 대신 둥근 사각형으로 변경
          color: const Color(0xFF6328A5), // 보라색 배경
        ),
        child: SvgPicture.asset(
          'assets/icons/dm_send_icon_filled.svg',
        ),
      ),
    );
  }

  Widget? _buildSuffixAction(bool canSend) {
    if (canSend) {
      // 텍스트 입력 중: 전송 버튼 반환
      return Padding(
        padding: const EdgeInsets.only(right: 8.0), // 버튼이 너무 우측에 붙지 않도록 패딩
        child: _buildTrailingSendButton(),
      );
    } else {
      // 텍스트 없을 때: 액션 아이콘 그룹 반환
      return _buildTrailingActionIcons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = !_isTextEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 텍스트 입력 필드
        Padding(
          // 키보드에 가려지지 않도록 bottom padding을 처리합니다.
          padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0 + MediaQuery.of(context).padding.bottom),
          child: Row(
            children: [
              // 1. 텍스트 입력 필드
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: canSend ? 'Hi' : 'Message...', // 힌트 텍스트 조건부 변경
                    filled: true,
                    fillColor: const Color(0xFFE8E8E8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),

                    // ⭐️ prefixIcon을 항상 반환하여 위젯 구조를 안정화합니다.
                    prefixIcon: _buildLeadingIconContainer(canSend),
                    prefixIconConstraints: const BoxConstraints(minWidth: 50, maxWidth: 50, maxHeight: 40),

                    suffixIcon: _buildSuffixAction(canSend),
                    suffixIconConstraints: const BoxConstraints(),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: canSend ? (_) => _sendMessage() : null,
                  textInputAction: TextInputAction.send,
                  textAlignVertical: TextAlignVertical.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updateTextState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openMediaPickerBottomSheet() async {
    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진/미디어 접근 권한이 필요합니다. 설정에서 허용해주세요.')),
        );
      }
      await PhotoManager.openSetting();
      return;
    }

    final List<AssetEntity>? selected = await showModalBottomSheet<List<AssetEntity>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _MediaPickerSheet(
        onImageSelected: (image) {
          // 미리보기 제거
        },
      ),
    );

    if (selected == null || selected.isEmpty) return;
    
    // 전송 버튼을 눌렀을 때만 전송
    await ref
        .read(messageProvider(widget.chatId).notifier)
        .sendUserImagesAndGetGeminiResponse(selected);
  }
}

class _MediaPickerSheet extends StatefulWidget {
  final Function(AssetEntity)? onImageSelected;
  
  const _MediaPickerSheet({this.onImageSelected});

  @override
  State<_MediaPickerSheet> createState() => _MediaPickerSheetState();
}

class _MediaPickerSheetState extends State<_MediaPickerSheet> {
  List<AssetEntity> _assets = const [];
  final List<AssetEntity> _selected = <AssetEntity>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    final AssetPathEntity? recent = paths.isNotEmpty ? paths.first : null;
    final List<AssetEntity> assets = recent != null
        ? await recent.getAssetListPaged(page: 0, size: 200)
        : <AssetEntity>[];

    if (!mounted) return;
    setState(() {
      _assets = assets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Recents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(2),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      itemCount: _assets.length,
                      itemBuilder: (context, index) {
                        final asset = _assets[index];
                        final int selectionIndex = _selected.indexOf(asset);
                        final bool isSelected = selectionIndex != -1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selected.removeAt(selectionIndex);
                              } else {
                                _selected.add(asset);
                              }
                            });
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AssetEntityImage(
                                asset,
                                isOriginal: false,
                                thumbnailSize: const ThumbnailSize.square(400),
                                fit: BoxFit.cover,
                              ),
                              // Top-right selection indicator
                              Positioned(
                                right: 6,
                                top: 6,
                                child: isSelected
                                    ? Container(
                                        width: 22,
                                        height: 22,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                        child: Text(
                                          '${selectionIndex + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                      ),
                              ),
                              if (asset.type == AssetType.video)
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
            ),
            // Bottom-right DM send button (사진 선택했을 때만 표시)
            if (_selected.isNotEmpty)
              Positioned(
                right: 16,
                bottom: 24,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(List<AssetEntity>.from(_selected));
                  },
                  child: Container(
                    width: 56,
                    height: 42,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21.0),
                      color: const Color(0xFF6328A5), // 보라색 배경
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/dm_send_icon_filled.svg',
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

