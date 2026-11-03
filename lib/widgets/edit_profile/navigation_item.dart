import 'package:flutter/material.dart';

class NavigationItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final String? trailing;
  final bool showArrow;
  final bool showDivider;

  const NavigationItem({
    super.key,
    required this.title,
    required this.onTap,
    this.trailing,
    this.showArrow = true,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    if (trailing != null)
                      Text(
                        trailing!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (trailing != null && showArrow) const SizedBox(width: 8),
                    if (showArrow)
                      Icon(Icons.chevron_right, color: Colors.grey.shade600),
                  ],
                ),
              ],
            ),
            if (showDivider) ...[
              const SizedBox(height: 10),
              Container(
                height: 1.5,
                color: Colors.grey.shade300,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
