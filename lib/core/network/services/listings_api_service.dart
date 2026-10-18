import '../api_client.dart';
import '../api_endpoints.dart';
import '../../../models/watch_model.dart';

class ListingsApiService {
  final ApiClient _api = ApiClient.to;

  Future<List<WatchModel>?> getListings({int page = 1, int limit = 20, String? sort}) async {
    // 1. Try /posts/get-all-posts
    var res = await _api.safeGet(ApiEndpoints.postsGetAll, query: {
      'page': page,
      'limit': limit,
      ...?sort != null ? {'sort': sort} : null,
    });
    // 2. Fallback to /listings
    if (!res.isOk) {
      res = await _api.safeGet(ApiEndpoints.listings, query: {
        'page': page,
        'limit': limit,
        ...?sort != null ? {'sort': sort} : null,
      });
    }

    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<List<WatchModel>?> getTraderCollections() async {
    final res = await _api.safeGet(ApiEndpoints.traderCollection);
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<List<WatchModel>?> getMyListings({String status = 'active'}) async {
    // 1. Try /posts/my-posts
    var res = await _api.safeGet(ApiEndpoints.postsMy, query: {'status': status});
    // 2. Fallback to /me/listings
    if (!res.isOk) {
      res = await _api.safeGet(ApiEndpoints.myListings, query: {'status': status});
    }

    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<WatchModel?> getListingDetails(String listingId) async {
    // 1. Try /posts/view-post/:id
    var res = await _api.safeGet('${ApiEndpoints.postsView}/$listingId');
    // 2. Fallback to /listings/:id
    if (!res.isOk) {
      res = await _api.safeGet('${ApiEndpoints.listings}/$listingId');
    }

    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'] ?? body;
      if (data is Map) {
        return WatchModel.fromMap(Map<String, dynamic>.from(data));
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> createListing(Map<String, dynamic> listingData, {List<int>? imageBytes, String? filename}) async {
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final fields = listingData.map((k, v) => MapEntry(k, v.toString()));
      var res = await _api.safeUpload(ApiEndpoints.postsCreate, imageBytes, filename ?? 'watch.jpg', fields: fields);
      if (!res.isOk) {
        res = await _api.safeUpload(ApiEndpoints.listings, imageBytes, filename ?? 'watch.jpg', fields: fields);
      }
      if (res.isOk && res.body != null) {
        final body = res.body is Map ? res.body : {};
        return body['data'] is Map<String, dynamic> ? body['data'] : null;
      }
    }

    var res = await _api.safePost(ApiEndpoints.postsCreate, listingData);
    if (!res.isOk) {
      res = await _api.safePost(ApiEndpoints.listings, listingData);
    }
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : null;
    }
    return null;
  }

  Future<bool> deleteListing(String listingId) async {
    var res = await _api.safeDelete('${ApiEndpoints.postsDelete}/$listingId');
    if (!res.isOk) {
      res = await _api.safeDelete('${ApiEndpoints.listings}/$listingId');
    }
    return res.isOk;
  }

  Future<bool> markListingSold(String listingId) async {
    var res = await _api.safePost('${ApiEndpoints.listings}/$listingId/mark-sold', {});
    if (!res.isOk) {
      res = await _api.safePatch('${ApiEndpoints.listings}/$listingId', {'status': 'sold', 'is_sold': 1});
    }
    return res.isOk;
  }

  Future<bool> toggleSave(String listingId) async {
    var res = await _api.safePost('${ApiEndpoints.postsToggleSave}/$listingId', {});
    if (!res.isOk) {
      res = await _api.safePost('${ApiEndpoints.listings}/$listingId/save', {});
    }
    return res.isOk;
  }

  Future<List<WatchModel>?> getSavedPosts() async {
    var res = await _api.safeGet(ApiEndpoints.postsSaved);
    if (!res.isOk) {
      res = await _api.safeGet(ApiEndpoints.savedListings);
    }
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<bool> purchaseListing(String listingId, {double? price, String? buyerName}) async {
    var res = await _api.safePost('/orders', {
      'listingId': listingId,
      if (price != null) 'amount': price,
      if (buyerName != null) 'buyerName': buyerName,
    });
    if (!res.isOk) {
      res = await _api.safePost('/purchases', {
        'listingId': listingId,
        if (price != null) 'price': price,
      });
    }
    return res.isOk;
  }

  Future<Map<String, dynamic>?> getInvoice(String listingId) async {
    final res = await _api.safeGet('/subscriptions/invoices', query: {'listingId': listingId});
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'];
      if (data is List && data.isNotEmpty) return Map<String, dynamic>.from(data.first);
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    return null;
  }
}