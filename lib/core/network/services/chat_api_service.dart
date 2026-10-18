import '../api_client.dart';
import '../api_endpoints.dart';
import '../../../models/message_model.dart';

class ChatApiService {
  final ApiClient _api = ApiClient.to;

  Future<List<ChatModel>?> getChats() async {
    // 1. Try /chats
    var res = await _api.safeGet(ApiEndpoints.chats);
    if (!res.isOk) {
      res = await _api.safeGet('/support/tickets');
    }
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => ChatModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<ChatModel?> createOrGetChat({String? recipientId, String? listingId, String? initialMessage}) async {
    // 1. If listingId provided, try /listings/:listingId/contact-seller
    if (listingId != null && listingId.isNotEmpty) {
      final res = await _api.safePost('${ApiEndpoints.listings}/$listingId/contact-seller', {
        if (initialMessage != null) 'message': initialMessage,
        if (recipientId != null) 'recipientId': recipientId,
      });
      if (res.isOk && res.body != null) {
        final body = res.body is Map ? res.body : {};
        final data = body['data'] ?? body;
        if (data is Map) return ChatModel.fromMap(Map<String, dynamic>.from(data));
      }
    }

    // 2. Direct /chats room creation
    var res = await _api.safePost(ApiEndpoints.chats, {
      if (recipientId != null) 'recipientId': recipientId,
      if (listingId != null) 'listingId': listingId,
    });
    if (!res.isOk) {
      res = await _api.safePost('/support/tickets', {
        'subject': listingId != null ? 'Inquiry on listing #$listingId' : 'Direct Conversation',
        if (initialMessage != null) 'message': initialMessage,
      });
    }

    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'] ?? body;
      if (data is Map) return ChatModel.fromMap(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<MessageModel>?> getMessages(String chatId, {int page = 1, int limit = 50, String? currentUserId}) async {
    // 1. Try /messages/:chatId
    var res = await _api.safeGet('${ApiEndpoints.messages}/$chatId', query: {'page': page, 'limit': limit});
    if (!res.isOk) {
      res = await _api.safeGet('${ApiEndpoints.chats}/$chatId/messages', query: {'page': page, 'limit': limit});
    }
    if (!res.isOk) {
      res = await _api.safeGet('/support/tickets/$chatId/messages');
    }

    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => MessageModel.fromMap(Map<String, dynamic>.from(e), currentUserId: currentUserId)).toList();
      }
    }
    return null;
  }

  Future<MessageModel?> sendMessageHttp({
    required String chatId,
    required String content,
    String messageType = 'text',
    String? fileUrl,
    String? currentUserId,
  }) async {
    final payload = {
      'chatId': chatId,
      'content': content,
      'messageType': messageType,
      if (fileUrl != null) 'fileUrl': fileUrl,
    };

    var res = await _api.safePost(ApiEndpoints.messages, payload);
    if (!res.isOk) {
      res = await _api.safePost('${ApiEndpoints.chats}/$chatId/messages', payload);
    }
    if (!res.isOk) {
      res = await _api.safePost('/support/tickets/$chatId/messages', {'content': content});
    }

    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'] ?? body;
      if (data is Map) {
        return MessageModel.fromMap(Map<String, dynamic>.from(data), currentUserId: currentUserId);
      }
    }
    return null;
  }
}
