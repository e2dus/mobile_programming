class ChatModel {
  final String chatId;
  final String userId;
  final String username;
  final String profileImageUrl;
  final DateTime? lastMessageTime;
  final bool hasUnreadMessage;

  ChatModel({
    required this.chatId,
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    this.lastMessageTime,
    this.hasUnreadMessage = false,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    DateTime? _parseTime(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) { return null; }
      }
      return null;
    }
    return ChatModel(
      chatId: json['chatId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      lastMessageTime: _parseTime(json['lastMessageTime']),
      hasUnreadMessage: json['hasUnreadMessage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'userId': userId,
    'username': username,
    'profileImageUrl': profileImageUrl,
    'lastMessageTime': lastMessageTime?.toIso8601String(),
    'hasUnreadMessage': hasUnreadMessage,
  };

  ChatModel copyWith({
    bool? hasUnreadMessage,
    DateTime? lastMessageTime,
  }) {
    return ChatModel(
      chatId: chatId,
      userId: userId,
      username: username,
      profileImageUrl: profileImageUrl,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      hasUnreadMessage: hasUnreadMessage ?? this.hasUnreadMessage,
    );
  }
}