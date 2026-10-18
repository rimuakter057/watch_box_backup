import '../api_client.dart';
import '../api_endpoints.dart';

class VisualSearchApiService {
  final ApiClient _api = ApiClient.to;

  Future<Map<String, dynamic>?> executeImageSearch(List<int> imageBytes, String filename) async {
    final res = await _api.safeUpload(ApiEndpoints.imageSearch, imageBytes, filename);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : (body is Map<String, dynamic> ? body : null);
    }
    return null;
  }

  Future<Map<String, dynamic>?> analyzeImage(List<int> imageBytes, String filename) async {
    final res = await _api.safeUpload(ApiEndpoints.aiAnalyzeImage, imageBytes, filename);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : (body is Map<String, dynamic> ? body : null);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getRecentImageSearches() async {
    final res = await _api.safeGet(ApiEndpoints.imageSearchRecent);
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }
}