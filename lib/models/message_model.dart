import 'package:photo_manager/photo_manager.dart';

class MessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool isSeen;
  final List<AssetEntity>? images; // 선택된 이미지 미리보기용

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isSeen = false,
    this.images,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isMe: json['isMe'] as bool,
      isSeen: json['isSeen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isMe': isMe,
    'isSeen': isSeen,
  };

  MessageModel copyWith({
    bool? isSeen,
    List<AssetEntity>? images,
  }) {
    return MessageModel(
      senderId: senderId,
      text: text,
      timestamp: timestamp,
      isMe: isMe,
      isSeen: isSeen ?? this.isSeen,
      images: images ?? this.images,
    );
  }
}