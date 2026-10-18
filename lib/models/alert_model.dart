class AlertModel {
  final int? id;
  final int userId;
  final String type; // 'new_listing', 'price_drop', 'saved_search_update'
  final String message;
  final String timestamp;
  final bool isRead;

  AlertModel({
    this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      message: map['message'] as String,
      timestamp: map['timestamp'] as String,
      isRead: (map['is_read'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type,
      'message': message,
      'timestamp': timestamp,
      'is_read': isRead ? 1 : 0,
    };
  }

  AlertModel copyWith({
    int? id,
    int? userId,
    String? type,
    String? message,
    String? timestamp,
    bool? isRead,
  }) {
    return AlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  String get title {
    switch (type.toLowerCase()) {
      case 'price_drop':
        return 'Price Drop Alert';
      case 'new_listing':
        return 'New Listing Alert';
      case 'saved_search_update':
        return 'Search Update';
      default:
        return 'Watch Alert';
    }
  }
}
