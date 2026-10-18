import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../prefs/pref_manager.dart';
import '../../controllers/alert_controller.dart';
import '../../models/alert_model.dart';
import '../../models/message_model.dart';

class SocketService extends GetxService {
  static SocketService get to => Get.find<SocketService>();
  final PrefManager _pref = Get.find<PrefManager>();

  IO.Socket? _socket;
  final RxBool isConnected = false.obs;

  // Real-time Event Callbacks
  Function(MessageModel message)? onMessageReceived;
  Function(String chatId, bool isTyping)? onTypingStatusChanged;
  Function(String messageId, String chatId)? onMessageSeen;

  @override
  void onInit() {
    super.onInit();
    debugPrint("🔌 [SOCKET SERVICE] Initializing SocketService...");
    if (_pref.hasToken) {
      connect();
    }
  }

  void connect() {
    final token = _pref.accessToken;
    if (token == null || token.isEmpty) {
      debugPrint("⚠️ [SOCKET] Cannot connect: No access token available in PrefManager.");
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint("ℹ️ [SOCKET] Socket is already connected.");
      return;
    }

    final rawBaseUrl = _pref.apiBaseUrl;
    // Strip trailing /api/v1 and slashes if present for root websocket endpoint
    final socketUrl = rawBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '').replaceAll(RegExp(r'/+$'), '');
    debugPrint("🔌 [SOCKET] Connecting to live Socket.io server at: $socketUrl");

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(5000)
          .setReconnectionAttempts(3)
          .setAuth({'token': 'Bearer $token'})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      isConnected.value = true;
      debugPrint("✅ [SOCKET] Handshake authenticated & connected successfully! Socket ID: ${_socket?.id}");
    });

    _socket!.onDisconnect((reason) {
      isConnected.value = false;
      debugPrint("⚠️ [SOCKET] Disconnected from backend socket server. Reason: $reason");
    });

    _socket!.onConnectError((err) {
      isConnected.value = false;
      debugPrint("ℹ️ [SOCKET] Real-time gateway status: $err (REST fallback active)");
    });

    // 1. Message reception
    _socket!.on('receive_message', (data) {
      debugPrint("💬 [SOCKET] 'receive_message' event payload: $data");
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final currentUserId = _pref.activeUserBackendId ?? _pref.activeUserId?.toString();
        final msg = MessageModel.fromMap(map, currentUserId: currentUserId);
        onMessageReceived?.call(msg);
      }
    });

    _socket!.on('support-message:new', (data) {
      debugPrint("💬 [SOCKET] 'support-message:new' event payload: $data");
      if (data is Map && data['data'] is Map) {
        final map = Map<String, dynamic>.from(data['data'] as Map);
        final currentUserId = _pref.activeUserBackendId ?? _pref.activeUserId?.toString();
        final msg = MessageModel.fromMap(map, currentUserId: currentUserId);
        onMessageReceived?.call(msg);
      }
    });

    // 2. Typing status
    _socket!.on('typing', (data) {
      if (data is Map && data['chatId'] != null) {
        onTypingStatusChanged?.call(data['chatId'].toString(), true);
      }
    });

    _socket!.on('stop_typing', (data) {
      if (data is Map && data['chatId'] != null) {
        onTypingStatusChanged?.call(data['chatId'].toString(), false);
      }
    });

    // 3. Message seen
    _socket!.on('message_seen', (data) {
      if (data is Map) {
        final mId = (data['messageId'] ?? '').toString();
        final cId = (data['chatId'] ?? '').toString();
        onMessageSeen?.call(mId, cId);
      }
    });

    // 4. Real-time Notifications & Alerts
    _socket!.on('new_notification', (data) {
      debugPrint("🔔 [SOCKET] 'new_notification' received: $data");
      _handleIncomingNotification(data);
    });

    _socket!.on('notification:new', (data) {
      debugPrint("🔔 [SOCKET] 'notification:new' received: $data");
      _handleIncomingNotification(data);
    });

    _socket!.on('unread-count:updated', (data) {
      debugPrint("🔔 [SOCKET] 'unread-count:updated' received: $data");
      if (data is Map && data['data'] is Map && data['data']['count'] != null) {
        try {
          final count = data['data']['count'] as int;
          Get.find<AlertController>().unreadCount.value = count;
        } catch (_) {}
      }
    });

    _socket!.connect();
  }

  void _handleIncomingNotification(dynamic data) {
    try {
      final alertCtrl = Get.find<AlertController>();
      Map<String, dynamic> alertMap = {};
      if (data is Map && data.containsKey('data') && data['data'] is Map) {
        alertMap = Map<String, dynamic>.from(data['data'] as Map);
      } else if (data is Map) {
        alertMap = Map<String, dynamic>.from(data);
      }

      final newAlert = AlertModel(
        id: alertMap['id'] is int ? alertMap['id'] as int : DateTime.now().millisecondsSinceEpoch,
        userId: _pref.activeUserId ?? 1,
        type: (alertMap['type'] ?? 'system_alert').toString(),
        message: (alertMap['message'] ?? alertMap['title'] ?? 'New notification received').toString(),
        timestamp: (alertMap['createdAt'] ?? alertMap['timestamp'] ?? DateTime.now().toIso8601String()).toString(),
        isRead: false,
      );

      alertCtrl.onNewAlertReceived(newAlert);
    } catch (e) {
      debugPrint("Error handling incoming socket notification: $e");
    }
  }

  // Socket Actions
  void joinChat(String chatId) {
    if (_socket != null && _socket!.connected) {
      debugPrint("💬 [SOCKET] Emitting 'join_chat' -> $chatId");
      _socket!.emit('join_chat', chatId);
    }
  }

  void sendMessage({
    required String chatId,
    required String content,
    String messageType = 'text',
    String? fileUrl,
    Function(bool success, dynamic data)? ack,
  }) {
    if (_socket != null && _socket!.connected) {
      final payload = {
        'chatId': chatId,
        'content': content,
        'messageType': messageType,
        if (fileUrl != null) 'fileUrl': fileUrl,
      };
      debugPrint("💬 [SOCKET] Emitting 'send_message' -> $payload");
      _socket!.emitWithAck('send_message', payload, ack: (response) {
        debugPrint("💬 [SOCKET] 'send_message' ACK received: $response");
        if (response is Map) {
          final success = response['success'] == true;
          ack?.call(success, response['data']);
        } else {
          ack?.call(true, response);
        }
      });
    } else {
      debugPrint("⚠️ [SOCKET] Socket not connected. Passing to fallback.");
      ack?.call(false, null);
    }
  }

  void emitTyping(String chatId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing', {'chatId': chatId});
    }
  }

  void emitStopTyping(String chatId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('stop_typing', {'chatId': chatId});
    }
  }

  void markSeen({required String messageId, required String chatId}) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_seen', {'messageId': messageId, 'chatId': chatId});
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      isConnected.value = false;
      debugPrint("🔌 [SOCKET] Disconnected and disposed socket instance.");
    }
  }
}
