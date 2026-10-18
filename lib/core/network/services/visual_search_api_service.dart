import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../../../models/watch_model.dart';

class VisualSearchResult {
  final bool success;
  final String? searchId;
  final String? query;
  final String? generatedTitle;
  final String? imageUrl;
  final String? probableBrand;
  final String? probableModel;
  final String? probableReferenceNumber;
  final Map<String, dynamic>? visualAttributes;
  final List<WatchModel> items;
  final String? errorMessage;

  VisualSearchResult({
    this.success = true,
    this.searchId,
    this.query,
    this.generatedTitle,
    this.imageUrl,
    this.probableBrand,
    this.probableModel,
    this.probableReferenceNumber,
    this.visualAttributes,
    required this.items,
    this.errorMessage,
  });
}

class VisualSearchApiService {
  final ApiClient _api = ApiClient.to;

  Future<VisualSearchResult> executeVisualSearch(List<int> imageBytes, String filename) async {
    debugPrint("🔍 [VISUAL SEARCH API] Uploading photo (${imageBytes.length} bytes, $filename) to /image-search/visual...");

    // Exclusively use POST /api/v1/image-search/visual
    final res = await _api.safeUpload(
      ApiEndpoints.imageSearchVisual,
      imageBytes,
      filename,
      fieldName: 'image',
    );

    if (res.isOk && res.body != null) {
      debugPrint("✅ [VISUAL SEARCH API] Visual search succeeded from /image-search/visual");
      return _parseVisualResponse(res.body);
    }

    if (res.statusCode == 401) {
      debugPrint("❌ [VISUAL SEARCH API] 401 Unauthorized. User authentication is required. No fallback.");
      return VisualSearchResult(
        success: false,
        items: [],
        errorMessage: "Authentication required. Please login to perform visual search.",
      );
    }

    final errorBody = res.body is Map ? res.body['error'] ?? res.body : res.statusText;
    final msg = errorBody is Map ? (errorBody['message'] ?? errorBody.toString()) : (errorBody?.toString() ?? "Visual search failed.");
    debugPrint("❌ [VISUAL SEARCH API ERROR] $msg (HTTP ${res.statusCode}). No fallback.");

    return VisualSearchResult(
      success: false,
      items: [],
      errorMessage: msg.toString(),
    );
  }

  VisualSearchResult _parseVisualResponse(dynamic body) {
    try {
      final map = body is Map ? body : {};
      final data = map['data'] is Map ? map['data'] : map;

      final searchId = data['searchId']?.toString();
      final query = data['query']?.toString();
      final generatedTitle = data['generatedTitle']?.toString();
      final imageUrl = data['image']?.toString() ?? data['imageUrl']?.toString();

      final analysis = data['queryImageAnalysis'] is Map ? data['queryImageAnalysis'] : (data['analysis'] is Map ? data['analysis'] : null);
      final probableBrand = analysis?['probableBrand']?.toString();
      final probableModel = analysis?['probableModel']?.toString();
      final probableReferenceNumber = analysis?['probableReferenceNumber']?.toString();
      final visualAttributes = analysis?['visualAttributes'] is Map ? Map<String, dynamic>.from(analysis['visualAttributes']) : null;

      // Items could be in results.items or directly in items
      List<dynamic> rawItems = [];
      if (data['results'] is Map && data['results']['items'] is List) {
        rawItems = data['results']['items'];
      } else if (data['items'] is List) {
        rawItems = data['items'];
      } else {
        final extracted = ApiClient.extractList(body);
        if (extracted != null) rawItems = extracted;
      }

      final items = rawItems
          .whereType<Map>()
          .map((item) => WatchModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      return VisualSearchResult(
        success: true,
        searchId: searchId,
        query: query,
        generatedTitle: generatedTitle,
        imageUrl: imageUrl,
        probableBrand: probableBrand,
        probableModel: probableModel,
        probableReferenceNumber: probableReferenceNumber,
        visualAttributes: visualAttributes,
        items: items,
      );
    } catch (e) {
      debugPrint("❌ [VISUAL SEARCH PARSE ERROR] $e");
      return VisualSearchResult(
        success: false,
        items: [],
        errorMessage: "Error parsing visual search results: $e",
      );
    }
  }

  Future<Map<String, dynamic>?> analyzeImage(List<int> imageBytes, String filename) async {
    final res = await _api.safeUpload(ApiEndpoints.aiAnalyzeImage, imageBytes, filename);
    if (res.isOk && res.body != null) {
      final body = res.body is Map ? res.body : {};
      return body['data'] is Map<String, dynamic> ? body['data'] : (body is Map<String, dynamic> ? body : null);
    }
    return null;
  }

  Future<List<Map<String, String>>> getRecentImageSearches() async {
    final res = await _api.safeGet(ApiEndpoints.imageSearchRecent);
    if (res.isOk && res.body != null) {
      final list = ApiClient.extractList(res.body);
      if (list != null) {
        final List<Map<String, String>> recents = [];
        for (final item in list) {
          if (item is Map) {
            final data = item['data'] is Map ? item['data'] : item;
            final query = (data['query'] ?? data['generatedTitle'] ?? '').toString();
            final title = (data['generatedTitle'] ?? data['query'] ?? 'Timepiece Scan').toString();
            final imageUrl = (data['imageUrl'] ?? data['image'] ?? '').toString();
            final id = (item['id'] ?? item['_id'] ?? '').toString();

            if (title.isNotEmpty || query.isNotEmpty) {
              recents.add({
                'name': title,
                'keyword': query.isNotEmpty ? query : title,
                'image': imageUrl.isNotEmpty ? imageUrl : 'assets/images/rolex_watch.png',
                if (id.isNotEmpty) 'searchId': id,
              });
            }
          }
        }
        return recents;
      }
    }
    return [];
  }
}