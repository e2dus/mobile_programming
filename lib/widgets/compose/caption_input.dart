import 'package:flutter/material.dart';
import 'package:individual_project/widgets/compose/chip_button.dart';

class CaptionInput extends StatelessWidget {
  const CaptionInput({super.key, required this.controller, this.focusNode});
  final TextEditingController controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: const InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: TextStyle(color: Colors.black54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            minLines: 1,
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              ChipButton(label: 'Poll', icon: Icons.poll),
              SizedBox(width: 8),
              ChipButton(label: 'Prompt', icon: Icons.lightbulb_outline),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
