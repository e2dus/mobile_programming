import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/providers/app_providers.dart';

class EditBioPage extends ConsumerStatefulWidget {
  final String currentBio;
  final String userId;

  const EditBioPage({
    super.key,
    required this.currentBio,
    required this.userId,
  });

  @override
  ConsumerState<EditBioPage> createState() => _EditBioPageState();
}

class _EditBioPageState extends ConsumerState<EditBioPage> {
  late TextEditingController _bioController;
  final FocusNode _focusNode = FocusNode();
  final int _maxLength = 118;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.currentBio);
    
    // 화면이 빌드된 후 자동으로 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLength = _bioController.text.length;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bio',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              final newBio = _bioController.text.trim();
              
              // Bio가 변경되지 않았으면 그냥 돌아가기
              if (newBio == widget.currentBio) {
                Navigator.pop(context);
                return;
              }

              // 로딩 표시
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // DB 업데이트 (Supabase + 로컬 상태)
              final success = await ref
                  .read(usersProvider.notifier)
                  .updateUserBio(widget.userId, newBio.isEmpty ? null : newBio);

              if (mounted) {
                Navigator.pop(context); // 로딩 닫기

                if (success) {
                  Navigator.pop(context, newBio); // 변경된 bio와 함께 돌아가기
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bio updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update bio'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bio label
                    Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bio input field
                    TextField(
                      controller: _bioController,
                      focusNode: _focusNode,
                      maxLength: _maxLength,
                      maxLines: null,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Bio',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        counterText: '', // 기본 카운터 숨김
                      ),
                      onChanged: (value) {
                        setState(() {}); // 글자 수 업데이트를 위해
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 키보드 위에 붙는 문구 영역
          AnimatedPadding(
            padding: EdgeInsets.only(
              left: 0,
              right: 0,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Column(
              children: [
                // Character count (오른쪽 위)
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_maxLength - currentLength}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                      bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    ),
                  ),
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Your bio is visible to everyone on and off Instagram. ',
                          ),
                          TextSpan(
                            text: 'Learn more',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
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
    );
  }
}
