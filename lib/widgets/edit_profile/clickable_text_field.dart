import 'package:flutter/material.dart';

class ClickableTextField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  final String hint;
  final Color? textColor;
  final double? dividerSpacing;
  final bool showLeadingArrow;

  const ClickableTextField({
    super.key,
    required this.value,
    required this.onTap,
    this.hint = 'Name',
    this.textColor,
    this.dividerSpacing,
    this.showLeadingArrow = false,
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
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? hint : value,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor ?? (value.isEmpty ? Colors.grey.shade400 : Colors.black),
                    ),
                  ),
                ),
                if (showLeadingArrow)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.chevron_right, color: Colors.grey.shade600),
                  ),
              ],
            ),
            SizedBox(height: dividerSpacing ?? 0),
            Container(
              height: 1.5,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}
