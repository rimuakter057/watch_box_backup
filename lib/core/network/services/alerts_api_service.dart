import '../api_client.dart';
import '../api_endpoints.dart';

class AlertsApiService {
  final ApiClient _api = ApiClient.to;

  Future<List<Map<String, dynamic>>?> getNotifications() async {
    final res = await _api.safeGet(ApiEndpoints.notifications);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final list = body['data']?['items'] ?? body['data'] ?? body['items'];
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return null;
  }

  Future<int> getUnreadCount() async {
    final res = await _api.safeGet(ApiEndpoints.notificationsUnreadCount);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return (body['data']?['count'] ?? body['count'] ?? 0) as int;
    }
    return 0;
  }

  Future<bool> markAsRead(String id) async {
    final res = await _api.safePost('${ApiEndpoints.notifications}/$id/read', {});
    return res.isOk;
  }

  Future<bool> markAllAsRead() async {
    final res = await _api.safePost('${ApiEndpoints.notifications}/read-all', {});
    return res.isOk;
  }

  Future<bool> deleteNotification(String id) async {
    final res = await _api.safeDelete('${ApiEndpoints.notifications}/$id');
    return res.isOk;
  }
}