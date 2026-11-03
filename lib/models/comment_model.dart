class CommentModel {
  final int id;
  final String postId;
  final String username;
  final String content;
  final DateTime time;
  final int heartCount;
  final bool myHeart;
  final int? reply;
  // 로컬에서만 사용하는 임시 상태: 서버 전송 중인 댓글 여부
  final bool pending;

  CommentModel({
    required this.id,
    required this.postId,
    required this.username,
    required this.content,
    required this.time,
    required this.heartCount,
    required this.myHeart,
    this.reply,
    this.pending = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    bool _asBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1' || s == 't' || s == 'yes';
      }
      return false;
    }

    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    final dynamic timeVal = json['time'];
    DateTime parsedTime;
    if (timeVal is String) {
      parsedTime = DateTime.tryParse(timeVal) ?? DateTime.now();
    } else if (timeVal is DateTime) {
      parsedTime = timeVal;
    } else {
      parsedTime = DateTime.now();
    }

    return CommentModel(
      id: (json['id'] as int?) ?? 0,
      // accept both 'post_id' and 'post_Id' just in case
      postId: (json['post_id'] ?? json['post_Id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      time: parsedTime,
  heartCount: _asInt(json['heart_count']),
  myHeart: _asBool(json['my_heart']),
      reply: json['reply'] as int?,
      pending: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'username': username,
    'content': content,
    'time': time.toIso8601String(),
    'heart_count': heartCount,
    'my_heart': myHeart,
    'reply': reply,
    // 'pending'는 서버에 저장하지 않습니다
  };

  CommentModel copyWith({
    int? id,
    String? postId,
    String? username,
    String? content,
    DateTime? time,
    int? heartCount,
    bool? myHeart,
    int? reply,
    bool? pending,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      username: username ?? this.username,
      content: content ?? this.content,
      time: time ?? this.time,
      heartCount: heartCount ?? this.heartCount,
      myHeart: myHeart ?? this.myHeart,
      reply: reply ?? this.reply,
      pending: pending ?? this.pending,
    );
  }
}
