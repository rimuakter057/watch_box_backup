import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../../../models/watch_model.dart';

class EbayApiService {
  final ApiClient _api = ApiClient.to;

  /// Fetches the authenticated user's eBay connection status.
  /// Returns a Map containing `connected` (bool), `status` (String), `connection` (Map), etc.
  Future<Map<String, dynamic>?> getStatus() async {
    try {
      debugPrint("🛒 [EBAY API SERVICE] Fetching eBay connection status: ${ApiEndpoints.ebayStatus}");
      final res = await _api.safeGet(ApiEndpoints.ebayStatus);
      if (res.isOk && res.body != null) {
        final body = res.body is Map ? res.body : {};
        if (body['data'] is Map<String, dynamic>) {
          return body['data'] as Map<String, dynamic>;
        } else if (body['data'] is Map) {
          return Map<String, dynamic>.from(body['data']);
        }
        return Map<String, dynamic>.from(body);
      }
      debugPrint("⚠️ [EBAY API SERVICE] Status returned error: ${res.statusCode} | ${res.statusText}");
    } catch (e) {
      debugPrint("❌ [EBAY API SERVICE] Error fetching status: $e");
    }
    return null;
  }

  /// Requests the eBay OAuth consent URL for the authenticated user.
  /// Returns the `authorizationUrl` as a String.
  Future<String?> getConnectUrl() async {
    try {
      debugPrint("🛒 [EBAY API SERVICE] Requesting eBay OAuth URL: ${ApiEndpoints.ebayConnect}?response=json");
      final res = await _api.safeGet(
        ApiEndpoints.ebayConnect,
        query: {'response': 'json'},
      );
      if (res.isOk && res.body != null) {
        final body = res.body is Map ? res.body : {};
        final data = body['data'] is Map ? body['data'] as Map : body;
        final url = (data['authorizationUrl'] ?? data['url'] ?? data['authUrl'])?.toString();
        debugPrint("🛒 [EBAY API SERVICE] Received eBay OAuth URL: $url");
        return url;
      }
      debugPrint("⚠️ [EBAY API SERVICE] getConnectUrl failed: ${res.statusCode} | ${res.body}");
    } catch (e) {
      debugPrint("❌ [EBAY API SERVICE] Error requesting connect URL: $e");
    }
    return null;
  }

  /// Disconnects the user's eBay account and revokes tokens.
  Future<bool> disconnect() async {
    try {
      debugPrint("🛒 [EBAY API SERVICE] Disconnecting eBay account: ${ApiEndpoints.ebayDisconnect}");
      final res = await _api.safePost(ApiEndpoints.ebayDisconnect, {});
      if (res.isOk) {
        debugPrint("✅ [EBAY API SERVICE] eBay account disconnected successfully.");
        return true;
      }
      debugPrint("⚠️ [EBAY API SERVICE] Disconnect failed: ${res.statusCode} | ${res.body}");
    } catch (e) {
      debugPrint("❌ [EBAY API SERVICE] Error disconnecting: $e");
    }
    return false;
  }

  /// Scrapes / searches watch listings directly from eBay via the backend Browse API.
  Future<List<WatchModel>?> searchEbayListings({
    required String query,
    int limit = 20,
    String? marketplaceId,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'q': query,
        'limit': limit,
      };
      if (marketplaceId != null) {
        params['marketplaceId'] = marketplaceId;
      }
      debugPrint("🛒 [EBAY API SERVICE] Searching eBay listings: ${ApiEndpoints.ebaySearch} with params $params");
      final res = await _api.safeGet(ApiEndpoints.ebaySearch, query: params);
      if (res.isOk && res.body != null) {
        final body = res.body is Map ? res.body : {};
        final items = body['data']?['items'] ?? body['items'];
        if (items is List) {
          return items
              .whereType<Map>()
              .map((e) => WatchModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("❌ [EBAY API SERVICE] Error searching eBay listings: $e");
    }
    return null;
  }
}
