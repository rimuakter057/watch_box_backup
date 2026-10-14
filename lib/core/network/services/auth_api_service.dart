import 'package:get/get.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../../prefs/pref_manager.dart';

class AuthApiService {
  final ApiClient _api = ApiClient.to;
  final PrefManager _pref = Get.find<PrefManager>();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final res = await _api.safePost(ApiEndpoints.login, {
      'email': email,
      'password': password,
    });
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'] ?? body;
      final token = data['accessToken'] ?? data['token'];
      final refresh = data['refreshToken'];
      if (token != null) await _pref.setAccessToken(token.toString());
      if (refresh != null) await _pref.setRefreshToken(refresh.toString());
      return data is Map<String, dynamic> ? data : null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    final res = await _api.safePost(ApiEndpoints.register, {
      'name': name,
      'email': email,
      'password': password,
    });
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'] ?? body;
      final token = data['accessToken'] ?? data['token'];
      final refresh = data['refreshToken'];
      if (token != null) await _pref.setAccessToken(token.toString());
      if (refresh != null) await _pref.setRefreshToken(refresh.toString());
      return data is Map<String, dynamic> ? data : null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final res = await _api.safeGet(ApiEndpoints.userMe);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      final data = body['data'] ?? body;
      return data is Map<String, dynamic> ? data : null;
    }
    return null;
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final res = await _api.safePost(ApiEndpoints.changePassword, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return res.isOk;
  }

  Future<bool> forgotPassword(String email) async {
    final res = await _api.safePost(ApiEndpoints.forgotPassword, {
      'email': email,
    });
    return res.isOk;
  }

  Future<bool> updatePreferences({String? currency, bool? darkMode}) async {
    bool ok = true;
    if (currency != null) {
      final res = await _api.safePatch(ApiEndpoints.userPreferences, {'currency': currency});
      ok = ok && res.isOk;
    }
    if (darkMode != null) {
      final res = await _api.safePatch(ApiEndpoints.userDarkMode, {'darkMode': darkMode});
      ok = ok && res.isOk;
    }
    return ok;
  }

  Future<void> logout() async {
    await _api.safePost(ApiEndpoints.logout, {});
    await _pref.clearSession();
  }
}