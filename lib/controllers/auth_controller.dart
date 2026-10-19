import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/db/db_helper.dart';
import '../core/prefs/pref_manager.dart';
import '../core/network/services/auth_api_service.dart';
import '../core/network/services/subscriptions_api_service.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final PrefManager _pref = Get.find<PrefManager>();
  final DbHelper _dbHelper = DbHelper();
  
  // Lazy access to Network API Services
  AuthApiService get _authApi => Get.find<AuthApiService>();
  SubscriptionsApiService get _subApi => Get.find<SubscriptionsApiService>();

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint("🚀 [AUTH CONTROLLER] Initializing AuthController...");
    _loadUserSession();
  }

  Future<void> restoreSession() async {
    debugPrint("🔄 [AUTH CONTROLLER] Restoring session via PrefManager / JWT token...");
    await _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final hasToken = _pref.hasToken;
    debugPrint("🔄 [AUTH CONTROLLER] Checking authorization state -> hasToken: $hasToken");

    if (!hasToken) {
      debugPrint("❌ [AUTH ERROR] Not authorized: No access token found in preferences. Please sign in. No fallback.");
      currentUser.value = null;
      return;
    }

    isLoading.value = true;
    try {
      debugPrint("📡 [AUTH CONTROLLER] Syncing live profile from backend for user session...");
      final profileUser = await fetchProfile();
      if (profileUser != null) {
        debugPrint("✅ [AUTH CONTROLLER] Live profile session synced successfully: ${profileUser.name} (${profileUser.email})");
      } else {
        debugPrint("❌ [AUTH ERROR] Not authorized: Live profile sync failed. No fallback.");
        currentUser.value = null;
      }
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Exception during authorization check: $e. No fallback.");
      currentUser.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void handleSessionExpired() {
    debugPrint("🚨 [AUTH CONTROLLER] Session expired. Resetting currentUser and clearing session.");
    currentUser.value = null;
    _pref.clearSession();
  }

  // Fetch full live profile from GET /api/v1/users/me
  Future<UserModel?> fetchProfile() async {
    if (!_pref.hasToken) {
      debugPrint("❌ [AUTH ERROR] Cannot fetch profile: User not authorized (no access token). No fallback.");
      return null;
    }

    debugPrint("👤 [AUTH CONTROLLER] Requesting profile fetch from backend API...");
    try {
      final profileData = await _authApi.getProfile();
      if (profileData != null && profileData.isNotEmpty) {
        final existingUser = currentUser.value;
        final name = (profileData['displayName'] ?? profileData['name'] ?? _pref.activeUserName).toString();
        final email = (profileData['email'] ?? _pref.activeUserEmail).toString();
        final backendId = profileData['id']?.toString() ?? _pref.activeUserBackendId;
        final role = (profileData['role'] ?? existingUser?.role ?? _pref.activeUserRole).toString();
        final plan = (profileData['plan'] ?? existingUser?.plan ?? _pref.activeUserPlan).toString();
        final phone = profileData['phone']?.toString() ?? _pref.activeUserPhone;
        final country = profileData['country']?.toString() ?? _pref.activeUserCountry;
        String? avatarUrl = profileData['avatarUrl']?.toString();
        if (avatarUrl == null || avatarUrl.isEmpty) {
          avatarUrl = await _authApi.getAvatar();
        }
        if (avatarUrl == null || avatarUrl.isEmpty) {
          final cached = _pref.activeUserAvatarUrl;
          if (cached.isNotEmpty) avatarUrl = cached;
        }
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          avatarUrl = _authApi.formatAvatarUrl(avatarUrl);
        }

        final emailVerified = profileData['emailVerified'] == true;
        final currency = (profileData['preferences'] is Map 
            ? profileData['preferences']['currency'] 
            : _pref.preferredCurrency).toString();
        final darkMode = profileData['darkMode'] == true || _pref.isDarkMode;

        final user = UserModel(
          id: existingUser?.id ?? _pref.activeUserId,
          backendId: backendId,
          name: name.isNotEmpty ? name : (email.isNotEmpty ? email.split('@').first : "User"),
          email: email,
          role: role,
          plan: plan,
          status: 'active',
          phone: phone,
          country: country,
          avatarUrl: avatarUrl,
          emailVerified: emailVerified,
          currency: currency,
          darkMode: darkMode,
        );
        currentUser.value = user;

        await _pref.setActiveUserName(user.name);
        await _pref.setActiveUserEmail(user.email);
        if (backendId.isNotEmpty) await _pref.setActiveUserBackendId(backendId);
        await _pref.setActiveUserRole(role);
        await _pref.setActiveUserPlan(plan);
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          await _pref.setActiveUserAvatarUrl(avatarUrl);
        }
        await _pref.setPreferredCurrency(currency);

        debugPrint("✅ [AUTH CONTROLLER] Profile successfully fetched and synced into state: ${user.name} <${user.email}> (Verified: $emailVerified, Currency: $currency, Dark: $darkMode)");
        return user;
      } else {
        debugPrint("❌ [AUTH ERROR] Profile fetch failed: Not authorized or profile data empty. No fallback.");
        return null;
      }
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Exception fetching backend profile: $e. No fallback.");
      return null;
    }
  }

  // Login: Syncs with live backend API (POST /api/v1/auth/login) strictly without fallback
  Future<bool> login(String name, String role, String plan, {String? email, String? password}) async {
    final effectiveEmail = (email ?? '').trim();
    final effectivePassword = password ?? '';

    if (effectiveEmail.isEmpty || effectivePassword.isEmpty) {
      debugPrint("❌ [AUTH ERROR] Login failed: Email and password are required. No fallback.");
      Get.snackbar("Missing Credentials", "Please enter both email and password.");
      return false;
    }

    debugPrint("🔐 [AUTH CONTROLLER] Starting login process for: $effectiveEmail");
    isLoading.value = true;
    Map<String, dynamic>? backendData;
    
    // 1. Live backend authentication
    try {
      backendData = await _authApi.login(effectiveEmail, effectivePassword);
      if (backendData != null) {
        debugPrint("✅ [AUTH CONTROLLER] Live backend authentication succeeded for: $effectiveEmail");
      } else {
        debugPrint("❌ [AUTH ERROR] Login failed for $effectiveEmail: Backend returned null or unauthorized. No fallback.");
        isLoading.value = false;
        Get.snackbar("Authentication Failed", "Invalid email or password. Please try again.");
        return false;
      }
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Backend login error for $effectiveEmail: $e. No fallback.");
      isLoading.value = false;
      Get.snackbar("Authentication Error", "Could not sign in: $e");
      return false;
    }

    // 2. Persist authenticated session
    try {
      final db = await _dbHelper.database;
      final accountData = backendData['account'] is Map 
          ? backendData['account'] as Map<String, dynamic> 
          : null;
      
      final resolvedName = accountData?['displayName']?.toString() ?? (name.trim().isNotEmpty ? name.trim() : effectiveEmail.split('@').first);
      final resolvedEmail = accountData?['email']?.toString() ?? effectiveEmail;
      final backendId = accountData?['id']?.toString() ?? _pref.activeUserBackendId;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'name = ?',
        whereArgs: [resolvedName],
      );

      UserModel user;
      if (maps.isNotEmpty) {
        user = UserModel.fromMap(maps.first);
        if (user.plan != plan || user.role != role) {
          await db.update(
            'users',
            {'plan': plan, 'role': role},
            where: 'id = ?',
            whereArgs: [user.id],
          );
          user = user.copyWith(plan: plan, role: role);
        }
      } else {
        final newUser = UserModel(
          name: resolvedName,
          role: role,
          plan: plan,
          status: 'active',
        );
        final id = await db.insert('users', newUser.toMap());
        user = newUser.copyWith(id: id);
      }

      if (!user.isActive) {
        Get.snackbar("Access Denied", "This user account has been deactivated.");
        return false;
      }

      final fullUser = user.copyWith(
        backendId: backendId,
        email: resolvedEmail,
        phone: accountData?['phone']?.toString() ?? _pref.activeUserPhone,
        country: accountData?['country']?.toString() ?? _pref.activeUserCountry,
        avatarUrl: accountData?['avatarUrl']?.toString() ?? _pref.activeUserAvatarUrl,
        emailVerified: accountData?['emailVerified'] == true,
        currency: accountData?['preferences'] is Map ? accountData!['preferences']['currency']?.toString() ?? 'USD' : _pref.preferredCurrency,
        darkMode: accountData?['darkMode'] == true || _pref.isDarkMode,
      );

      currentUser.value = fullUser;
      await _pref.setActiveUserId(user.id);
      await _pref.setActiveUserName(fullUser.name);
      await _pref.setActiveUserEmail(fullUser.email);
      if (backendId.isNotEmpty) await _pref.setActiveUserBackendId(backendId);
      await _pref.setActiveUserRole(fullUser.role);
      await _pref.setActiveUserPlan(fullUser.plan);

      debugPrint("✅ [AUTH CONTROLLER] Login completed. User session set: ${fullUser.name} | Role: ${fullUser.role} | Plan: ${fullUser.plan}");

      // Async fetch profile to ensure complete consistency with backend
      fetchProfile();

      return true;
    } catch (e) {
      debugPrint("❌ [AUTH CONTROLLER] Error in login: $e");
      Get.snackbar("Login Error", "Could not complete login: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Register: Syncs with live backend API (POST /api/v1/auth/register)
  Future<bool> register(
    String name,
    String email,
    String password, {
    String? phone,
    String? country,
    double? latitude,
    double? longitude,
    String role = 'user',
    String plan = 'free',
  }) async {
    debugPrint("📝 [AUTH CONTROLLER] Starting registration for: $name ($email), Phone: $phone, Country: $country, Role: $role");
    isLoading.value = true;
    try {
      final res = await _authApi.register(
        name,
        email,
        password,
        phone: phone,
        country: country,
        latitude: latitude,
        longitude: longitude,
      );
      if (res != null) {
        debugPrint("✅ [AUTH CONTROLLER] Live backend register succeeded for: $email");
      } else {
        debugPrint("❌ [AUTH ERROR] Registration failed on backend for $email. No fallback.");
        isLoading.value = false;
        Get.snackbar("Registration Failed", "Could not create account on server. Please try again.");
        return false;
      }
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Backend register error: $e. No fallback.");
      isLoading.value = false;
      Get.snackbar("Registration Error", "Error registering account: $e");
      return false;
    }

    final loginSuccess = await login(name, role, plan, email: email, password: password);
    if (loginSuccess && (phone != null || country != null)) {
      await updateProfile(
        displayName: name,
        phone: phone,
        country: country,
      );
    }
    return loginSuccess;
  }

  // Update Profile: calls PATCH /api/v1/users/me
  Future<bool> updateProfile({
    String? displayName,
    String? phone,
    String? country,
    String? avatarUrl,
    List<int>? profileImageBytes,
    String? profileImageName,
    List<int>? bannerImageBytes,
    String? bannerImageName,
  }) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [AUTH ERROR] Cannot update profile: User not authorized (no access token). No fallback.");
      Get.snackbar("Authentication Required", "Please sign in to update profile.");
      return false;
    }

    debugPrint("✏️ [AUTH CONTROLLER] Triggering updateProfile: Name=$displayName, Phone=$phone, Country=$country, HasAvatar=${profileImageBytes != null || avatarUrl != null}");
    isLoading.value = true;
    try {
      final resData = await _authApi.updateProfile(
        displayName: displayName,
        phone: phone,
        country: country,
        avatarUrl: avatarUrl,
        profileImageBytes: profileImageBytes,
        profileImageName: profileImageName,
        bannerImageBytes: bannerImageBytes,
        bannerImageName: bannerImageName,
      );

      if (resData == null) {
        debugPrint("❌ [AUTH ERROR] Profile update rejected by backend / not authorized. No fallback.");
        Get.snackbar("Error", "Could not update profile on server.");
        return false;
      }

      // Immediate live profile re-fetch right after updating
      debugPrint("🔄 [AUTH CONTROLLER] Immediately re-fetching live profile from server after update...");
      await fetchProfile();

      debugPrint("✅ [AUTH CONTROLLER] Profile updated & live profile fetched successfully.");
      Get.snackbar("Success", "Profile updated successfully.");
      return true;
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Error updating profile: $e. No fallback.");
      Get.snackbar("Error", "Could not update profile: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateAvatar(List<int> imageBytes, String filename) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [AUTH ERROR] Cannot update avatar: User not authorized (no access token). No fallback.");
      Get.snackbar("Authentication Required", "Please sign in to update profile picture.");
      return false;
    }

    debugPrint("📷 [AUTH CONTROLLER] Uploading profile picture (${imageBytes.length} bytes)...");
    isLoading.value = true;
    try {
      final avatarUrl = await _authApi.uploadAvatar(imageBytes, filename);
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        // Immediately fetch live profile right after updating
        debugPrint("🔄 [AUTH CONTROLLER] Immediately re-fetching live profile after avatar upload...");
        await fetchProfile();
        debugPrint("✅ [AUTH CONTROLLER] Profile picture uploaded & live profile refreshed: $avatarUrl");
        Get.snackbar("Success", "Profile picture updated successfully!");
        return true;
      } else {
        debugPrint("❌ [AUTH ERROR] Avatar upload rejected by backend. No fallback.");
        Get.snackbar("Error", "Could not upload profile picture to server.");
        return false;
      }
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Error updating avatar: $e. No fallback.");
      Get.snackbar("Error", "Could not update profile picture: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP for email confirmation
  Future<bool> verifyOtp(String email, String code) async {
    debugPrint("🔢 [AUTH CONTROLLER] Verifying OTP: $email ($code)");
    isLoading.value = true;
    try {
      final success = await _authApi.verifyOtp(email, code);
      if (success) {
        Get.snackbar("Verified", "OTP verified successfully.");
      } else {
        debugPrint("❌ [AUTH ERROR] OTP verification failed on backend. No fallback.");
        Get.snackbar("Verification Failed", "Invalid or expired code.");
      }
      return success;
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] OTP verification error: $e. No fallback.");
      Get.snackbar("Error", "Could not verify code.");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // FCM Token sync (PATCH /api/v1/users/update-fcm-token)
  Future<bool> updateFcmToken(String fcmToken) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [AUTH ERROR] Cannot update FCM token: User not authorized (no access token). No fallback.");
      return false;
    }
    debugPrint("🔔 [AUTH CONTROLLER] Updating FCM token...");
    try {
      return await _authApi.updateFcmToken(fcmToken);
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Error updating FCM token: $e. No fallback.");
      return false;
    }
  }

  // Update Preferences: Currency and Dark Mode
  Future<void> updatePreferences({String? currency, bool? darkMode}) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [AUTH ERROR] Cannot update preferences: User not authorized (no access token). No fallback.");
      return;
    }
    debugPrint("⚙️ [AUTH CONTROLLER] Updating preferences -> Currency=$currency, DarkMode=$darkMode");
    try {
      final ok = await _authApi.updatePreferences(currency: currency, darkMode: darkMode);
      if (!ok) {
        debugPrint("❌ [AUTH ERROR] Backend preference update rejected / not authorized. No fallback.");
        return;
      }
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Backend preference update failed: $e. No fallback.");
      return;
    }

    final existing = currentUser.value;
    if (existing != null) {
      currentUser.value = existing.copyWith(
        currency: currency ?? existing.currency,
        darkMode: darkMode ?? existing.darkMode,
      );
    }
    if (currency != null) await _pref.setPreferredCurrency(currency);
    if (darkMode != null) await _pref.setDarkMode(darkMode);
    debugPrint("✅ [AUTH CONTROLLER] State & preferences updated.");
  }

  // Change Password: Calls live backend (POST /api/v1/auth/change-password)
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [AUTH ERROR] Cannot change password: User not authorized (no access token). No fallback.");
      Get.snackbar("Authentication Required", "Please sign in to change password.");
      return false;
    }

    debugPrint("🔒 [AUTH CONTROLLER] Initiating changePassword request...");
    try {
      final success = await _authApi.changePassword(currentPassword, newPassword);
      if (success) {
        debugPrint("✅ [AUTH CONTROLLER] Password changed successfully on backend.");

        // Backend revokes all active sessions upon password change (auth.service.ts: sessions.revokeAll).
        // Automatically re-authenticate immediately with the new password to establish a fresh active session.
        final email = currentUser.value?.email.isNotEmpty == true 
            ? currentUser.value!.email 
            : _pref.activeUserEmail;
            
        if (email.isNotEmpty) {
          debugPrint("🔄 [AUTH CONTROLLER] Re-authenticating with new password for $email to establish active session...");
          final loginData = await _authApi.login(email, newPassword);
          if (loginData != null) {
            debugPrint("✅ [AUTH CONTROLLER] Re-authentication succeeded. Fresh session active.");
            await fetchProfile();
          } else {
            debugPrint("⚠️ [AUTH CONTROLLER] Re-authentication failed after password change. Clearing session.");
            handleSessionExpired();
          }
        }

        Get.snackbar("Success", "Password updated successfully on server.");
        return true;
      } else {
        debugPrint("❌ [AUTH ERROR] Change password rejected by backend / not authorized. No fallback.");
        Get.snackbar("Error", "Could not change password. Please check your current password.");
        return false;
      }
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Change password backend error: $e. No fallback.");
      Get.snackbar("Error", "Server error changing password: $e");
      return false;
    }
  }

  // Forgot Password: Calls live backend (POST /api/v1/auth/forgot-password)
  Future<bool> forgotPassword(String email) async {
    debugPrint("📧 [AUTH CONTROLLER] Initiating forgotPassword request for: $email");
    try {
      final ok = await _authApi.forgotPassword(email);
      if (ok) {
        debugPrint("✅ [AUTH CONTROLLER] Forgot password response: success");
        return true;
      } else {
        debugPrint("❌ [AUTH ERROR] Forgot password rejected by backend. No fallback.");
        return false;
      }
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Forgot password exception: $e. No fallback.");
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint("🚪 [AUTH CONTROLLER] Performing logout...");
    try {
      await _authApi.logout();
    } catch (e) {
      debugPrint("⚠️ [AUTH CONTROLLER] Logout endpoint error: $e");
    }
    currentUser.value = null;
    await _pref.clearSession();
    debugPrint("✅ [AUTH CONTROLLER] User logged out, redirecting to /login.");
    Get.offAllNamed('/login');
  }

  // Delete Account: calls DELETE /api/v1/users/me
  Future<bool> deleteAccount() async {
    if (!_pref.hasToken) {
      debugPrint("❌ [AUTH ERROR] Cannot delete account: User not authorized (no access token). No fallback.");
      return false;
    }

    debugPrint("🗑️ [AUTH CONTROLLER] Initiating account deletion...");
    isLoading.value = true;
    try {
      final success = await _authApi.deleteAccount();
      if (!success) {
        debugPrint("❌ [AUTH ERROR] Backend rejected account deletion / not authorized. No fallback.");
        Get.snackbar("Error", "Could not delete account on server.");
        return false;
      }

      final user = currentUser.value;
      if (user?.id != null) {
        try {
          final db = await _dbHelper.database;
          await db.delete('users', where: 'id = ?', whereArgs: [user!.id]);
        } catch (_) {}
      }
      currentUser.value = null;
      await _pref.clearSession();
      debugPrint("✅ [AUTH CONTROLLER] Account deleted and local session cleared.");
      Get.offAllNamed('/login');
      Get.snackbar("Account Deleted", "Your account has been deleted permanently.");
      return true;
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Error deleting account: $e. No fallback.");
      Get.snackbar("Error", "Could not delete account: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Upgrade Plan: Syncs with live backend (POST /api/v1/subscriptions/change-plan)
  Future<void> upgradePlan() async {
    final user = currentUser.value;
    if (user == null || user.id == null) return;
    if (!_pref.hasToken) {
      debugPrint("❌ [AUTH ERROR] Cannot upgrade plan: User not authorized (no access token). No fallback.");
      Get.snackbar("Authentication Required", "Please sign in to upgrade plan.");
      return;
    }
    
    debugPrint("💳 [AUTH CONTROLLER] Upgrading plan to paid for user: ${user.name}");
    isLoading.value = true;
    try {
      final success = await _subApi.changePlan('paid');
      if (!success) {
        debugPrint("❌ [AUTH ERROR] Subscription upgrade failed on backend / not authorized. No fallback.");
        Get.snackbar("Error", "Could not upgrade plan on server.");
        return;
      }
      debugPrint("✅ [AUTH CONTROLLER] Subscriptions API updated to paid plan.");

      final updatedUser = user.copyWith(plan: 'paid');
      currentUser.value = updatedUser;
      await _pref.setActiveUserPlan('paid');
      Get.snackbar("Success", "Upgraded to Elite Plan successfully!");
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Upgrade error: $e. No fallback.");
      Get.snackbar("Error", "Could not upgrade plan: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Downgrade Plan
  Future<void> downgradePlan() async {
    final user = currentUser.value;
    if (user == null || user.id == null) return;
    if (!_pref.hasToken) {
      debugPrint("❌ [AUTH ERROR] Cannot downgrade plan: User not authorized (no access token). No fallback.");
      return;
    }
    
    debugPrint("💳 [AUTH CONTROLLER] Downgrading plan to free for user: ${user.name}");
    isLoading.value = true;
    try {
      final success = await _subApi.changePlan('free');
      if (!success) {
        debugPrint("❌ [AUTH ERROR] Subscription downgrade failed on backend / not authorized. No fallback.");
        return;
      }
      debugPrint("✅ [AUTH CONTROLLER] Subscriptions API updated to free plan.");

      final updatedUser = user.copyWith(plan: 'free');
      currentUser.value = updatedUser;
      await _pref.setActiveUserPlan('free');
      Get.snackbar("Success", "Switched to Standard Free tier.");
    } catch (e) {
      debugPrint("❌ [AUTH ERROR] Downgrade error: $e. No fallback.");
    } finally {
      isLoading.value = false;
    }
  }
}