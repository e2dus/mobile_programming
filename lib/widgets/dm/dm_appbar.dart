import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/utils/user_name.dart';

class DmAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const DmAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserName = getCurrentUserName(ref);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Row(
        children: [
          Text(
            currentUserName,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 20),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note_outlined, color: Colors.black, size: 30),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}