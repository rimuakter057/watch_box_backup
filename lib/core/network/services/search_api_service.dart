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
      final body = res.body is Map ? res.body : {};
      final listData = body['data']?['items'] ?? body['data'] ?? body['items'];
      if (listData is List) {
        return listData.map((item) => WatchModel.fromMap(Map<String, dynamic>.from(item))).toList();
      }
    }
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
    return ["Rolex Submariner", "Patek Philippe Nautilus", "Omega Speedmaster", "Audemars Piguet Royal Oak"];
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