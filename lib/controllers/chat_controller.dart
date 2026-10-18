import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/prefs/pref_manager.dart';
import '../core/network/socket_service.dart';
import '../core/network/services/chat_api_service.dart';
import '../models/message_model.dart';
import 'auth_controller.dart';

class ChatController extends GetxController {
  final PrefManager _pref = Get.find<PrefManager>();
  final AuthController _auth = Get.find<AuthController>();

  ChatApiService get _chatApi {
    try {
      return Get.find<ChatApiService>();
    } catch (_) {
      return ChatApiService();
    }
  }

  SocketService get _socket {
    try {
      return SocketService.to;
    } catch (_) {
      return Get.find<SocketService>();
    }
  }

  final RxList<ChatModel> chatRooms = <ChatModel>[].obs;
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoadingChats = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isOtherTyping = false.obs;
  final RxString activeChatId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint("💬 [CHAT CONTROLLER] Initializing ChatController...");

    // 1. Wire Socket.io real-time event hooks
    _setupSocketListeners();

    // 2. Load conversations when auth is ready
    ever(_auth.currentUser, (user) {
      if (user != null) {
        loadChats();
        if (!_socket.isConnected.value && _pref.hasToken) {
          _socket.connect();
        }
      } else {
        chatRooms.clear();
        messages.clear();
        activeChatId.value = '';
      }
    });

    if (_auth.currentUser.value != null) {
      loadChats();
    }
  }

  void _setupSocketListeners() {
    _socket.onMessageReceived = (MessageModel message) {
      debugPrint("💬 [CHAT CONTROLLER] Socket incoming message: ${message.content} (ChatId: ${message.chatId})");
      if (message.chatId == activeChatId.value) {
        // Append message instantaneously to RxList without full-screen rebuild
        final exists = messages.any((m) => m.id == message.id);
        if (!exists) {
          messages.add(message);
        }
      }
      _updateChatRoomPreview(message);
    };

    _socket.onTypingStatusChanged = (String chatId, bool isTyping) {
      if (chatId == activeChatId.value) {
        isOtherTyping.value = isTyping;
      }
    };

    _socket.onMessageSeen = (String messageId, String chatId) {
      if (chatId == activeChatId.value) {
        final idx = messages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          messages[idx] = messages[idx].copyWith(isSeen: true);
        }
      }
    };
  }

  void _updateChatRoomPreview(MessageModel message) {
    final idx = chatRooms.indexWhere((c) => c.id == message.chatId);
    if (idx != -1) {
      final old = chatRooms[idx];
      chatRooms[idx] = ChatModel(
        id: old.id,
        name: old.name,
        avatarUrl: old.avatarUrl,
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        unreadCount: message.chatId == activeChatId.value ? 0 : old.unreadCount + 1,
        listingId: old.listingId,
        watchTitle: old.watchTitle,
      );
    }
  }

  // Fetch all chat rooms
  Future<void> loadChats() async {
    if (!_pref.hasToken) {
      debugPrint("❌ [CHAT ERROR] Cannot load chats: User not authorized (no access token). No fallback.");
      chatRooms.clear();
      return;
    }

    isLoadingChats.value = true;
    try {
      final rooms = await _chatApi.getChats();
      if (rooms != null) {
        chatRooms.assignAll(rooms);
        debugPrint("✅ [CHAT CONTROLLER] Loaded ${rooms.length} chat rooms from backend.");
      } else {
        debugPrint("❌ [CHAT ERROR] Chats API returned null / not authorized. No fallback.");
      }
    } catch (e) {
      debugPrint("❌ [CHAT CONTROLLER] Error loading chats: $e. No fallback.");
    } finally {
      isLoadingChats.value = false;
    }
  }

  // Open conversation room
  Future<void> openChat(String chatId, {String? recipientId, String? listingId, String? watchTitle}) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [CHAT ERROR] Cannot open chat $chatId: User not authorized (no access token). No fallback.");
      return;
    }

    activeChatId.value = chatId;
    messages.clear();
    isOtherTyping.value = false;

    // 1. Join room on Socket.io
    _socket.joinChat(chatId);

    // 2. Fetch paginated message history via REST API
    isLoadingMessages.value = true;
    try {
      final currentUserId = _pref.activeUserBackendId ?? _pref.activeUserId?.toString();
      final history = await _chatApi.getMessages(chatId, currentUserId: currentUserId);
      if (history != null) {
        messages.assignAll(history);
        debugPrint("✅ [CHAT CONTROLLER] Loaded ${history.length} messages for chat $chatId.");
      } else {
        debugPrint("❌ [CHAT ERROR] Messages API returned null / not authorized for $chatId. No fallback.");
      }
    } catch (e) {
      debugPrint("❌ [CHAT CONTROLLER] Error fetching messages for $chatId: $e. No fallback.");
    } finally {
      isLoadingMessages.value = false;
    }
  }

  // Contact seller from Watch Detail Screen
  Future<String?> startConversationWithSeller({required String recipientId, String? listingId, String? watchTitle}) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [CHAT ERROR] Cannot contact seller: User not authorized (no access token). No fallback.");
      Get.snackbar("Authentication Required", "Please sign in to contact sellers.");
      return null;
    }

    isLoadingChats.value = true;
    try {
      final chat = await _chatApi.createOrGetChat(
        recipientId: recipientId,
        listingId: listingId,
        initialMessage: "Hi, I am interested in your $watchTitle listing on The Watch Box.",
      );
      if (chat != null) {
        final existingIdx = chatRooms.indexWhere((c) => c.id == chat.id);
        if (existingIdx == -1) {
          chatRooms.insert(0, chat);
        }
        await openChat(chat.id, recipientId: recipientId, listingId: listingId, watchTitle: watchTitle);
        return chat.id;
      } else {
        debugPrint("❌ [CHAT ERROR] Failed to create or get chat from backend / not authorized. No fallback.");
      }
    } catch (e) {
      debugPrint("❌ [CHAT CONTROLLER] Error starting conversation: $e. No fallback.");
    } finally {
      isLoadingChats.value = false;
    }
    return null;
  }

  // Send message
  Future<bool> sendMessage(String content, {String messageType = 'text', String? fileUrl}) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [CHAT ERROR] Cannot send message: User not authorized (no access token). No fallback.");
      return false;
    }

    final chatId = activeChatId.value;
    if (chatId.isEmpty || content.trim().isEmpty) return false;

    final currentUserId = _pref.activeUserBackendId ?? _pref.activeUserId?.toString() ?? 'me';
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    // Optimistic local update
    final optimisticMsg = MessageModel(
      id: tempId,
      chatId: chatId,
      senderId: currentUserId,
      content: content.trim(),
      messageType: messageType,
      fileUrl: fileUrl,
      timestamp: DateTime.now().toIso8601String(),
      isSeen: false,
      isMine: true,
    );
    messages.add(optimisticMsg);
    _updateChatRoomPreview(optimisticMsg);

    // 1. Emit send_message through socket
    bool socketHandled = false;
    _socket.sendMessage(
      chatId: chatId,
      content: content.trim(),
      messageType: messageType,
      fileUrl: fileUrl,
      ack: (success, data) {
        if (success && data is Map) {
          socketHandled = true;
          final serverMsg = MessageModel.fromMap(Map<String, dynamic>.from(data), currentUserId: currentUserId);
          final idx = messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            messages[idx] = serverMsg.copyWith(isMine: true);
          }
        }
      },
    );

    // 2. HTTP Fallback if socket fails or offline
    await Future.delayed(const Duration(milliseconds: 300));
    if (!socketHandled) {
      try {
        final serverMsg = await _chatApi.sendMessageHttp(
          chatId: chatId,
          content: content.trim(),
          messageType: messageType,
          fileUrl: fileUrl,
          currentUserId: currentUserId,
        );
        if (serverMsg != null) {
          final idx = messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            messages[idx] = serverMsg.copyWith(isMine: true);
          }
        }
      } catch (e) {
        debugPrint("HTTP send message error: $e");
      }
    }

    sendStopTyping();
    return true;
  }

  void sendTyping() {
    if (activeChatId.value.isNotEmpty) {
      _socket.emitTyping(activeChatId.value);
    }
  }

  void sendStopTyping() {
    if (activeChatId.value.isNotEmpty) {
      _socket.emitStopTyping(activeChatId.value);
    }
  }

  void markMessageSeen(String messageId) {
    if (activeChatId.value.isNotEmpty) {
      _socket.markSeen(messageId: messageId, chatId: activeChatId.value);
    }
  }
}
