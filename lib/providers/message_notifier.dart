// lib/providers/message_notifier.dart (최종 수정)

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:individual_project/models/message_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:individual_project/api_keys.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:individual_project/providers/app_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';


class MessageNotifier extends StateNotifier<List<MessageModel>> {
  final Ref ref;
  final String chatId;
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final Random _random = Random();

  MessageNotifier(this.ref, this.chatId, List<MessageModel> initialMessages) : super(initialMessages) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: GEMINI_API_KEY,
    );
    _chat = _model.startChat(history: []);
    loadMessages();
  }

  void addMessage(MessageModel message) {
    state = [...state, message];
    _saveMessages(); // 메시지가 추가될 때마다 저장
    _insertSupabaseMessage(message); // Supabase에도 반영
    _updateChatLastMessageMeta(message); // chats 테이블의 메타 갱신
  }

  // 메시지를 JSON으로 저장
  Future<void> _saveMessages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/messages_$chatId.json');
      
      final List<Map<String, dynamic>> jsonList = state.map((message) => message.toJson()).toList();
      final String jsonString = json.encode(jsonList);
      
      await file.writeAsString(jsonString);
      debugPrint('Messages saved for chat $chatId');
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  // 저장된 메시지 로드
  Future<void> loadMessages() async {
    try {
      // 1) Supabase에서 해당 채팅방 메시지 로드 (오래된 것부터)
      final client = Supabase.instance.client;
      final List<dynamic> rows = await client
          .from('messages')
          .select('senderId, text, timestamp, isMe, isSeen, chatroomId')
          .eq('chatroomId', chatId)
          .order('timestamp', ascending: true);

      if (rows.isNotEmpty) {
        final parsed = rows.map<MessageModel>((r) {
          final ts = r['timestamp'];
          final DateTime dt = ts is String
              ? DateTime.parse(ts)
              : (ts is DateTime ? ts : DateTime.now());
          return MessageModel(
            senderId: (r['senderId'] ?? '').toString(),
            text: (r['text'] ?? '').toString(),
            timestamp: dt,
            isMe: (r['isMe'] as bool?) ?? false,
            isSeen: (r['isSeen'] as bool?) ?? false,
          );
        }).toList();
        state = parsed;
        return;
      }

      // 2) Supabase가 비었으면 저장된 파일에서 로드 (로컬 캐시)
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/messages_$chatId.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        state = jsonList.map((json) => MessageModel.fromJson(json)).toList();
        debugPrint('Loaded saved messages for chat $chatId');
        return;
      }

      // 3) 초기 자산은 더 이상 사용하지 않으므로 건너뜀
      debugPrint('[MessageNotifier] No messages found in Supabase or local cache for $chatId');
    } catch (e) {
      debugPrint('Error loading messages for chat $chatId: $e');
    }
  }

  Future<void> _insertSupabaseMessage(MessageModel message) async {
    try {
      final client = Supabase.instance.client;
      await client.from('messages').insert({
        'senderId': message.senderId,
        'text': message.text,
        'timestamp': message.timestamp.toIso8601String(),
        'isMe': message.isMe,
        'isSeen': message.isSeen,
        'chatroomId': chatId,
      });
    } catch (e) {
      // 네트워크/권한 문제 시 조용히 무시하고 로컬 저장만 유지
      debugPrint('[MessageNotifier] Supabase insert failed for $chatId: $e');
    }
  }

  Future<void> _updateChatLastMessageMeta(MessageModel message) async {
    try {
      final client = Supabase.instance.client;
      await client
          .from('chats')
          .update({
            'lastMessageTime': message.timestamp.toUtc().toIso8601String(),
            'hasUnreadMessage': !(message.isSeen),
          })
          .eq('id', chatId);
      debugPrint('[MessageNotifier] chats meta updated for $chatId');

      // Update local chats list and re-order so latest chat floats to top
      try {
        ref.read(chatsProvider.notifier).updateChatMetaLocal(
          chatId: chatId,
          lastMessageTime: message.timestamp,
          hasUnreadMessage: !(message.isSeen),
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('[MessageNotifier] Failed to update chats meta for $chatId: $e');
    }
  }

  // -----------------------------------------------------------------
  // 이미지(여러 장) 전송 + Gemini 응답 받기
  // -----------------------------------------------------------------
  Future<void> sendUserImagesAndGetGeminiResponse(List<AssetEntity> assets, {String prompt = 'Please analyze these images and respond helpfully.'}) async {
    if (assets.isEmpty) return;

    // 1) 사용자 측 메시지를 UI에 즉시 반영 (이미지 미리보기 포함)
    final userMessage = MessageModel(
      senderId: 'me',
      text: '',
      timestamp: DateTime.now(),
      isMe: true,
      isSeen: false,
      images: assets,
    );
  addMessage(userMessage);

    final typingNotifier = ref.read(isTypingProvider(chatId).notifier);

    // 가벼운 읽음/생각 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 600));
    _markAllUserMessagesAsSeen();
    await Future.delayed(const Duration(milliseconds: 400));
    typingNotifier.setTyping(true);

    try {
      // 2) 자산 바이트 로드 -> 멀티 파트 컨텐츠 구성
      final List<Part> parts = <Part>[TextPart(prompt)];
      for (final asset in assets) {
        final file = await asset.file; // may be null for some cloud-only items
        if (file == null) continue;
        final Uint8List bytes = await file.readAsBytes();
        final String mime = _inferMimeFromAsset(asset);
        parts.add(DataPart(mime, bytes));
      }

      final response = await _chat.sendMessage(Content.multi(parts));
      final String? text = response.text;

      final MessageModel reply = MessageModel(
        senderId: 'gemini',
        text: text ?? '(No text response)',
        timestamp: DateTime.now(),
        isMe: false,
      );
      addMessage(reply);
    } catch (e) {
      addMessage(MessageModel(
        senderId: 'system',
        text: '이미지 분석 실패: ${e.toString()}',
        timestamp: DateTime.now(),
        isMe: false,
      ));
    } finally {
      typingNotifier.setTyping(false);
    }
  }

  String _inferMimeFromAsset(AssetEntity asset) {
    switch (asset.type) {
      case AssetType.image:
        // PhotoManager에서 확장자를 직접 주지 않으므로 일반적으로 jpeg로 처리
        return 'image/jpeg';
      case AssetType.video:
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  void _markAllUserMessagesAsSeen() {
    state = [
      for (final message in state)
        if (message.isMe && !message.isSeen)
          message.copyWith(isSeen: true)
        else
          message,
    ];

    // 최신 메시지가 읽힘 상태가 되면 chats의 hasUnreadMessage=false 로 갱신
    if (state.isNotEmpty) {
      final latest = state.last;
      _updateChatLastMessageMeta(
        latest.copyWith(isSeen: true),
      );
    }
  }

  // -----------------------------------------------------------------
  // ⭐️ Gemini API를 호출하여 응답을 받는 함수 (읽음/타이핑/응답 분리)
  // -----------------------------------------------------------------
  Future<void> sendUserMessageAndGetGeminiResponse(String text) async {
    // 1. 사용자 메시지 UI에 즉시 반영
    final userMessage = MessageModel(
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      isSeen: false,
    );
  addMessage(userMessage);

    final typingNotifier = ref.read(isTypingProvider(chatId).notifier);

    // =======================================================
    // ⭐️ STEP 1: 메시지 읽는 시간 딜레이 (1초 ~ 4초)
    // =======================================================
    final readDelayMs = 1000 + _random.nextInt(3000); // 1초 ~ 4초 랜덤
    await Future.delayed(Duration(milliseconds: readDelayMs));

    // ⭐️ 읽음 처리: 'Seen just now' 표시를 위해 상태 업데이트
    _markAllUserMessagesAsSeen();

    // =======================================================
    // ⭐️ STEP 2: 답변 생각 및 타이핑 시작 딜레이 (1초 ~ 3초)
    // =======================================================
    final thinkDelayMs = 1000 + _random.nextInt(2000); // 1초 ~ 3초 랜덤
    await Future.delayed(Duration(milliseconds: thinkDelayMs));

    // ⭐️ 타이핑 상태 시작: 화면에 '...' 표시
    typingNotifier.setTyping(true);

    // 💡 타이핑이 시작된 후 0.5초 후에 API를 호출하여 자연스러움을 더합니다.
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // =======================================================
      // ⭐️ STEP 3: Gemini 응답 요청 및 응답 메시지 추가
      // =======================================================
      final response = await _chat.sendMessage(Content.text(text));

      final geminiResponseText = response.text;

      if (geminiResponseText == null) {
        throw Exception("Gemini API가 유효한 텍스트 응답을 반환하지 않았습니다.");
      }

      final geminiResponse = MessageModel(
        senderId: 'gemini',
        text: geminiResponseText,
        timestamp: DateTime.now(),
        isMe: false,
      );
      addMessage(geminiResponse);

    } catch (e) {
      // API 호출 실패 시 에러 메시지 추가
      final errorResponse = MessageModel(
        senderId: 'system',
        text: 'API 오류: Gemini 응답을 가져오지 못했습니다. (${e.toString()})',
        timestamp: DateTime.now(),
        isMe: false,
      );
      addMessage(errorResponse);
    }finally{
      // ⭐️ 타이핑 상태 종료 (응답이 왔으므로)
      typingNotifier.setTyping(false);
    }
  }
}