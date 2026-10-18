
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/db/db_helper.dart';
import '../core/prefs/pref_manager.dart';
import '../core/theme/app_colors.dart';
import '../models/watch_model.dart';
import 'auth_controller.dart';
import 'alert_controller.dart';
import '../core/network/services/search_api_service.dart';
import '../core/network/services/listings_api_service.dart';

class WatchSearchController extends GetxController {
  final DbHelper _dbHelper = DbHelper();
  final PrefManager _pref = Get.find<PrefManager>();
  final AuthController _auth = Get.find<AuthController>();

  SearchApiService get _searchApi {
    try {
      return Get.find<SearchApiService>();
    } catch (_) {
      return SearchApiService();
    }
  }

  ListingsApiService get _listingsApi {
    try {
      return Get.find<ListingsApiService>();
    } catch (_) {
      return ListingsApiService();
    }
  }

  final RxList<WatchModel> searchResults = <WatchModel>[].obs;
  final RxList<Map<String, dynamic>> searchHistory = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  // Search limit tracking
  final RxInt monthlySearchCount = 0.obs;
  final int maxFreeSearches = 5;

  // Active Search Parameters
  final RxString queryText = ''.obs;
  
  // Platform selection (checked chips)
  final RxBool searchEbay = true.obs;
  final RxBool searchChrono24 = true.obs;
  final RxBool searchGrailzee = true.obs;

  // Filter values
  final RxnInt filterYearMin = RxnInt();
  final RxnInt filterYearMax = RxnInt();
  final RxnDouble filterPriceMin = RxnDouble();
  final RxnDouble filterPriceMax = RxnDouble();
  final RxString filterLocation = ''.obs; // 'USA', 'Germany', etc.
  final RxString filterCondition = ''.obs; // 'New', 'Very Good', etc.
  final RxBool filterShowSold = false.obs; // false = Active only, true = Sold only
  final RxString filterTimeRange = 'All Time'.obs; // 'All Time', '30 Days', '90 Days'

  // Image search simulator
  final RxString simulatedImagePath = ''.obs;

  // Analytics outputs for selected search/watch
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 0.0.obs;
  final RxDouble avgPrice = 0.0.obs;
  final RxList<double> priceTrendData = <double>[].obs; // Data points for painter chart

  @override
  void onInit() {
    super.onInit();
    loadSearchHistory();
    checkSearchLimit();
  }

  // Count search queries done by this user in the current calendar month
  Future<void> checkSearchLimit() async {
    final user = _auth.currentUser.value;
    if (user == null || user.id == null) return;
    
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      // Start of current month date string
      final firstOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      
      final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM search_history WHERE user_id = ? AND timestamp >= ?",
        [user.id, firstOfMonth]
      );
      
      if (result.isNotEmpty) {
        monthlySearchCount.value = result.first['count'] as int;
      } else {
        monthlySearchCount.value = 0;
      }
    } catch (e) {
      print("Error checking search limit: $e");
    }
  }

  // Load user's search history
  Future<void> loadSearchHistory() async {
    final user = _auth.currentUser.value;
    if (user == null || user.id == null) return;

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'search_history',
        where: 'user_id = ?',
        whereArgs: [user.id],
        orderBy: 'timestamp DESC',
        limit: 10,
      );
      searchHistory.assignAll(maps);
    } catch (e) {
      print("Error loading search history: $e");
    }
  }

  // Add search query to history
  Future<void> _logSearch(String query) async {
    final user = _auth.currentUser.value;
    if (user == null || user.id == null || query.trim().isEmpty) return;

    try {
      final db = await _dbHelper.database;
      await db.insert('search_history', {
        'user_id': user.id,
        'query_text': query,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await loadSearchHistory();
      await checkSearchLimit();
    } catch (e) {
      print("Error logging search: $e");
    }
  }

  // Clear Search History
  Future<void> clearHistory() async {
    final user = _auth.currentUser.value;
    if (user == null || user.id == null) return;

    try {
      final db = await _dbHelper.database;
      await db.delete(
        'search_history',
        where: 'user_id = ?',
        whereArgs: [user.id],
      );
      searchHistory.clear();
    } catch (e) {
      print("Error clearing history: $e");
    }
  }

  // Execute Aggregated Search
  Future<bool> executeSearch(String keyword, {bool isImageSearch = false}) async {
    final user = _auth.currentUser.value;
    if (user == null) return false;

    // 1. Check free limit
    if (user.plan == 'free' && !user.isAdmin) {
      await checkSearchLimit();
      if (monthlySearchCount.value >= maxFreeSearches) {
        Get.dialog(
          GetPlatform.isAndroid || GetPlatform.isIOS 
          ? _buildUpgradeDialog() 
          : _buildUpgradeDialog(),
          barrierDismissible: true,
        );
        return false;
      }
    }

    isLoading.value = true;
    queryText.value = keyword;

    // 1. Live Backend Search with graceful fallback
    try {
      List<String> activePlatforms = [];
      if (searchEbay.value && _pref.ebayEnabled) activePlatforms.add('eBay');
      if (searchChrono24.value && _pref.chrono24Enabled) activePlatforms.add('Chrono24');
      if (searchGrailzee.value && _pref.grailzeeEnabled) activePlatforms.add('Grailzee');

      if (activePlatforms.isEmpty) {
        searchResults.clear();
        _calculateAnalytics([]);
        isLoading.value = false;
        return true;
      }

      final liveResults = await _searchApi.search(
        query: keyword,
        minPrice: filterPriceMin.value,
        maxPrice: filterPriceMax.value,
        yearMin: filterYearMin.value,
        yearMax: filterYearMax.value,
        platforms: activePlatforms,
      );

      if (liveResults != null && liveResults.isNotEmpty) {
        searchResults.assignAll(liveResults);
        _calculateAnalytics(liveResults);
        await _logSearch(keyword);
        isLoading.value = false;
        return true;
      }
    } catch (e) {
      print("Live search fallback to SQLite: ");
    }

    try {
      final db = await _dbHelper.database;
      
      // Build search query with filters
      String query = "SELECT * FROM listings WHERE 1=1";
      List<dynamic> arguments = [];

      // Keyword search
      if (keyword.isNotEmpty) {
        query += " AND (title LIKE ? OR brand LIKE ? OR model LIKE ?)";
        arguments.add('%$keyword%');
        arguments.add('%$keyword%');
        arguments.add('%$keyword%');
      }

      // Platforms filter (eBay, Chrono24, Grailzee)
      // Checks both checking status & admin disable toggles
      List<String> activePlatforms = [];
      if (searchEbay.value && _pref.ebayEnabled) activePlatforms.add('eBay');
      if (searchChrono24.value && _pref.chrono24Enabled) activePlatforms.add('Chrono24');
      if (searchGrailzee.value && _pref.grailzeeEnabled) activePlatforms.add('Grailzee');

      if (activePlatforms.isEmpty) {
        searchResults.clear();
        _calculateAnalytics([]);
        isLoading.value = false;
        return true;
      }

      query += " AND platform IN (${activePlatforms.map((p) => '?').join(', ')})";
      arguments.addAll(activePlatforms);

      // Advanced Filters
      // 1. Year filters (Free plan only has basic filters, so year/condition filters are ignored if user is free, mimicking premium lock)
      final bool hasAdvancedFilter = user.plan == 'paid' || user.isAdmin;
      
      if (hasAdvancedFilter) {
        if (filterYearMin.value != null) {
          query += " AND year >= ?";
          arguments.add(filterYearMin.value);
        }
        if (filterYearMax.value != null) {
          query += " AND year <= ?";
          arguments.add(filterYearMax.value);
        }
        if (filterLocation.value.isNotEmpty) {
          query += " AND location = ?";
          arguments.add(filterLocation.value);
        }
        if (filterCondition.value.isNotEmpty) {
          query += " AND condition = ?";
          arguments.add(filterCondition.value);
        }
        if (filterTimeRange.value != 'All Time') {
          final days = filterTimeRange.value == '30 Days' ? 30 : 90;
          final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
          query += " AND timestamp >= ?";
          arguments.add(cutoff);
        }
      }

      // 2. Sold vs Active filter (also an advanced filter)
      if (hasAdvancedFilter) {
        query += " AND is_sold = ?";
        arguments.add(filterShowSold.value ? 1 : 0);
      } else {
        // Free users always see Active listings only
        query += " AND is_sold = 0";
      }

      // 3. Price Filter
      if (filterPriceMin.value != null) {
        query += " AND price >= ?";
        arguments.add(filterPriceMin.value);
      }
      if (filterPriceMax.value != null) {
        query += " AND price <= ?";
        arguments.add(filterPriceMax.value);
      }

      final List<Map<String, dynamic>> resultsMaps = await db.rawQuery(query, arguments);
      final List<WatchModel> fetchedList = resultsMaps.map((map) => WatchModel.fromMap(map)).toList();

      searchResults.assignAll(fetchedList);
      _calculateAnalytics(fetchedList);

      // Log the search
      await _logSearch(keyword);

      return true;
    } catch (e) {
      print("Search query failed: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Reset Filters
  void resetFilters() {
    filterYearMin.value = null;
    filterYearMax.value = null;
    filterPriceMin.value = null;
    filterPriceMax.value = null;
    filterLocation.value = '';
    filterCondition.value = '';
    filterShowSold.value = false;
    filterTimeRange.value = 'All Time';
  }

  // Calculate pricing insights based on listings
  void _calculateAnalytics(List<WatchModel> list) {
    if (list.isEmpty) {
      minPrice.value = 0.0;
      maxPrice.value = 0.0;
      avgPrice.value = 0.0;
      priceTrendData.clear();
      return;
    }

    double min = double.infinity;
    double max = 0.0;
    double sum = 0.0;

    for (var w in list) {
      if (w.price < min) min = w.price;
      if (w.price > max) max = w.price;
      sum += w.price;
    }

    minPrice.value = min == double.infinity ? 0.0 : min;
    maxPrice.value = max;
    avgPrice.value = sum / list.length;

    // Simulate trend chart points. Let's create a smooth dataset around the average
    // to render the gorgeous CustomPainter trend line.
    final basePrice = avgPrice.value;
    if (basePrice > 0) {
      priceTrendData.assignAll([
        basePrice * 0.92,
        basePrice * 0.94,
        basePrice * 0.91,
        basePrice * 0.98,
        basePrice * 1.05,
        basePrice * 1.02,
        basePrice * 1.10,
        basePrice * 1.08,
        basePrice * 1.12,
      ]);
    } else {
      priceTrendData.clear();
    }
  }

  // Simulated Image Search Action
  Future<void> runSimulatedImageSearch(String brand) async {
    simulatedImagePath.value = "assets/images/watches/${brand.toLowerCase()}.jpg";
    await executeSearch(brand, isImageSearch: true);
  }

  // Custom UI Dialog for Plan Upgrade
  Widget _buildUpgradeDialog() {
    return androidxUpgradeDialogMock();
  }

  Widget androidxUpgradeDialogMock() {
    return GetPlatform.isIOS 
    ? _cupertinoStyleDialog() 
    : _materialStyleDialog();
  }

  Widget _materialStyleDialog() {
    importMaterial();
    return Get.context != null ? dialogWidget() : const SizedBox();
  }

  void importMaterial() {}

  Widget dialogWidget() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.stars_rounded,
              color: AppColors.accent,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              "Upgrade to Premium",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "You have reached the monthly search limit (5 searches/month) for the Free Plan. Upgrade to access unlimited searches, advanced filters, price drop tracking, and full market index analysis.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Maybe Later"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _auth.upgradePlan();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Upgrade \$29/mo"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _cupertinoStyleDialog() {
    return dialogWidget(); // Simplified standard fallback dialogue
  }

  // ==========================================
  // TRANSACTION / PEER-TO-PEER MARKETPLACE ACTIONS
  // ==========================================

  Future<List<WatchModel>> getTraderListings() async {
    try {
      final liveList = await _listingsApi.getTraderCollections();
      if (liveList != null && liveList.isNotEmpty) {
        return liveList;
      }
    } catch (e) {
      print("Live trader listings fallback to SQLite: ");
    }
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'listings',
        where: 'platform = ? AND is_sold = 0',
        whereArgs: ['In-App'],
        orderBy: 'timestamp DESC',
      );
      return maps.map((map) => WatchModel.fromMap(map)).toList();
    } catch (e) {
      print("Error loading trader listings: $e");
      return [];
    }
  }

  Future<List<WatchModel>> getUserListings({required bool isSold}) async {
    try {
      final liveList = await _listingsApi.getMyListings(status: isSold ? 'sold' : 'active');
      if (liveList != null && liveList.isNotEmpty) {
        return liveList;
      }
    } catch (e) {
      print("Live user listings fallback to SQLite: ");
    }
    final user = _auth.currentUser.value;
    if (user == null || user.id == null) return [];
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'listings',
        where: 'user_id = ? AND is_sold = ?',
        whereArgs: [user.id, isSold ? 1 : 0],
        orderBy: 'timestamp DESC',
      );
      return maps.map((map) => WatchModel.fromMap(map)).toList();
    } catch (e) {
      print("Error loading user listings: $e");
      return [];
    }
  }

  Future<bool> createCustomListing({
    required String brand,
    required String model,
    required String title,
    required double price,
    required int year,
    required String condition,
    required String location,
  }) async {
    final user = _auth.currentUser.value;
    if (user == null || user.id == null) return false;

    try {
      await _listingsApi.createListing({
        'brand': brand,
        'model': model,
        'title': title,
        'price': price,
        'year': year,
        'condition': condition,
        'location': location,
        'platform': 'In-App',
      });
    } catch (e) {
      print("Backend createListing sync failed: ");
    }

    try {
      final db = await _dbHelper.database;
      await db.insert('listings', {
        'user_id': user.id,
        'title': title,
        'brand': brand,
        'model': model,
        'price': price,
        'platform': 'In-App',
        'year': year,
        'condition': condition,
        'location': location,
        'is_sold': 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print("Error creating custom listing: $e");
      return false;
    }
  }

  Future<bool> buyListing(WatchModel watch, String buyerName) async {
    if (watch.id == null) return false;
    try {
      // 1. Live backend purchase & mark sold
      try {
        await _listingsApi.purchaseListing(watch.id.toString(), price: watch.price, buyerName: buyerName);
        await _listingsApi.markListingSold(watch.id.toString());
      } catch (e) {
        print("Backend purchase sync: $e");
      }

      final db = await _dbHelper.database;
      
      // 1. Mark listing as sold
      await db.update(
        'listings',
        {'is_sold': 1},
        where: 'id = ?',
        whereArgs: [watch.id],
      );
      
      // 2. Generate system alert/notification for the seller
      if (watch.userId != null) {
        final nowStr = DateTime.now().toIso8601String();
        await db.insert('alerts', {
          'user_id': watch.userId,
          'type': 'sold_notification',
          'message': 'Congrats! Your listing "${watch.title}" has been purchased by $buyerName.',
          'timestamp': nowStr,
          'is_read': 0,
        });
        
        // Trigger refresh on AlertController if active
        try {
          final alertCtrl = Get.find<AlertController>();
          alertCtrl.fetchAlerts();
        } catch (_) {}
      }
      
      return true;
    } catch (e) {
      print("Error purchasing listing: $e");
      return false;
    }
  }

  Future<bool> generateInvoice({
    required int listingId,
    required String buyerName,
    required String buyerEmail,
    required double price,
  }) async {
    try {
      final db = await _dbHelper.database;
      final invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      
      await db.insert('invoices', {
        'listing_id': listingId,
        'buyer_name': buyerName,
        'buyer_email': buyerEmail,
        'invoice_no': invoiceNo,
        'date': dateStr,
        'price': price,
      });
      return true;
    } catch (e) {
      print("Error generating invoice: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getInvoice(int listingId) async {
    try {
      // 1. Live API invoice fetch
      try {
        final liveInvoice = await _listingsApi.getInvoice(listingId.toString());
        if (liveInvoice != null && liveInvoice.isNotEmpty) return liveInvoice;
      } catch (_) {}

      // 2. Local fallback
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'invoices',
        where: 'listing_id = ?',
        whereArgs: [listingId],
        limit: 1,
      );
      if (maps.isNotEmpty) return maps.first;
      return null;
    } catch (e) {
      print("Error loading invoice: $e");
      return null;
    }
  }
}
