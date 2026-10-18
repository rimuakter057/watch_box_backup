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
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMarketInsights() async {
    var res = await _api.safeGet(ApiEndpoints.analyticsMarketInsights);
    if (!res.isOk || res.body == null || (res.body is Map && (res.body['data'] == null || (res.body['data'] is List && (res.body['data'] as List).isEmpty)))) {
      res = await _api.safeGet('/marketplaces/ebay/market-insights');
    }
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is List && data.isNotEmpty && data.first is Map) return Map<String, dynamic>.from(data.first);
      if (body is Map<String, dynamic> && (body.containsKey('marketAveragePrice') || body.containsKey('items'))) return body;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProfileAnalytics() async {
    var res = await _api.safeGet(ApiEndpoints.userProfileAnalytics);
    if (!res.isOk) {
      res = await _api.safeGet('/users/me/stats');
    }
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : (body is Map<String, dynamic> ? body : null);
    }
    return null;
  }

  Future<List<double>?> getWatchPriceTrend(String modelId) async {
    final res = await _api.safeGet('${ApiEndpoints.analyticsPriceTrend}/$modelId/price-trend');
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final list = body['data']?['trend'] ?? body['data'] ?? body['trend'];
      if (list is List) {
        return list.map((e) => (e is num) ? e.toDouble() : (double.tryParse(e.toString()) ?? 0.0)).toList();
      }
    }
    return null;
  }
}