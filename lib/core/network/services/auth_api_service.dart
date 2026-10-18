import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../../prefs/pref_manager.dart';

class AuthApiService {
  final ApiClient _api = ApiClient.to;
  final PrefManager _pref = Get.find<PrefManager>();

  Future<void> _saveAuthSession(Map<String, dynamic> data) async {
    // 1. Extract tokens (handles both direct and nested structure from backend)
    final tokens = data['tokens'] is Map 
        ? data['tokens'] as Map<String, dynamic> 
        : (data['auth'] is Map && data['auth']['tokens'] is Map 
            ? data['auth']['tokens'] as Map<String, dynamic> 
            : data);
            
    final token = tokens['accessToken'] ?? tokens['access_token'] ?? data['accessToken'] ?? data['token'];
    final refresh = tokens['refreshToken'] ?? tokens['refresh_token'] ?? data['refreshToken'];
    
    if (token != null) {
      await _pref.setAccessToken(token.toString());
      debugPrint("🔐 [AUTH API] Access Token stored in preferences.");
    }
    if (refresh != null) {
      await _pref.setRefreshToken(refresh.toString());
      debugPrint("🔐 [AUTH API] Refresh Token stored in preferences.");
    }

    // 2. Extract account details
    final account = data['account'] is Map 
        ? data['account'] as Map<String, dynamic> 
        : (data['auth'] is Map && data['auth']['account'] is Map 
            ? data['auth']['account'] as Map<String, dynamic> 
            : (data['id'] != null ? data : null));

    if (account != null) {
      if (account['id'] != null) {
        await _pref.setActiveUserBackendId(account['id'].toString());
      }
      final name = account['displayName'] ?? account['name'];
      if (name != null) {
        await _pref.setActiveUserName(name.toString());
      }
      if (account['email'] != null) {
        await _pref.setActiveUserEmail(account['email'].toString());
      }
      if (account['phone'] != null) {
        await _pref.setActiveUserPhone(account['phone'].toString());
      }
      if (account['country'] != null) {
        await _pref.setActiveUserCountry(account['country'].toString());
      }
      if (account['avatarUrl'] != null) {
        await _pref.setActiveUserAvatarUrl(account['avatarUrl'].toString());
      }
      if (account['preferences'] is Map && account['preferences']['currency'] != null) {
        await _pref.setPreferredCurrency(account['preferences']['currency'].toString());
      }
      if (account['darkMode'] != null) {
        await _pref.setDarkMode(account['darkMode'] == true);
      }
      debugPrint("👤 [AUTH API] Account cached: ${account['displayName'] ?? account['name']} <${account['email']}> | Currency: ${account['preferences']?['currency'] ?? 'USD'}");
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    debugPrint("🔐 [AUTH API] Requesting login -> Email: $email");
    final res = await _api.safePost(ApiEndpoints.login, {
      'email': email,
      'password': password,
    });
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body as Map<String, dynamic> : <String, dynamic>{};
      final data = body['data'] is Map ? body['data'] as Map<String, dynamic> : body;
      await _saveAuthSession(data);
      debugPrint("✅ [AUTH API] Login successful for: $email");
      return data;
    }
    debugPrint("⚠️ [AUTH API] Login failed for $email -> StatusCode: ${res.statusCode} | Text: ${res.statusText}");
    return null;
  }

  Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    debugPrint("📝 [AUTH API] Requesting registration -> Name: $name | Email: $email");
    final res = await _api.safePost(ApiEndpoints.register, {
      'displayName': name,
      'email': email,
      'password': password,
    });
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body as Map<String, dynamic> : <String, dynamic>{};
      final data = body['data'] is Map ? body['data'] as Map<String, dynamic> : body;
      await _saveAuthSession(data);
      debugPrint("✅ [AUTH API] Registration successful for: $email");
      return data;
    }
    debugPrint("⚠️ [AUTH API] Registration failed for $email -> StatusCode: ${res.statusCode} | Text: ${res.statusText}");
    return null;
  }

  Future<bool> verifyOtp(String email, String code) async {
    debugPrint("🔢 [AUTH API] Verifying OTP for: $email with code: $code");
    final res = await _api.safePost('/auth/verify-email/confirm', {
      'email': email,
      'code': code,
    });
    if (res.isOk) {
      debugPrint("✅ [AUTH API] OTP verification confirmed.");
      return true;
    }
    // Also try alternate reset code verify endpoint
    final res2 = await _api.safePost('/auth/verify-reset-code', {
      'email': email,
      'code': code,
    });
    if (res2.isOk) {
      debugPrint("✅ [AUTH API] Reset code verification confirmed.");
      return true;
    }
    debugPrint("⚠️ [AUTH API] OTP verification failed: ${res.statusCode}");
    return false;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    debugPrint("👤 [PROFILE API] Fetching user profile...");
    // 1. Try /users/my-profile, fallback to /users/me
    var res = await _api.safeGet(ApiEndpoints.userMyProfile);
    if (!res.isOk) {
      res = await _api.safeGet(ApiEndpoints.userMe);
    }

    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body as Map<String, dynamic> : <String, dynamic>{};
      final data = body['data'] is Map ? body['data'] as Map<String, dynamic> : body;
      
      // Update local preferences with live profile attributes
      if (data.isNotEmpty) {
        if (data['id'] != null) await _pref.setActiveUserBackendId(data['id'].toString());
        final name = data['displayName'] ?? data['name'];
        if (name != null) await _pref.setActiveUserName(name.toString());
        if (data['email'] != null) await _pref.setActiveUserEmail(data['email'].toString());
        if (data['phone'] != null) await _pref.setActiveUserPhone(data['phone'].toString());
        if (data['country'] != null) await _pref.setActiveUserCountry(data['country'].toString());
        if (data['avatarUrl'] != null) await _pref.setActiveUserAvatarUrl(data['avatarUrl'].toString());
        if (data['preferences'] is Map && data['preferences']['currency'] != null) {
          await _pref.setPreferredCurrency(data['preferences']['currency'].toString());
        }
        if (data['darkMode'] != null) {
          await _pref.setDarkMode(data['darkMode'] == true);
        }
        debugPrint("✅ [PROFILE API] Profile successfully fetched and synced: ${name ?? 'User'} <${data['email']}>");
      }
      return data;
    }
    debugPrint("⚠️ [PROFILE API] Failed to fetch profile -> StatusCode: ${res.statusCode} | Text: ${res.statusText}");
    return null;
  }

  Future<Map<String, dynamic>?> updateProfile({
    String? displayName,
    String? phone,
    String? country,
    List<int>? profileImageBytes,
    String? profileImageName,
    List<int>? bannerImageBytes,
    String? bannerImageName,
  }) async {
    final Map<String, String> fields = {};
    if (displayName != null && displayName.trim().isNotEmpty) {
      fields['displayName'] = displayName.trim();
    }
    if (phone != null && phone.trim().isNotEmpty) {
      fields['phone'] = phone.trim();
    }
    if (country != null && country.trim().isNotEmpty) {
      fields['country'] = country.trim();
    }

    final Map<String, MultipartFile> files = {};
    if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
      files['profileImage'] = MultipartFile(profileImageBytes, filename: profileImageName ?? 'profile.jpg');
    }
    if (bannerImageBytes != null && bannerImageBytes.isNotEmpty) {
      files['profileBanner'] = MultipartFile(bannerImageBytes, filename: bannerImageName ?? 'banner.jpg');
    }

    Response res;
    if (files.isNotEmpty) {
      debugPrint("✏️ [PROFILE API] Sending multipart update profile with ${files.length} files...");
      res = await _api.safeMultipartPatch(ApiEndpoints.userUpdateProfile, fields: fields, files: files);
      if (!res.isOk) {
        res = await _api.safeMultipartPatch(ApiEndpoints.userMe, fields: fields, files: files);
      }
    } else {
      if (fields.isEmpty) return null;
      debugPrint("✏️ [PROFILE API] Updating profile fields -> $fields");
      res = await _api.safePatch(ApiEndpoints.userUpdateProfile, fields);
      if (!res.isOk) {
        res = await _api.safePatch(ApiEndpoints.userMe, fields);
      }
    }

    if (res.isOk && res.body != null) {
      final resBody = res.body is Map ? res.body as Map<String, dynamic> : <String, dynamic>{};
      final data = resBody['data'] is Map ? resBody['data'] as Map<String, dynamic> : resBody;
      
      if (displayName != null) await _pref.setActiveUserName(displayName);
      if (phone != null) await _pref.setActiveUserPhone(phone);
      if (country != null) await _pref.setActiveUserCountry(country);
      if (data['avatarUrl'] != null) await _pref.setActiveUserAvatarUrl(data['avatarUrl'].toString());
      
      debugPrint("✅ [PROFILE API] Profile updated successfully on server.");
      return data;
    }
    debugPrint("⚠️ [PROFILE API] Profile update failed -> StatusCode: ${res.statusCode} | Text: ${res.statusText}");
    return null;
  }

  Future<String?> uploadAvatar(List<int> imageBytes, String filename) async {
    debugPrint("📷 [PROFILE API] Uploading avatar image to server (${imageBytes.length} bytes)...");
    final res = await _api.safeUpload(
      ApiEndpoints.userAvatar,
      imageBytes,
      filename,
      fieldName: 'image',
    );
    if (res.isOk && res.body != null) {
      final resBody = res.body is Map ? res.body as Map<String, dynamic> : <String, dynamic>{};
      final data = resBody['data'] is Map ? resBody['data'] as Map<String, dynamic> : resBody;
      final avatarUrl = data['avatarUrl']?.toString();
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await _pref.setActiveUserAvatarUrl(avatarUrl);
        debugPrint("✅ [PROFILE API] Avatar updated successfully on server: $avatarUrl");
        return avatarUrl;
      }
    }
    debugPrint("⚠️ [PROFILE API] Avatar upload failed -> StatusCode: ${res.statusCode} | Text: ${res.statusText}");
    return null;
  }

  Future<bool> updateFcmToken(String fcmToken) async {
    debugPrint("🔔 [AUTH API] Syncing FCM token to backend...");
    var res = await _api.safePatch(ApiEndpoints.userUpdateFcmToken, {'fcmToken': fcmToken});
    if (!res.isOk) {
      res = await _api.safePost('/devices', {
        'token': fcmToken,
        'platform': GetPlatform.isAndroid ? 'android' : 'ios',
      });
    }
    return res.isOk;
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    debugPrint("🔒 [AUTH API] Requesting password change on server...");
    final res = await _api.safePost(ApiEndpoints.changePassword, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (res.isOk) {
      debugPrint("✅ [AUTH API] Password change accepted by server.");
      return true;
    }
    debugPrint("⚠️ [AUTH API] Password change failed -> StatusCode: ${res.statusCode} | Text: ${res.statusText}");
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    debugPrint("📧 [AUTH API] Requesting password reset email for: $email");
    final res = await _api.safePost(ApiEndpoints.forgotPassword, {
      'email': email,
    });
    if (res.isOk) {
      debugPrint("✅ [AUTH API] Password reset request dispatched.");
      return true;
    }
    debugPrint("⚠️ [AUTH API] Password reset request failed -> StatusCode: ${res.statusCode}");
    return false;
  }

  Future<bool> updatePreferences({String? currency, bool? darkMode}) async {
    debugPrint("⚙️ [PROFILE API] Updating server preferences: Currency=$currency, DarkMode=$darkMode");
    bool ok = true;
    if (currency != null) {
      final res = await _api.safePatch(ApiEndpoints.userPreferences, {'currency': currency.toUpperCase()});
      ok = ok && res.isOk;
      if (res.isOk) {
        await _pref.setPreferredCurrency(currency.toUpperCase());
        debugPrint("✅ [PROFILE API] Currency preference set to ${currency.toUpperCase()}");
      }
    }
    if (darkMode != null) {
      final res = await _api.safePatch(ApiEndpoints.userDarkMode, {'darkMode': darkMode});
      ok = ok && res.isOk;
      if (res.isOk) {
        await _pref.setDarkMode(darkMode);
        debugPrint("✅ [PROFILE API] Dark mode preference set to $darkMode");
      }
    }
    return ok;
  }

  Future<void> logout() async {
    debugPrint("🚪 [AUTH API] Calling logout endpoint and clearing session...");
    try {
      await _api.safePost(ApiEndpoints.logout, {});
    } catch (e) {
      debugPrint("⚠️ [AUTH API] Logout endpoint error: $e");
    } finally {
      await _pref.clearSession();
      debugPrint("✅ [AUTH API] Session cleared locally.");
    }
  }

  Future<bool> deleteAccount() async {
    debugPrint("🗑️ [PROFILE API] Calling DELETE account...");
    var res = await _api.safeDelete(ApiEndpoints.userDeleteMyAccount);
    if (!res.isOk) {
      res = await _api.safeDelete(ApiEndpoints.userMe);
    }
    if (res.isOk) {
      await _pref.clearSession();
      debugPrint("✅ [PROFILE API] Account deleted from backend & local session cleared.");
      return true;
    }
    debugPrint("⚠️ [PROFILE API] Delete account failed -> StatusCode: ${res.statusCode} | Text: ${res.statusText}");
    return false;
  }
}