import 'package:flutter/material.dart';

class DmActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onPressed;
  final VoidCallback? onClose; // 닫기 버튼은 선택 사항일 수 있습니다.

  const DmActionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    this.onClose, // 선택적 인자
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // 1. 아이콘 (CircleAvatar로 배경색과 테두리 효과)
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade100,
            child: Icon(icon, color: Colors.black, size: 20),
          ),

          const SizedBox(width: 12),

          // 2. 텍스트 그룹 (제목 + 부제목)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          // 3. 액션 버튼 (Connect / Search)
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4438F0),
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 30),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          // 4. 닫기 아이콘 (X 표시)
          if (onClose != null) ...[ // onClose 콜백이 있을 때만 닫기 버튼 표시
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close, color: Colors.grey, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
