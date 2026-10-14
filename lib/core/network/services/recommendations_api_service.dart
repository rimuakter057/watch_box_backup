import '../api_client.dart';
import '../api_endpoints.dart';
import '../../../models/watch_model.dart';

class RecommendationsApiService {
  final ApiClient _api = ApiClient.to;

  Future<Map<String, dynamic>?> getHomeRecommendations() async {
    final res = await _api.safeGet(ApiEndpoints.recommendationsHome);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : null;
    }
    return null;
  }

  Future<List<WatchModel>?> getForYou() async {
    final res = await _api.safeGet(ApiEndpoints.recommendationsForYou);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final list = body['data']?['items'] ?? body['data'] ?? body['items'];
      if (list is List) {
        return list.map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMarketInsights() async {
    final res = await _api.safeGet(ApiEndpoints.analyticsMarketInsights);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : null;
    }
    return null;
  }
}