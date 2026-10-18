class ChatModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final String? listingId;
  final String? watchTitle;

  ChatModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.listingId,
    this.watchTitle,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    String lastMsg = '';
    if (map['lastMessage'] != null) {
      lastMsg = map['lastMessage'].toString();
    } else if (map['latestMessage'] is Map) {
      final latest = map['latestMessage'] as Map;
      lastMsg = (latest['content'] ?? latest['message'] ?? '').toString();
    } else if (map['latestMessage'] != null) {
      lastMsg = map['latestMessage'].toString();
    } else if (map['message'] != null) {
      lastMsg = map['message'].toString();
    } else if (map['subject'] != null) {
      lastMsg = map['subject'].toString();
    }

    int unread = 0;
    if (map['unreadCount'] is int) {
      unread = map['unreadCount'] as int;
    } else if (map['unreadCount'] != null) {
      unread = int.tryParse(map['unreadCount'].toString()) ?? 0;
    }

    return ChatModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      name: (map['name'] ?? map['userName'] ?? map['recipientName'] ?? map['subject'] ?? 'Dealer / Trader').toString(),
      avatarUrl: map['avatarUrl']?.toString(),
      lastMessage: lastMsg,
      lastMessageTime: (map['lastMessageTime'] ?? map['updatedAt'] ?? map['createdAt'] ?? '').toString(),
      unreadCount: unread,
      listingId: map['listingId']?.toString(),
      watchTitle: (map['watchTitle'] ?? map['subject'])?.toString(),
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String messageType; // 'text', 'image', 'file'
  final String? fileUrl;
  final String timestamp;
  final bool isSeen;
  final bool isMine;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    this.fileUrl,
    required this.timestamp,
    this.isSeen = false,
    this.isMine = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    String sender = '';
    if (map['senderId'] != null) {
      sender = map['senderId'].toString();
    } else if (map['sender'] is Map) {
      sender = ((map['sender'] as Map)['id'] ?? (map['sender'] as Map)['_id'] ?? '').toString();
    } else if (map['sender'] != null) {
      sender = map['sender'].toString();
    }

    final isMine = currentUserId != null && currentUserId.isNotEmpty && sender == currentUserId;
    return MessageModel(
      id: (map['id'] ?? map['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      chatId: (map['chatId'] ?? map['ticketId'] ?? '').toString(),
      senderId: sender,
      content: (map['content'] ?? map['message'] ?? '').toString(),
      messageType: (map['messageType'] ?? 'text').toString(),
      fileUrl: (map['fileUrl'] ?? (map['attachments'] is List && (map['attachments'] as List).isNotEmpty ? (map['attachments'] as List).first : null))?.toString(),
      timestamp: (map['createdAt'] ?? map['timestamp'] ?? DateTime.now().toIso8601String()).toString(),
      isSeen: map['isSeen'] == true || map['seen'] == true,
      isMine: isMine,
    );
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? messageType,
    String? fileUrl,
    String? timestamp,
    bool? isSeen,
    bool? isMine,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
      isMine: isMine ?? this.isMine,
    );
  }
}
