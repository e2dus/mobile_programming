import 'package:flutter_riverpod/legacy.dart';
// 💡 챗봇의 타이핑 상태를 관리하는 Notifier
class TypingNotifier extends StateNotifier<bool> {
  TypingNotifier() : super(false); // 초기 상태: false (입력 중 아님)

  void setTyping(bool value) {
    state = value;
  }
}