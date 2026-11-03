import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:individual_project/pages/notifications_screen.dart';

class InstagramAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const InstagramAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  ConsumerState<InstagramAppBar> createState() => _InstagramAppBarState();
}

class _InstagramAppBarState extends ConsumerState<InstagramAppBar>  {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      flexibleSpace: Container(color: Colors.white),
      title: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Image.asset(
          'assets/images/logo.jpg',
          height: 30,
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/heart_instagram.svg',
            width: 28,
            height: 28,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              Navigator.of(context).pushNamed('/directMessage');
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                'assets/icons/dm_instagram.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FastCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  final Duration customDuration;
  FastCupertinoPageRoute({
    required super.builder,
    required this.customDuration,
    super.settings,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => customDuration;

  @override
  Duration get reverseTransitionDuration => customDuration;
}

