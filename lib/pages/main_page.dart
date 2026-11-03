import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/pages/instagram_feed_screen.dart';
import 'package:individual_project/pages/profile_screen.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/widgets/bottom_nav_bar.dart';
import 'package:individual_project/widgets/instagram_app_bar.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  static final List<Widget> _screens = [
    const InstagramFeedScreen(),
    const Center(child: Text('검색 페이지 (Search Tab)')),
    const Center(child: Text('게시물 업로드 (Add Tab)')),
    const Center(child: Text('릴스 (Reels Tab)')),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      appBar: currentIndex == 0 ? const InstagramAppBar() : null,

      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: const InstagramBottomNavBar(),
    );
  }
}
