import '../api_client.dart';
import '../api_endpoints.dart';
import '../../../models/watch_model.dart';

class ListingsApiService {
  final ApiClient _api = ApiClient.to;

  Future<List<WatchModel>?> getListings({int page = 1, int limit = 20, String? sort}) async {
    final res = await _api.safeGet(ApiEndpoints.listings, query: {
      'page': page,
      'limit': limit,
      ...?sort != null ? {'sort': sort} : null,
    });
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final list = body['data']?['items'] ?? body['data'] ?? body['items'];
      if (list is List) {
        return list.map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<List<WatchModel>?> getTraderCollections() async {
    final res = await _api.safeGet(ApiEndpoints.traderCollection);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final list = body['data']?['items'] ?? body['data'] ?? body['items'];
      if (list is List) {
        return list.map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<List<WatchModel>?> getMyListings({String status = 'active'}) async {
    final res = await _api.safeGet(ApiEndpoints.myListings, query: {'status': status});
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final list = body['data']?['items'] ?? body['data'] ?? body['items'];
      if (list is List) {
        return list.map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<WatchModel?> getListingDetails(String listingId) async {
    final res = await _api.safeGet('${ApiEndpoints.listings}/$listingId');
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'] ?? body;
      if (data is Map) {
        return WatchModel.fromMap(Map<String, dynamic>.from(data));
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> createListing(Map<String, dynamic> listingData) async {
    final res = await _api.safePost(ApiEndpoints.listings, listingData);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : null;
    }
    return null;
  }

  Future<bool> markListingSold(String listingId) async {
    final res = await _api.safePost('${ApiEndpoints.listings}/$listingId/mark-sold', {});
    return res.isOk;
  }
}