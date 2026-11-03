import 'package:flutter/material.dart';

class OptionsList extends StatelessWidget {
  const OptionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _itemTile(context, Icons.person_outline, 'Tag people', showDivider: false, verticalPadding: 1),
        Transform.translate(
          offset: const Offset(0, -8),
          child: _itemTile(context, Icons.location_on_outlined, 'Add location', showDivider: false, verticalPadding: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'People you share this content with can see the location you tag and view this content on the map.',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 8, thickness: 8, color: Color(0xFFE0E0E0)),
        _itemTile(
          context,
          Icons.remove_red_eye_outlined,
          'Audience',
          showDivider: false,
          verticalPadding: 1,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Everyone', style: TextStyle(color: Colors.black54)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
            ],
          ),
        ),
        _itemTile(
          context,
          Icons.share_outlined,
          'Also share on…',
          showDivider: false,
          verticalPadding: 1,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Off', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
            ],
          ),
        ),
        const Divider(height: 8, thickness: 8, color: Color(0xFFE0E0E0)),
        _itemTile(context, Icons.more_horiz, 'More options'),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _itemTile(BuildContext context, IconData icon, String title, {Widget? trailing, String? subtitle, bool showDivider = true, double? verticalPadding}) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding ?? 2),
          leading: Icon(icon, color: Colors.black87, size: 24),
          title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          subtitle: subtitle == null ? null : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.black54),
          onTap: () {},
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
