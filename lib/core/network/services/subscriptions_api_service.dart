import '../api_client.dart';
import '../api_endpoints.dart';

class SubscriptionsApiService {
  final ApiClient _api = ApiClient.to;

  Future<List<Map<String, dynamic>>?> getPlans() async {
    final res = await _api.safeGet(ApiEndpoints.subscriptionPlans);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final list = body['data']?['items'] ?? body['data'] ?? body['items'];
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMySubscription() async {
    final res = await _api.safeGet(ApiEndpoints.subscriptionMe);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : null;
    }
    return null;
  }

  Future<bool> changePlan(String planId) async {
    final res = await _api.safePost(ApiEndpoints.subscriptionChangePlan, {'planId': planId});
    return res.isOk;
  }

  Future<String?> createStripeCheckoutSession(String planId) async {
    final res = await _api.safePost(ApiEndpoints.subscriptionCheckout, {'planId': planId});
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data']?['url'] ?? body['data']?['checkoutUrl'];
    }
    return null;
  }
}