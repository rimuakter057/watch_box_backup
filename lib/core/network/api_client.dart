import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import '../prefs/pref_manager.dart';

class ApiClient extends GetConnect {
  static ApiClient get to => Get.find<ApiClient>();
  final PrefManager _pref = Get.find<PrefManager>();

  @override
  void onInit() {
    super.onInit();
    baseUrl = _pref.apiBaseUrl;
    timeout = const Duration(seconds: 6);

    // Request modifier: Attach JSON headers and JWT Bearer token & debug log
    httpClient.addRequestModifier<dynamic>((Request request) {
      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'application/json';
      
      final token = _pref.accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      debugPrint("----------------------------------------------------------------------");
      debugPrint("🚀 [HTTP REQUEST] ${request.method.toUpperCase()} -> ${request.url}");
      debugPrint("📋 [HEADERS] Auth: ${token != null && token.isNotEmpty ? 'Bearer [PRESENT]' : '[NONE]'} | Accept: application/json");
      return request;
    });

    // Response modifier: Automatically handle 401 token refresh & log response
    httpClient.addResponseModifier((Request request, Response response) async {
      debugPrint("----------------------------------------------------------------------");
      if (response.isOk) {
        debugPrint("✅ [HTTP RESPONSE ${response.statusCode}] ${request.method.toUpperCase()} ${request.url}");
        final bodySnippet = response.bodyString != null && response.bodyString!.length > 400
            ? "${response.bodyString!.substring(0, 400)}... (truncated)"
            : response.bodyString;
        debugPrint("📄 [RESPONSE DATA] $bodySnippet");
      } else {
        debugPrint("⚠️ [HTTP ERROR ${response.statusCode}] ${request.method.toUpperCase()} ${request.url} | StatusText: ${response.statusText}");
        debugPrint("📄 [ERROR BODY] ${response.bodyString}");
      }
      debugPrint("----------------------------------------------------------------------");

      if (response.statusCode == 401 && _pref.refreshToken != null) {
        debugPrint("🔄 [HTTP AUTH] 401 Unauthorized encountered. Attempting silent token refresh...");
        final refreshed = await _attemptRefreshToken();
        if (refreshed) {
          debugPrint("✅ [HTTP AUTH] Silent refresh succeeded. Retrying request to ${request.url.path}...");
          request.headers['Authorization'] = 'Bearer ${_pref.accessToken}';
          return httpClient.request(
            request.url.path,
            request.method,
            body: request.bodyBytes,
            headers: request.headers,
          );
        } else {
          debugPrint("❌ [HTTP AUTH] Silent token refresh failed.");
        }
      }
      return response;
    });
  }

  Future<bool> _attemptRefreshToken() async {
    final rToken = _pref.refreshToken;
    if (rToken == null) return false;

    debugPrint("🔑 [HTTP REFRESH] Sending POST /auth/refresh with refresh token...");
    try {
      final res = await post(
        '/auth/refresh',
        {'refreshToken': rToken},
      );
      if (res.isOk && res.body != null) {
        final data = res.body is Map ? res.body['data'] ?? res.body : jsonDecode(res.bodyString ?? '{}');
        final tokens = data is Map && data['tokens'] is Map ? data['tokens'] : data;
        final newAccess = tokens['accessToken'] ?? tokens['access_token'] ?? data['accessToken'];
        final newRefresh = tokens['refreshToken'] ?? tokens['refresh_token'] ?? data['refreshToken'];
        if (newAccess != null) {
          await _pref.setAccessToken(newAccess.toString());
          if (newRefresh != null) {
            await _pref.setRefreshToken(newRefresh.toString());
          }
          debugPrint("🔑 [HTTP REFRESH] New access token stored successfully.");
          return true;
        }
      }
    } catch (e) {
      debugPrint("❌ [HTTP REFRESH ERROR] $e");
    }
    return false;
  }

  Future<Response<T>> safeGet<T>(String url, {Map<String, dynamic>? query}) async {
    debugPrint("🌐 [API FETCH CALL] safeGet: $url ${query != null ? '| Query: $query' : ''}");
    try {
      final res = await get<T>(url, query: query?.map((k, v) => MapEntry(k, v.toString())));
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT GET ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safePost<T>(String url, dynamic body, {Map<String, dynamic>? query}) async {
    debugPrint("🌐 [API FETCH CALL] safePost: $url | Payload: $body ${query != null ? '| Query: $query' : ''}");
    try {
      final res = await post<T>(url, body, query: query?.map((k, v) => MapEntry(k, v.toString())));
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT POST ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safePatch<T>(String url, dynamic body) async {
    debugPrint("🌐 [API FETCH CALL] safePatch: $url | Payload: $body");
    try {
      final res = await patch<T>(url, body);
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT PATCH ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safeDelete<T>(String url) async {
    debugPrint("🌐 [API FETCH CALL] safeDelete: $url");
    try {
      final res = await delete<T>(url);
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT DELETE ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safePut<T>(String url, dynamic body) async {
    debugPrint("🌐 [API FETCH CALL] safePut: $url | Payload: $body");
    try {
      final res = await put<T>(url, body);
      return res;
    } catch (e) {
      debugPrint("❌ [API CLIENT PUT ERROR] [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safeUpload<T>(String url, List<int> imageBytes, String filename, {String fieldName = 'image', Map<String, String>? fields}) async {
    debugPrint("🌐 [API FETCH CALL] safeUpload: $url | File: $filename (${imageBytes.length} bytes)");
    try {
      final form = FormData({
        fieldName: MultipartFile(imageBytes, filename: filename),
        ...?fields,
      });
      return await post<T>(url, form);
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
      return await patch<T>(url, form);
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