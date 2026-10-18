import '../api_client.dart';
import '../api_endpoints.dart';
import '../../../models/message_model.dart';

class ChatApiService {
  final ApiClient _api = ApiClient.to;

  Future<List<ChatModel>?> getChats() async {
    final res = await _api.safeGet(ApiEndpoints.chats);
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => ChatModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<ChatModel?> createOrGetChat({String? recipientId, String? listingId, String? initialMessage}) async {
    final res = await _api.safePost(ApiEndpoints.chats, {
      'subject': listingId != null ? 'Inquiry on listing #$listingId' : 'Direct Conversation',
      if (initialMessage != null) 'message': initialMessage,
      if (recipientId != null) 'recipientId': recipientId,
      if (listingId != null) 'listingId': listingId,
    });

    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'] ?? body;
      if (data is Map) return ChatModel.fromMap(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<MessageModel>?> getMessages(String chatId, {int page = 1, int limit = 50, String? currentUserId}) async {
    final res = await _api.safeGet('${ApiEndpoints.messages}/$chatId/messages', query: {'page': page, 'limit': limit});
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
      'content': content,
      'messageType': messageType,
      if (fileUrl != null) 'fileUrl': fileUrl,
    };

    final res = await _api.safePost('${ApiEndpoints.messages}/$chatId/messages', payload);
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
