import 'package:flutter/material.dart' hide SearchBar;
import 'package:individual_project/widgets/dm/dm_action_item.dart';
import 'package:individual_project/widgets/dm/dm_appbar.dart';
import 'package:individual_project/components/search_bar.dart';
import 'package:individual_project/widgets/dm/dm_chat_list_section.dart';
import 'package:individual_project/widgets/dm/dm_note_item.dart';


class DirectMessagePage extends StatefulWidget {
  final String currentUserName;

  const DirectMessagePage({super.key, required this.currentUserName});

  @override
  State<DirectMessagePage> createState() => _DirectMessagePageState();
}

class _DirectMessagePageState extends State<DirectMessagePage> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // 첫 프레임을 가볍게 그린 뒤, 무거운 섹션을 활성화하여 push 애니메이션을 부드럽게 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _ready = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DmAppBar(),
      body: ListView(
        children: [
          const SearchBar(),
          const SizedBox(height: 16),
          // Note item
          const DmNoteItem(),
          const SizedBox(height: 12),
          _buildMessagesHeader(),
          // 애니메이션 중에는 가벼운 플레이스홀더, 이후 실제 리스트 렌더
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _ready
                ? const DmChatListSection()
                : const _ChatsSkeleton(),
          ),
          _buildFindFriendsHeader(),
          _buildActionItems(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ... (기존 _buildMessagesHeader 메서드 유지)

  Widget _buildMessagesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(width: 4),
              Icon(Icons.notifications_off_outlined, size: 18),
            ],
          ),
          const Text('Requests (1)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(
              0xFF4438F0), fontSize: 14)),
        ],
      ),
    );
  }

  // ⭐️ 누락된 Find Friends Header 추가
  Widget _buildFindFriendsHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 16.0, bottom: 8.0),
      child: Text(
        'Find friends to follow and message',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
      ),
    );
  }

  // ⭐️ _buildActionItems()의 const를 제거하고 onPressed를 빈 함수로 변경
  Widget _buildActionItems() {
    return Column(
      children: [
        DmActionItem(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Connect contacts',
          subtitle: 'Follow people you know.',
          buttonText: 'Connect',
          onPressed: () {}, // 👈 빈 함수로 변경
          onClose: () {}, // 👈 빈 함수로 변경
        ),
        DmActionItem(
          icon: Icons.search,
          title: 'Search for friends',
          subtitle: 'Find your friends\' accounts.',
          buttonText: 'Search',
          onPressed: () {}, // 👈 빈 함수로 변경
          onClose: () {}, // 👈 빈 함수로 변경
        ),
      ],
    );
  }
}

class _ChatsSkeleton extends StatelessWidget {
  const _ChatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (i) => i).map((_) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 140, color: Colors.grey.shade300),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 90, color: Colors.grey.shade200),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}