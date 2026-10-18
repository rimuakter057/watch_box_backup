import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/prefs/pref_manager.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/services/listings_api_service.dart';
import '../models/watch_model.dart';
import '../models/search_query_model.dart';
import 'auth_controller.dart';

class BookmarkController extends GetxController {
  final PrefManager _pref = Get.find<PrefManager>();
  final AuthController _auth = Get.find<AuthController>();

  ListingsApiService get _listingsApi {
    try {
      return Get.find<ListingsApiService>();
    } catch (_) {
      return ListingsApiService();
    }
  }

  ApiClient get _api {
    try {
      return ApiClient.to;
    } catch (_) {
      return Get.find<ApiClient>();
    }
  }

  final RxList<WatchModel> bookmarkedWatches = <WatchModel>[].obs;
  final RxList<SearchQueryModel> savedSearches = <SearchQueryModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_auth.currentUser, (user) {
      if (user != null) {
        fetchBookmarks();
        fetchSavedSearches();
      } else {
        bookmarkedWatches.clear();
        savedSearches.clear();
      }
    });
    
    if (_auth.currentUser.value != null) {
      fetchBookmarks();
      fetchSavedSearches();
    }
  }

  // 1. Fetch saved listings
  Future<void> fetchBookmarks() async {
    if (!_pref.hasToken) {
      debugPrint("❌ [BOOKMARKS ERROR] Cannot fetch saved products: User not authorized (no access token). No fallback.");
      bookmarkedWatches.clear();
      return;
    }

    isLoading.value = true;
    try {
      final liveSaved = await _listingsApi.getSavedPosts();
      if (liveSaved != null) {
        bookmarkedWatches.assignAll(liveSaved);
        debugPrint("✅ [BOOKMARKS CONTROLLER] Loaded ${liveSaved.length} bookmarked watches from backend API.");
      } else {
        debugPrint("❌ [BOOKMARKS ERROR] Failed to fetch saved products from backend / not authorized. No fallback.");
      }
    } catch (e) {
      debugPrint("❌ [BOOKMARKS ERROR] Live bookmarks error: $e. No fallback.");
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle Bookmark
  Future<void> toggleBookmark(WatchModel watch) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [BOOKMARKS ERROR] Cannot toggle bookmark: User not authorized (no access token). No fallback.");
      Get.snackbar("Authentication Required", "Please sign in to save items.");
      return;
    }

    final targetId = watch.idString;
    if (targetId.isEmpty) return;

    try {
      final success = await _listingsApi.toggleSave(targetId, watch: watch);
      if (!success) {
        debugPrint("❌ [BOOKMARKS ERROR] Backend toggle save rejected / not authorized for ${watch.title}. No fallback.");
        Get.snackbar("Error", "Could not update bookmark on server.");
        return;
      }

      final isSaved = isBookmarked(targetId);
      if (isSaved) {
        bookmarkedWatches.removeWhere((w) => w.idString == targetId || (w.id != null && w.id.toString() == targetId));
        Get.snackbar("Bookmark Removed", "Removed ${watch.title} from bookmarks.");
      } else {
        bookmarkedWatches.add(watch);
        Get.snackbar("Bookmark Saved", "Saved ${watch.title} to bookmarks.");
      }
      debugPrint("✅ [BOOKMARKS CONTROLLER] Bookmark toggled successfully on backend for watch #$targetId");
    } catch (e) {
      debugPrint("❌ [BOOKMARKS ERROR] Error toggling bookmark: $e. No fallback.");
    }
  }

  bool isBookmarked(dynamic listingId) {
    if (listingId == null) return false;
    final str = listingId.toString();
    if (str.isEmpty) return false;
    return bookmarkedWatches.any((w) => w.idString == str || (w.id != null && w.id.toString() == str));
  }

  // 2. Fetch saved searches
  Future<void> fetchSavedSearches() async {
    if (!_pref.hasToken) {
      debugPrint("❌ [BOOKMARKS ERROR] Cannot fetch saved searches: User not authorized (no access token). No fallback.");
      savedSearches.clear();
      return;
    }

    try {
      final res = await _api.safeGet(ApiEndpoints.savedSearches);
      if (res.isOk && res.body != null) {
        final list = ApiClient.extractList(res.body);
        if (list != null) {
          final items = list.whereType<Map>().map((m) {
            final id = m['id'] is int ? m['id'] as int : int.tryParse(m['id']?.toString() ?? '0') ?? 0;
            final queryText = (m['query'] ?? m['query_text'] ?? '').toString();
            final filters = m['filters'] is Map ? jsonEncode(m['filters']) : (m['filters_json']?.toString() ?? '{}');
            return SearchQueryModel(
              id: id,
              userId: _pref.activeUserId ?? 1,
              queryText: queryText,
              filtersJson: filters,
            );
          }).toList();
          savedSearches.assignAll(items);
          debugPrint("✅ [BOOKMARKS CONTROLLER] Loaded ${items.length} saved searches from backend API.");
          return;
        }
      }
      debugPrint("❌ [BOOKMARKS ERROR] Failed to fetch saved searches from backend / not authorized. No fallback.");
    } catch (e) {
      debugPrint("❌ [BOOKMARKS ERROR] Error fetching saved searches: $e. No fallback.");
    }
  }

  // Save Search Parameters
  Future<void> saveSearch(String query, Map<String, dynamic> filters) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [BOOKMARKS ERROR] Cannot save search: User not authorized (no access token). No fallback.");
      Get.snackbar("Authentication Required", "Please sign in to save searches.");
      return;
    }

    try {
      final res = await _api.safePost(ApiEndpoints.savedSearches, {
        'query': query,
        'filters': filters,
      });

      if (res.isOk) {
        final body = res.body is Map ? res.body : {};
        final data = body['data'] is Map ? body['data'] : body;
        final newId = data['id'] is int ? data['id'] as int : int.tryParse(data['id']?.toString() ?? '0') ?? DateTime.now().millisecondsSinceEpoch;
        
        savedSearches.add(SearchQueryModel(
          id: newId,
          userId: _pref.activeUserId ?? 1,
          queryText: query,
          filtersJson: jsonEncode(filters),
        ));
        debugPrint("✅ [BOOKMARKS CONTROLLER] Saved search created on backend with ID: $newId");
        Get.snackbar("Search Saved", "Your search query and filters have been saved.");
      } else {
        debugPrint("❌ [BOOKMARKS ERROR] Backend rejected saveSearch / not authorized. No fallback.");
        Get.snackbar("Error", "Could not save search on server.");
      }
    } catch (e) {
      debugPrint("❌ [BOOKMARKS ERROR] Error saving search: $e. No fallback.");
    }
  }

  // Remove Saved Search
  Future<void> removeSavedSearch(int savedSearchId) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [BOOKMARKS ERROR] Cannot remove saved search: User not authorized (no access token). No fallback.");
      return;
    }

    try {
      final res = await _api.safeDelete('${ApiEndpoints.savedSearches}/$savedSearchId');
      if (res.isOk) {
        savedSearches.removeWhere((s) => s.id == savedSearchId);
        debugPrint("✅ [BOOKMARKS CONTROLLER] Saved search $savedSearchId deleted on backend.");
        Get.snackbar("Search Removed", "Removed saved search.");
      } else {
        debugPrint("❌ [BOOKMARKS ERROR] Backend rejected delete saved search $savedSearchId. No fallback.");
      }
    } catch (e) {
      debugPrint("❌ [BOOKMARKS ERROR] Error deleting saved search: $e. No fallback.");
    }
  }
}
