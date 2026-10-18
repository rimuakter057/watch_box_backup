import '../api_client.dart';
import '../api_endpoints.dart';

class AlertsApiService {
  final ApiClient _api = ApiClient.to;

  Future<List<Map<String, dynamic>>?> getNotifications() async {
    final res = await _api.safeGet(ApiEndpoints.notifications);
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return null;
  }

  Future<int> getUnreadCount() async {
    final res = await _api.safeGet(ApiEndpoints.notificationsUnreadCount);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      if (body['data'] is Map && body['data']['count'] != null) {
        return body['data']['count'] is int ? body['data']['count'] as int : int.tryParse(body['data']['count'].toString()) ?? 0;
      } else if (body['count'] != null) {
        return body['count'] is int ? body['count'] as int : int.tryParse(body['count'].toString()) ?? 0;
      }
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