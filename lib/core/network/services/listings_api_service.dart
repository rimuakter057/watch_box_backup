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
    // 1. Try dedicated path (/me/listings/active or /me/listings/sold)
    final specificPath = status == 'sold' ? '${ApiEndpoints.myListings}/sold' : '${ApiEndpoints.myListings}/active';
    var res = await _api.safeGet(specificPath);
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null && list.isNotEmpty) {
        return list.whereType<Map>().map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }

    // 2. Query /me/listings with status filter
    res = await _api.safeGet(ApiEndpoints.myListings, query: {'status': status});
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null && list.isNotEmpty) {
        return list.whereType<Map>().map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }

    // 3. Fallback to /listings?status=...
    res = await _api.safeGet(ApiEndpoints.listings, query: {'status': status});
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
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

  Future<Map<String, dynamic>?> createListing(Map<String, dynamic> listingData, {List<int>? imageBytes, String? filename}) async {
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final fields = listingData.map((k, v) => MapEntry(k, v.toString()));
      final res = await _api.safeUpload(ApiEndpoints.listings, imageBytes, filename ?? 'watch.jpg', fields: fields);
      if (res.isOk && res.body != null) {
        final body = res.body is Map ? res.body : {};
        return body['data'] is Map<String, dynamic> ? body['data'] : null;
      }
      return null;
    }

    final res = await _api.safePost(ApiEndpoints.listings, listingData);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : null;
    }
    return null;
  }

  Future<bool> deleteListing(String listingId) async {
    final res = await _api.safeDelete('${ApiEndpoints.listings}/$listingId');
    return res.isOk;
  }

  Future<bool> markListingSold(String listingId) async {
    final res = await _api.safePost('${ApiEndpoints.listings}/$listingId/mark-sold', {});
    return res.isOk;
  }

  Future<bool> saveProduct(WatchModel watch) async {
    final payload = <String, dynamic>{
      'source': watch.isEbay ? 'ebay' : 'local',
      'id': watch.idString,
      'productId': watch.idString,
      if (watch.title.isNotEmpty) 'title': watch.title.length > 295 ? watch.title.substring(0, 295) : watch.title,
      if (watch.brand.isNotEmpty) 'brand': watch.brand,
      if (watch.price > 0) 'price': watch.price,
      if (watch.currency.isNotEmpty) 'currency': watch.currency,
      if (watch.rawImage != null && watch.rawImage!.isNotEmpty) 'image': watch.rawImage,
      if (watch.location.isNotEmpty) 'region': watch.location,
    };
    final res = await _api.safePost(ApiEndpoints.savedProducts, payload);
    return res.isOk;
  }

  Future<bool> toggleSave(String listingId, {WatchModel? watch}) async {
    if (watch != null) {
      return saveProduct(watch);
    }
    final isEbayId = listingId.toLowerCase().contains('ebay') || listingId.contains('|');
    final payload = <String, dynamic>{
      'source': isEbayId ? 'ebay' : 'local',
      'id': listingId,
      'productId': listingId,
    };
    final res = await _api.safePost(ApiEndpoints.savedProducts, payload);
    return res.isOk;
  }

  Future<List<WatchModel>?> getSavedPosts() async {
    final res = await _api.safeGet(ApiEndpoints.savedProducts);
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    }
    return null;
  }

  Future<bool> purchaseListing(String listingId, {double? price, String? buyerName}) async {
    // 1. Create order on backend: POST /api/v1/orders
    final orderRes = await _api.safePost('/orders', {
      'listingId': listingId,
      'quantity': 1,
    });
    if (orderRes.isOk && orderRes.body != null) {
      final body = orderRes.body is Map ? orderRes.body : {};
      final data = body['data'] is Map ? (body['data']['order'] ?? body['data']) : body['data'];
      final orderId = data is Map ? (data['id'] ?? data['_id'])?.toString() : null;
      if (orderId != null && orderId.isNotEmpty) {
        // 2. Confirm order payment: POST /api/v1/orders/:orderId/confirm-payment
        final confirmRes = await _api.safePost('/orders/$orderId/confirm-payment', {});
        if (confirmRes.isOk) return true;
      }
      return true;
    }

    // Direct purchase fallback: POST /api/v1/purchases
    final res = await _api.safePost('/purchases', {
      'listingId': listingId,
      if (price != null) 'price': price,
      if (buyerName != null) 'buyerName': buyerName,
    });
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