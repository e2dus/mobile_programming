import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/components/story_icon.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:individual_project/utils/user_name.dart';

class DmNoteItem extends ConsumerWidget {
  const DmNoteItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final currentUserName = getCurrentUserName(ref);
    final currentUser = users.values.firstWhere(
      (u) => u.username == currentUserName,
      orElse: () => users.values.first,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 20.0, bottom: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Note icon with StoryIcon + speech bubble overlay
              Stack(
                clipBehavior: Clip.none,
                children: [
                  StoryIcon(
                    profileImageUrl: currentUser.profileImageUrl,
                    username: currentUserName,
                    hasViewed: true,
                    isMyStory: false,
                    onTap: () {
                      // TODO: Open note creation or note viewer
                    },
                    isMainPageStory: false,
                    size: 70,
                  ),
                  // Speech bubble overlay
                  Positioned(
                    top: -20,
                    left: 0,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 90),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "What's on your playlist?",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Label
              Text(
                "Your note",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
