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

    // Request modifier: Attach JSON headers and JWT Bearer token
    httpClient.addRequestModifier<dynamic>((Request request) {
      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'application/json';
      
      final token = _pref.accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });

    // Response modifier: Automatically handle 401 token refresh
    httpClient.addResponseModifier((Request request, Response response) async {
      if (response.statusCode == 401 && _pref.refreshToken != null) {
        final refreshed = await _attemptRefreshToken();
        if (refreshed) {
          request.headers['Authorization'] = 'Bearer ${_pref.accessToken}';
          return httpClient.request(
            request.url.path,
            request.method,
            body: request.bodyBytes,
            headers: request.headers,
          );
        }
      }
      return response;
    });
  }

  Future<bool> _attemptRefreshToken() async {
    final rToken = _pref.refreshToken;
    if (rToken == null) return false;

    try {
      final res = await post(
        '/auth/refresh',
        {'refreshToken': rToken},
      );
      if (res.isOk && res.body != null) {
        final data = res.body is Map ? res.body['data'] ?? res.body : jsonDecode(res.bodyString ?? '{}');
        final newAccess = data['accessToken'] ?? data['access_token'];
        final newRefresh = data['refreshToken'] ?? data['refresh_token'];
        if (newAccess != null) {
          await _pref.setAccessToken(newAccess.toString());
          if (newRefresh != null) {
            await _pref.setRefreshToken(newRefresh.toString());
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<Response<T>> safeGet<T>(String url, {Map<String, dynamic>? query}) async {
    try {
      return await get<T>(url, query: query?.map((k, v) => MapEntry(k, v.toString())));
    } catch (e) {
      debugPrint("ApiClient GET error [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safePost<T>(String url, dynamic body, {Map<String, dynamic>? query}) async {
    try {
      return await post<T>(url, body, query: query?.map((k, v) => MapEntry(k, v.toString())));
    } catch (e) {
      debugPrint("ApiClient POST error [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safePatch<T>(String url, dynamic body) async {
    try {
      return await patch<T>(url, body);
    } catch (e) {
      debugPrint("ApiClient PATCH error [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safeDelete<T>(String url) async {
    try {
      return await delete<T>(url);
    } catch (e) {
      debugPrint("ApiClient DELETE error [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }

  Future<Response<T>> safeUpload<T>(String url, List<int> imageBytes, String filename, {Map<String, String>? fields}) async {
    try {
      final form = FormData({
        'image': MultipartFile(imageBytes, filename: filename),
        ...?fields,
      });
      return await post<T>(url, form);
    } catch (e) {
      debugPrint("ApiClient Upload error [$url]: $e");
      return Response<T>(statusCode: 503, statusText: "Backend unreachable: $e");
    }
  }
}