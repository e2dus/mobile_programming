import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/utils/user_name.dart';
import 'package:individual_project/pages/gallery_picker_page.dart';
import 'package:individual_project/pages/edit_name_page.dart';
import 'package:individual_project/pages/edit_bio_page.dart';
import 'package:individual_project/widgets/edit_profile/bottom_sheet_option.dart';
import 'package:individual_project/widgets/edit_profile/clickable_text_field.dart';
import 'package:individual_project/widgets/edit_profile/navigation_item.dart';
import 'package:individual_project/widgets/edit_profile/section_header.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  String? _editedName; // 편집된 이름을 저장
  String? _editedBio; // 편집된 Bio를 저장
  bool _isProfilePressed = false; // 프로필 사진 눌림 상태
  bool _isAvatarPressed = false; // 아바타 아이콘 눌림 상태

  @override
  void initState() {
    super.initState();
    // 페이지 로드 후 아바타 생성 대화상자 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCreateAvatarDialog();
    });
  }

  void _showCreateAvatarDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar illustration
            Image.asset(
              'assets/images/create_avatar.png',
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'Create your avatar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Get your own personalized stickers to share in stories and chats.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          ),
        ),
        actionsPadding: EdgeInsets.zero,
        actions: [
          Column(
            children: [
              const Divider(height: 1, thickness: 0.5),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: 아바타 생성 페이지로 이동
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Avatar creation feature coming soon!'),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  'Create avatar',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  'Not now',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _animateProfilePicture() async {
    setState(() {
      _isProfilePressed = true;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _isProfilePressed = false;
    });
    // 애니메이션 완료 후 옵션 표시
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      final users = ref.read(usersProvider);
      final currentUserName = getCurrentUserName(ref);
      final currentUser = users.values.firstWhere(
        (u) => u.username == currentUserName,
        orElse: () => users.values.first,
      );
      _showProfilePictureOptions(context, currentUser.profileImageUrl);
    }
  }

  void _animateAvatar() async {
    setState(() {
      _isAvatarPressed = true;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _isAvatarPressed = false;
    });
    // 애니메이션 완료 후 스낵바 표시
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Avatar creation feature coming soon!'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  void _showProfilePictureOptions(BuildContext context, String profileImageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool selectedProfilePicture = true;
        bool selectedAvatar = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Profile pictures at top
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                        selectedProfilePicture = true;
                        selectedAvatar = false;
                      setState(() {});
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: profileImageUrl.startsWith('http')
                                  ? NetworkImage(profileImageUrl) as ImageProvider
                                  : AssetImage(profileImageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 2,
                          color: selectedProfilePicture ? Colors.black : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 30),
                  GestureDetector(
                    onTap: () {
                        selectedProfilePicture = false;
                        selectedAvatar = true;
                      setState(() {});
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.face_outlined,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 2,
                          color: selectedAvatar ? Colors.black : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, thickness: 0.5),
              // Options
              BottomSheetOption(
                icon: Icons.photo_library_outlined,
                text: 'Choose from library',
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const GalleryPickerPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                  if (result != null) {
                    // TODO: Handle selected image file
                    debugPrint('Selected image: $result');
                  }
                },
              ),
              BottomSheetOption(
                icon: Icons.facebook,
                text: 'Import from Facebook',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement import from Facebook
                },
              ),
              BottomSheetOption(
                icon: Icons.camera_alt_outlined,
                text: 'Take photo',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement take photo
                },
              ),
              BottomSheetOption(
                icon: Icons.delete_outline,
                text: 'Delete',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement delete profile picture
                },
                isDestructive: true,
              ),
              const SizedBox(height: 12),
              // Footer text
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your profile picture and avatar are visible to everyone on and off Instagram.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Learn more',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);
    final currentUserName = getCurrentUserName(ref);
    final currentUser = users.values.firstWhere(
      (u) => u.username == currentUserName,
      orElse: () => users.values.first,
    );

    // 편집된 이름이 있으면 사용, 없으면 원래 이름 사용
    final displayName = _editedName ?? currentUser.name ?? '';
    final displayBio = _editedBio ?? currentUser.bio ?? '';

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
          'Edit profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Profile pictures section
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Current profile picture
                  GestureDetector(
                    onTap: _animateProfilePicture,
                    child: AnimatedScale(
                      scale: _isProfilePressed ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: currentUser.profileImageUrl.startsWith('http')
                            ? NetworkImage(currentUser.profileImageUrl) as ImageProvider
                            : AssetImage(currentUser.profileImageUrl),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Add profile picture icon
                  GestureDetector(
                    onTap: _animateAvatar,
                    child: AnimatedScale(
                      scale: _isAvatarPressed ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_outlined,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _showProfilePictureOptions(context, currentUser.profileImageUrl),
                child: Text(
                  'Change profile picture',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name field
            const SectionHeader('Name'),
            ClickableTextField(
              value: displayName,
              hint: 'Name',
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditNamePage(
                      currentName: displayName,
                      userId: currentUser.id,
                    ),
                  ),
                );
                if (result != null && result != displayName) {
                  setState(() {
                    _editedName = result;
                  });
                }
              },
            ),
            const SizedBox(height: 6),
            // Username field
            const SectionHeader('Username'),
            ClickableTextField(
              value: currentUser.username,
              hint: 'Username',
              onTap: () {
                // TODO: Implement edit username
              },
            ),
            const SizedBox(height: 10),

            ClickableTextField(
              value: currentUser.pronouns ?? '',
              hint: 'Pronouns',
              textColor: Colors.grey.shade600,
              dividerSpacing: 10.0,
              onTap: () {
                // TODO: Implement edit pronouns
              },
            ),
            const SizedBox(height: 6),
            const SectionHeader('Bio'),
            ClickableTextField(
              value: displayBio,
              hint: 'Bio',
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBioPage(
                      currentBio: displayBio,
                      userId: currentUser.id,
                    ),
                  ),
                );
                if (result != null && result != displayBio) {
                  setState(() {
                    _editedBio = result;
                  });
                }
              },
            ),
            const SizedBox(height: 6),
            // Add link
            NavigationItem(title: 'Add link', onTap: () {}, showArrow: false),
            const SizedBox(height: 12),
            // Add banner
            NavigationItem(title: 'Add banners', onTap: () {}),
            const SizedBox(height: 12),
            // Gender
            const SectionHeader('Gender'),
            ClickableTextField(
              value: 'Prefer not to say',
              hint: 'Gender',
              showLeadingArrow: true,
              onTap: () {
                // TODO: Implement edit gender
              },
            ),
            const SizedBox(height: 6),
            // Music
            NavigationItem(
              title: 'Music',
              trailing: 'Add music to your profile',
              showDivider: true,
              onTap: () {
                // TODO: Implement add music
              },
            ),
            const SizedBox(height: 6),
            // Switch to professional account
            const Divider(height: 6, thickness: 0.5),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Switch to professional account',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 6, thickness: 0.5),
            const SizedBox(height: 8),
            // Personal information settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Personal information settings',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 6, thickness: 0.5),
            const SizedBox(height: 8),
            // Show your profile is verified
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Show your profile is verified',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 6, thickness: 0.5),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

}
