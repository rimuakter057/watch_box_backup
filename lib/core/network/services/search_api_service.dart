import '../api_client.dart';
import '../api_endpoints.dart';
import '../../../models/watch_model.dart';

class SearchApiService {
  final ApiClient _api = ApiClient.to;

  Future<List<WatchModel>?> search({
    required String query,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? yearMin,
    int? yearMax,
    List<String>? platforms,
    String? sort,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> params = {
      'q': query,
      'page': page,
      'limit': limit,
    };
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (yearMin != null) params['yearMin'] = yearMin;
    if (yearMax != null) params['yearMax'] = yearMax;
    if (platforms != null && platforms.isNotEmpty) params['platforms'] = platforms.join(',');
    if (sort != null) params['sort'] = sort;

    final res = await _api.safeGet(ApiEndpoints.search, query: params);
    if (res.isOk && res.body != null) {
      final listData = ApiClient.extractList(res.body);
      if (listData != null && listData.isNotEmpty) {
        return listData.whereType<Map>().map((item) => WatchModel.fromMap(Map<String, dynamic>.from(item))).toList();
      }

      // Check if data is a Map with marketplace items (ebay / localStore)
      if (res.body is Map && res.body['data'] is Map) {
        final data = res.body['data'] as Map;
        final List<dynamic> combined = [];
        if (data['ebay'] is Map && data['ebay']['items'] is List) {
          combined.addAll(data['ebay']['items']);
        }
        if (data['localStore'] is Map && data['localStore']['items'] is List) {
          combined.addAll(data['localStore']['items']);
        }
        if (combined.isNotEmpty) {
          return combined.whereType<Map>().map((item) => WatchModel.fromMap(Map<String, dynamic>.from(item))).toList();
        }
      }
    }

    // Fallback to /marketplaces/search if /search returned 0 results
    try {
      final fallbackRes = await _api.safeGet('/marketplaces/search', query: params);
      if (fallbackRes.isOk && fallbackRes.body != null) {
        if (fallbackRes.body is Map && fallbackRes.body['data'] is Map) {
          final data = fallbackRes.body['data'] as Map;
          final List<dynamic> combined = [];
          if (data['ebay'] is Map && data['ebay']['items'] is List) {
            combined.addAll(data['ebay']['items']);
          }
          if (data['localStore'] is Map && data['localStore']['items'] is List) {
            combined.addAll(data['localStore']['items']);
          }
          if (combined.isNotEmpty) {
            return combined.whereType<Map>().map((item) => WatchModel.fromMap(Map<String, dynamic>.from(item))).toList();
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<List<String>> getSuggestions(String query) async {
    final res = await _api.safeGet(ApiEndpoints.searchSuggestions, query: {'q': query});
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final list = body['data'] ?? body['suggestions'];
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  Future<List<String>> getPopularSearches() async {
    final res = await _api.safeGet(ApiEndpoints.searchPopular);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final list = body['data'] ?? body['popular'];
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  Future<Map<String, dynamic>?> getSearchQuotaUsage() async {
    final res = await _api.safeGet(ApiEndpoints.subscriptionUsage);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : null;
    }
    return null;
  }
}