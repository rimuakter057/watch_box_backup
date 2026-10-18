import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import '../prefs/pref_manager.dart';
import 'api_endpoints.dart';
import '../../controllers/auth_controller.dart';

class ApiClient extends GetConnect {
  static ApiClient get to => Get.find<ApiClient>();
  final PrefManager _pref = Get.find<PrefManager>();

  Future<bool>? _refreshFuture;

  @override
  void onInit() {
    super.onInit();
    baseUrl = _pref.apiBaseUrl;
    timeout = const Duration(seconds: 40);

    // Request modifier: Attach JSON headers and JWT Bearer token & debug log
    httpClient.addRequestModifier<dynamic>((Request request) {
      request.headers['Accept'] = 'application/json';

      final hasMultipart = request.headers.entries.any(
        (e) => e.key.toLowerCase() == 'content-type' && e.value.contains('multipart/form-data'),
      );
      if (!hasMultipart) {
        request.headers['Content-Type'] = 'application/json';
      }

      // Do NOT attach expired Authorization header to auth endpoints like /refresh or /login
      final path = request.url.path;
      final isAuthEndpoint = path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/refresh') ||
          path.contains('/auth/forgot-password');

      if (!isAuthEndpoint) {
        final token = _pref.accessToken;
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      debugPrint("----------------------------------------------------------------------");
      debugPrint("🚀 [HTTP REQUEST] ${request.method.toUpperCase()} -> ${request.url}");
      debugPrint("📋 [HEADERS] Auth: ${request.headers.containsKey('Authorization') ? 'Bearer [PRESENT]' : '[NONE]'} | Type: ${request.headers['content-type'] ?? request.headers['Content-Type'] ?? 'application/json'}");
      return request;
    });

    // Response modifier: Automatically log response and 401 errors
    httpClient.addResponseModifier((Request request, Response response) async {
      debugPrint("----------------------------------------------------------------------");
      if (response.isOk) {
        debugPrint("✅ [HTTP RESPONSE ${response.statusCode}] ${request.method.toUpperCase()} ${request.url}");
        final bodySnippet = response.bodyString != null && response.bodyString!.length > 400
            ? "${response.bodyString!.substring(0, 400)}... (truncated)"
            : response.bodyString;
        debugPrint("📄 [RESPONSE DATA] $bodySnippet");
      } else {
        if (response.statusCode == 401) {
          debugPrint("❌ [NOT AUTHORIZED] 401 Unauthorized for ${request.method.toUpperCase()} ${request.url}");
          debugPrint("❌ [AUTH ERROR] Authentication is required or token expired. Headers: ${request.headers['Authorization'] ?? '[NONE]'}.");
        } else {
          debugPrint("⚠️ [HTTP ERROR ${response.statusCode}] ${request.method.toUpperCase()} ${request.url} | StatusText: ${response.statusText}");
        }
        debugPrint("📄 [ERROR BODY] ${response.bodyString}");
      }
      debugPrint("----------------------------------------------------------------------");

      return response;
    });
  }

  bool _canAttemptRefresh(String url) {
    if (url.contains('/auth/login') ||
        url.contains('/auth/register') ||
        url.contains('/auth/refresh') ||
        url.contains('/auth/forgot-password') ||
        url.contains('/auth/reset-password')) {
      return false;
    }
    return _pref.refreshToken != null && _pref.refreshToken!.isNotEmpty;
  }

  Future<bool> attemptTokenRefresh() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = _executeTokenRefresh();
    try {
      final success = await _refreshFuture!;
      return success;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _executeTokenRefresh() async {
    final rToken = _pref.refreshToken;
    if (rToken == null || rToken.isEmpty) {
      debugPrint("❌ [HTTP REFRESH] No refresh token present. Cannot refresh session.");
      _handleSessionExpired();
      return false;
    }

    debugPrint("🔑 [HTTP REFRESH] Sending POST /auth/refresh with refresh token...");
    try {
      final res = await post(
        ApiEndpoints.refresh,
        {'refreshToken': rToken},
      );
      if (res.isOk && res.body != null) {
        final body = res.body is Map ? res.body as Map<String, dynamic> : jsonDecode(res.bodyString ?? '{}');
        final data = body['data'] is Map ? body['data'] as Map<String, dynamic> : body;
        final tokens = data['tokens'] is Map ? data['tokens'] as Map<String, dynamic> : data;
        final newAccess = tokens['accessToken'] ?? tokens['access_token'] ?? data['accessToken'];
        final newRefresh = tokens['refreshToken'] ?? tokens['refresh_token'] ?? data['refreshToken'];

        if (newAccess != null && newAccess.toString().isNotEmpty) {
          await _pref.setAccessToken(newAccess.toString());
          if (newRefresh != null && newRefresh.toString().isNotEmpty) {
            await _pref.setRefreshToken(newRefresh.toString());
          }
          debugPrint("✅ [HTTP REFRESH] Access token successfully refreshed and stored.");
          return true;
        }
      }
      debugPrint("❌ [HTTP REFRESH] Refresh rejected by server: ${res.statusCode} | ${res.bodyString}");
    } catch (e) {
      debugPrint("❌ [HTTP REFRESH ERROR] Exception during token refresh: $e");
    }

    _handleSessionExpired();
    return false;
  }

  void _handleSessionExpired() {
    debugPrint("🚨 [AUTH ERROR] Session expired or invalid refresh token. Clearing local session...");
    _pref.clearSession();
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().handleSessionExpired();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute != '/login' && Get.currentRoute != '/splash' && Get.currentRoute != '/onboarding') {
        Get.offAllNamed('/login');
        Get.snackbar(
          "Session Expired",
          "Your session has expired. Please log in again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1E293B),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B)),
        );
      }
    });
  }

  Future<Response<T>> safeGet<T>(String url, {Map<String, dynamic>? query}) async {
    debugPrint("🌐 [API FETCH CALL] safeGet: $url ${query != null ? '| Query: $query' : ''}");
    try {
      var res = await get<T>(url, query: query?.map((k, v) => MapEntry(k, v.toString())));
      if (res.statusCode == 401 && _canAttemptRefresh(url)) {
        final refreshed = await attemptTokenRefresh();
        if (refreshed) {
          debugPrint("🔄 [API RETRY] Retrying safeGet: $url with new access token");
          res = await get<T>(url, query: query?.map((k, v) => MapEntry(k, v.toString())));
        }
      }
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT GET ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safePost<T>(String url, dynamic body, {Map<String, dynamic>? query}) async {
    debugPrint("🌐 [API FETCH CALL] safePost: $url | Payload: $body ${query != null ? '| Query: $query' : ''}");
    try {
      var res = await post<T>(url, body, query: query?.map((k, v) => MapEntry(k, v.toString())));
      if (res.statusCode == 401 && _canAttemptRefresh(url)) {
        final refreshed = await attemptTokenRefresh();
        if (refreshed) {
          debugPrint("🔄 [API RETRY] Retrying safePost: $url with new access token");
          res = await post<T>(url, body, query: query?.map((k, v) => MapEntry(k, v.toString())));
        }
      }
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT POST ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safePatch<T>(String url, dynamic body) async {
    debugPrint("🌐 [API FETCH CALL] safePatch: $url | Payload: $body");
    try {
      var res = await patch<T>(url, body);
      if (res.statusCode == 401 && _canAttemptRefresh(url)) {
        final refreshed = await attemptTokenRefresh();
        if (refreshed) {
          debugPrint("🔄 [API RETRY] Retrying safePatch: $url with new access token");
          res = await patch<T>(url, body);
        }
      }
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT PATCH ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safeDelete<T>(String url) async {
    debugPrint("🌐 [API FETCH CALL] safeDelete: $url");
    try {
      var res = await delete<T>(url);
      if (res.statusCode == 401 && _canAttemptRefresh(url)) {
        final refreshed = await attemptTokenRefresh();
        if (refreshed) {
          debugPrint("🔄 [API RETRY] Retrying safeDelete: $url with new access token");
          res = await delete<T>(url);
        }
      }
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT DELETE ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safePut<T>(String url, dynamic body) async {
    debugPrint("🌐 [API FETCH CALL] safePut: $url | Payload: $body");
    try {
      var res = await put<T>(url, body);
      if (res.statusCode == 401 && _canAttemptRefresh(url)) {
        final refreshed = await attemptTokenRefresh();
        if (refreshed) {
          debugPrint("🔄 [API RETRY] Retrying safePut: $url with new access token");
          res = await put<T>(url, body);
        }
      }
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT PUT ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safeUpload<T>(
    String url,
    List<int> imageBytes,
    String filename, {
    String fieldName = 'image',
    Map<String, String>? fields,
  }) async {
    debugPrint("🌐 [API FETCH CALL] safeUpload: $url | File: $filename (${imageBytes.length} bytes)");
    try {
      final ext = filename.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'webp') {
        mimeType = 'image/webp';
      } else if (ext == 'gif') {
        mimeType = 'image/gif';
      }

      final form = FormData({
        fieldName: MultipartFile(imageBytes, filename: filename, contentType: mimeType),
        ...?fields,
      });
      var res = await post<T>(url, form);
      if (res.statusCode == 401 && _canAttemptRefresh(url)) {
        final refreshed = await attemptTokenRefresh();
        if (refreshed) {
          debugPrint("🔄 [API RETRY] Retrying safeUpload: $url with new access token");
          final retryForm = FormData({
            fieldName: MultipartFile(imageBytes, filename: filename, contentType: mimeType),
            ...?fields,
          });
          res = await post<T>(url, retryForm);
        }
      }
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT UPLOAD ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safeMultipartPatch<T>(String url, {Map<String, String>? fields, Map<String, MultipartFile>? files}) async {
    debugPrint("🌐 [API FETCH CALL] safeMultipartPatch: $url | Fields: ${fields?.keys} | Files: ${files?.keys}");
    try {
      final form = FormData({
        ...?fields,
        ...?files,
      });
      var res = await patch<T>(url, form);
      if (res.statusCode == 401 && _canAttemptRefresh(url)) {
        final refreshed = await attemptTokenRefresh();
        if (refreshed) {
          debugPrint("🔄 [API RETRY] Retrying safeMultipartPatch: $url with new access token");
          final retryForm = FormData({
            ...?fields,
            ...?files,
          });
          res = await patch<T>(url, retryForm);
        }
      }
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT MULTIPART PATCH ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  static List<dynamic>? extractList(dynamic body) {
    if (body == null) return null;
    if (body is List) return body;
    if (body is Map) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map) {
        final items = data['items'] ?? data['data'];
        if (items is List) return items;
      }
      final items = body['items'];
      if (items is List) return items;
    }
    return null;
  }

  dynamic extractData(Response res) {
    if (!res.isOk || res.body == null) return null;
    if (res.body is Map) {
      final map = res.body as Map<String, dynamic>;
      if (map.containsKey('data')) return map['data'];
      return map;
    }
    return res.body;
  }
}