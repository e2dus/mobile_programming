import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:individual_project/providers/app_providers.dart';

class InstagramBottomNavBar extends ConsumerWidget {
  const InstagramBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final users = ref.watch(usersProvider);

    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    final loggedInUser = users.values.firstWhere(
      (u) => u.login == true,
      orElse: () => users.values.first,
    );

    final profileImageUrl = loggedInUser.profileImageUrl;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        ref.read(bottomNavIndexProvider.notifier).state = index;
      },

      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,

      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            currentIndex == 0 ? 'assets/icons/ic_home_clicked.svg' : 'assets/icons/ic_home.svg',
            width: 30,
            height: 30,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            currentIndex == 1 ? 'assets/icons/ic_search_clicked.svg' : 'assets/icons/ic_search.svg',
            width: 30,
            height: 30,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/ic_plus.svg',
            width: 30,
            height: 30,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            currentIndex == 3 ? 'assets/icons/ic_reals_clicked.svg' : 'assets/icons/ic_reals.svg',
            width: 30,
            height: 30,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          label: 'Reels',
        ),
        BottomNavigationBarItem(
          icon: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: currentIndex == 4 ? Colors.black : Colors.transparent,
                width: 2,
              ),
              image: DecorationImage(
                image: profileImageUrl.startsWith('http')
                    ? NetworkImage(profileImageUrl) as ImageProvider
                    : AssetImage(profileImageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}