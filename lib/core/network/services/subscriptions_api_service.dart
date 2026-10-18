import '../api_client.dart';
import '../api_endpoints.dart';

class SubscriptionsApiService {
  final ApiClient _api = ApiClient.to;

  Future<List<Map<String, dynamic>>?> getPlans() async {
    // 1. Try /plans/all-plans
    var res = await _api.safeGet(ApiEndpoints.plansAll);
    if (!res.isOk) {
      res = await _api.safeGet(ApiEndpoints.subscriptionPlans);
    }
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMySubscription() async {
    // 1. Try /plans/my-active-plan
    var res = await _api.safeGet(ApiEndpoints.plansMyActive);
    if (!res.isOk) {
      res = await _api.safeGet(ApiEndpoints.subscriptionMe);
    }
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : null;
    }
    return null;
  }

  Future<bool> changePlan(String planId) async {
    var res = await _api.safePost(ApiEndpoints.subscriptionChangePlan, {'planId': planId});
    if (!res.isOk) {
      res = await _api.safePost('/plans/change-plan', {'planId': planId});
    }
    return res.isOk;
  }

  Future<String?> createStripeCheckoutSession(String planId) async {
    // 1. Try /payments/create-checkout-session/:planId
    var res = await _api.safePost('${ApiEndpoints.paymentsCheckout}/$planId', {});
    // 2. Fallback to /subscriptions/checkout-session
    if (!res.isOk) {
      res = await _api.safePost(ApiEndpoints.subscriptionCheckout, {'planId': planId});
    }
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'] is Map ? body['data'] as Map<String, dynamic> : body;
      return (data['url'] ?? data['checkoutUrl'] ?? data['sessionUrl'])?.toString();
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getMyTransactions() async {
    var res = await _api.safeGet(ApiEndpoints.paymentsTransactions);
    if (!res.isOk) {
      res = await _api.safeGet('/subscriptions/invoices');
    }
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return null;
  }
}