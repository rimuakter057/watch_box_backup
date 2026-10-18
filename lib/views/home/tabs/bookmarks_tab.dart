import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/bookmark_controller.dart';
import '../../../controllers/search_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/watch_model.dart';
import '../../../models/search_query_model.dart';
import '../watch_detail_screen.dart';
import '../../widgets/watch_background.dart';
import '../../../core/prefs/pref_manager.dart';
import '../../../core/network/api_client.dart';

class BookmarksTab extends StatefulWidget {
  const BookmarksTab({super.key});

  @override
  State<BookmarksTab> createState() => _BookmarksTabState();
}

class _BookmarksTabState extends State<BookmarksTab> with SingleTickerProviderStateMixin {
  final BookmarkController _bookmark = Get.find<BookmarkController>();
  final WatchSearchController _search = Get.find<WatchSearchController>();
  
  late TabController _tabController;
  
  // 'active' (Active Alerts) or 'all' (All Searches) Segment toggle matching the mockup
  String _searchSegment = 'active';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _runSavedSearch(SearchQueryModel sSearch) {
    final query = sSearch.queryText;
    final filters = sSearch.filters;

    _search.resetFilters();
    if (filters.containsKey('priceMin') && filters['priceMin'] != null) {
      _search.filterPriceMin.value = (filters['priceMin'] as num).toDouble();
    }
    if (filters.containsKey('priceMax') && filters['priceMax'] != null) {
      _search.filterPriceMax.value = (filters['priceMax'] as num).toDouble();
    }
    if (filters.containsKey('yearMin') && filters['yearMin'] != null) {
      _search.filterYearMin.value = filters['yearMin'] as int;
    }
    if (filters.containsKey('yearMax') && filters['yearMax'] != null) {
      _search.filterYearMax.value = filters['yearMax'] as int;
    }
    if (filters.containsKey('location')) {
      _search.filterLocation.value = filters['location'] as String;
    }
    if (filters.containsKey('condition')) {
      _search.filterCondition.value = filters['condition'] as String;
    }
    if (filters.containsKey('showSold')) {
      _search.filterShowSold.value = filters['showSold'] as bool;
    }

    _search.executeSearch(query);
    Get.snackbar(
      "Running Saved Search", 
      "Rerunning query with filters: '$query'",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: context.surfaceBg.withValues(alpha: 0.9),
      colorText: context.textPrimaryColor,
    );
  }

  // Toggle active alert on backend API
  Future<void> _toggleSavedSearchAlert(SearchQueryModel sSearch) async {
    final pref = Get.find<PrefManager>();
    if (!pref.hasToken) {
      debugPrint("❌ [BOOKMARKS ERROR] Cannot toggle alert notifications: User not authorized (no access token). No fallback.");
      Get.snackbar("Authentication Required", "Please sign in to manage search alerts.");
      return;
    }

    final filters = sSearch.filters;
    final bool current = filters['alertsEnabled'] ?? false;
    final endpoint = !current ? '/saved-searches/${sSearch.id}/alerts/enable' : '/saved-searches/${sSearch.id}/alerts/disable';
    
    final res = await ApiClient.to.safePost(endpoint, {});
    if (res.isOk) {
      _bookmark.fetchSavedSearches();
      Get.snackbar(
        "Alert State Toggled",
        !current ? "Push notifications enabled for this query." : "Push notifications muted.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      debugPrint("❌ [BOOKMARKS ERROR] Toggle saved search alerts rejected by backend / not authorized. No fallback.");
      Get.snackbar("Error", "Could not toggle alert on server.");
    }
  }

  // Options bottom sheet for saved search card
  void _showSavedSearchOptionsMenu(SearchQueryModel sSearch) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              sSearch.queryText,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryNav),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.search_rounded, color: context.primaryNav),
              title: Text("Run Search Query Now", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Get.back();
                _runSavedSearch(sSearch);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined, color: Colors.green),
              title: Text("Toggle Alert Notifications", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Get.back();
                _toggleSavedSearchAlert(sSearch);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text("Delete Saved Search", style: TextStyle(color: Colors.red)),
              onTap: () {
                if (sSearch.id != null) {
                  _bookmark.removeSavedSearch(sSearch.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saved Content", style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.primaryNav,
          unselectedLabelColor: context.textSecondaryColor,
          indicatorColor: context.primaryNav,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Saved Listings", icon: Icon(Icons.watch_rounded, size: 20)),
            Tab(text: "Saved Searches", icon: Icon(Icons.saved_search_rounded, size: 20)),
          ],
        ),
      ),
      body: WatchBackground(
        showGears: false,
        showDialTicks: true,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSavedListingsTab(),
            _buildSavedSearchesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedListingsTab() {
    return Obx(() {
      if (_bookmark.bookmarkedWatches.isEmpty) {
        return _buildEmptyState(
          icon: Icons.bookmark_border_rounded,
          title: "No saved listings",
          subtitle: "Bookmark watch listings during search to save them here for quick comparison.",
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _bookmark.bookmarkedWatches.length,
        itemBuilder: (context, idx) {
          final watch = _bookmark.bookmarkedWatches[idx];
          return _buildWatchListTile(watch);
        },
      );
    });
  }

  // Main list builder for saved searches, styled exactly like mockup
  Widget _buildSavedSearchesTab() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Saved Searches",
            style: TextStyle(
              fontSize: 26, 
              fontWeight: FontWeight.bold, 
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Track your favorite watch searches and get instant updates.",
            style: TextStyle(
              fontSize: 14, 
              color: context.textSecondaryColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          
          // Segmented Control Pill matching mockup
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.chipBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _searchSegment = 'active';
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _searchSegment == 'active' ? context.primaryNav : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Active Alerts",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _searchSegment == 'active' ? Colors.white : context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _searchSegment = 'all';
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _searchSegment == 'all' ? context.primaryNav : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "All Searches",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _searchSegment == 'all' ? Colors.white : context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // The list of items
          Expanded(
            child: Obx(() {
              final allList = _bookmark.savedSearches;
              final filteredList = _searchSegment == 'active'
                  ? allList.where((s) => s.filters['alertsEnabled'] == true).toList()
                  : allList;
                  
              if (filteredList.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.saved_search_rounded,
                  title: _searchSegment == 'active' ? "No active alerts" : "No saved searches",
                  subtitle: _searchSegment == 'active' 
                      ? "Enable price drop or new listing alerts in your saved searches to see them here."
                      : "Save search criteria and advanced filters to rerun them with a single tap.",
                );
              }
              
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filteredList.length,
                itemBuilder: (context, idx) {
                  final query = filteredList[idx];
                  return _buildSavedSearchTile(query);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.textSecondaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.textSecondaryColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchListTile(WatchModel watch) {
    final String watchUrl = watch.imageUrl;

    return Card(
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: () => Get.to(() => WatchDetailScreen(watch: watch)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: watchUrl.startsWith('http')
                    ? Image.network(
                        watchUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/8.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        watchUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: watch.platformColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            watch.platformAbbrev,
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: watch.platformColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          watch.condition,
                          style: TextStyle(fontSize: 10, color: context.textSecondaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      watch.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\$${watch.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                      style: TextStyle(fontWeight: FontWeight.w900, color: context.primaryNav, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.bookmark_rounded, color: context.primaryNav),
                onPressed: () => _bookmark.toggleBookmark(watch),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Saved Search Card matching mockup
  Widget _buildSavedSearchTile(SearchQueryModel sSearch) {
    final filters = sSearch.filters;
    
    // Parse platforms (default to empty list if none)
    final List<dynamic> platforms = filters['platforms'] ?? [];
    
    // Parse chips
    final List<dynamic> customChips = filters['chips'] ?? [];
    
    // Suffix metadata
    final String timeAgo = filters['timeAgo'] ?? 'Just now';
    final int matchesCount = filters['matchesCount'] ?? 0;
    
    // Alert status row
    final bool alertsEnabled = filters['alertsEnabled'] ?? false;
    final String alertStatusText = filters['alertStatus'] ?? 'Push Notifications Off';
    
    return Card(
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkTheme ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bottom Action Row or Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sSearch.queryText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.primaryNav,
                    ),
                  ),
                ),
                Icon(
                  Icons.bookmark_rounded,
                  color: context.primaryNav,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Wrap of chips: Platforms + Custom Filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Platforms Chips (light grey/slate)
                ...platforms.map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.chipBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: context.textSecondaryColor,
                    ),
                  ),
                )),
                
                // Custom Filter Chips (light blue/accent)
                ...customChips.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.isDarkTheme ? const Color(0xFF1E3A8A) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.toString(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: context.isDarkTheme ? const Color(0xFF93C5FD) : const Color(0xFF0284C7),
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 16),
            
            // Meta info row: Time ago + Matches
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: context.textSecondaryColor),
                const SizedBox(width: 6),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
                const SizedBox(width: 12),
                Text("|", style: TextStyle(color: context.borderColor)),
                const SizedBox(width: 12),
                Icon(Icons.list_alt_rounded, size: 14, color: context.textSecondaryColor),
                const SizedBox(width: 6),
                Text(
                  "$matchesCount matches",
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: context.borderColor),
            const SizedBox(height: 8),
            
            // Bottom Action Row: Alert Status + More Option button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: alertsEnabled ? const Color(0xFF10B981) : context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alertStatusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                
                // More Option Menu (dots_vertical)
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: context.textSecondaryColor),
                  onPressed: () => _showSavedSearchOptionsMenu(sSearch),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
