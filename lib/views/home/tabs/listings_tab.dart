import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/search_controller.dart';
import '../../../core/network/services/listings_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/watch_model.dart';
import '../../widgets/watch_background.dart';
import '../../widgets/create_listing_sheet.dart';
import '../watch_detail_screen.dart';
import '../../chat/chat_screen.dart';
import '../../chat/conversations_screen.dart';

class ListingsTab extends StatefulWidget {
  final int initialTabIndex;

  const ListingsTab({super.key, this.initialTabIndex = 0});

  @override
  State<ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<ListingsTab> with SingleTickerProviderStateMixin {
  final ListingsApiService _listingsApi = Get.find<ListingsApiService>();
  final WatchSearchController _searchCtrl = Get.find<WatchSearchController>();
  final AuthController _auth = Get.find<AuthController>();

  late TabController _tabController;
  final TextEditingController _searchFieldController = TextEditingController();

  final RxList<WatchModel> _allListings = <WatchModel>[].obs;
  final RxList<WatchModel> _inAppListings = <WatchModel>[].obs;

  final RxBool _isLoadingAll = true.obs;
  final RxBool _isLoadingInApp = true.obs;

  String _selectedBrand = 'All';
  String _searchQuery = '';

  final List<String> _brands = ['All', 'Rolex', 'Omega', 'Patek Philippe', 'Audemars Piguet', 'Cartier'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchAllListings();
    _fetchInAppListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFieldController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllListings() async {
    _isLoadingAll.value = true;
    try {
      final list = await _listingsApi.getListings(page: 1, limit: 50);
      if (list != null) {
        _allListings.assignAll(list.where((w) => !w.isSold).toList());
      } else {
        _allListings.clear();
      }
    } catch (e) {
      debugPrint("❌ [LISTINGS TAB] Error fetching all listings: $e");
      _allListings.clear();
    } finally {
      _isLoadingAll.value = false;
    }
  }

  Future<void> _fetchInAppListings() async {
    _isLoadingInApp.value = true;
    try {
      final List<WatchModel> combined = [];
      final Set<String> seenIds = {};

      // 1. Live community in-app listings from /listings (includes newly created listings)
      final all = await _listingsApi.getListings(page: 1, limit: 50);
      if (all != null && all.isNotEmpty) {
        for (final w in all) {
          if (w.isInApp && !w.isEbay && !w.isSold) {
            final id = w.idString;
            if (id.isNotEmpty) {
              if (!seenIds.contains(id)) {
                seenIds.add(id);
                combined.add(w);
              }
            } else {
              combined.add(w);
            }
          }
        }
      }

      // 2. Peer trader collections
      final traders = await _listingsApi.getTraderCollections();
      if (traders != null && traders.isNotEmpty) {
        for (final w in traders) {
          if (w.isInApp && !w.isEbay && !w.isSold) {
            final id = w.idString;
            if (id.isNotEmpty) {
              if (!seenIds.contains(id)) {
                seenIds.add(id);
                combined.add(w);
              }
            } else {
              combined.add(w);
            }
          }
        }
      }

      _inAppListings.assignAll(combined);
    } catch (e) {
      debugPrint("❌ [LISTINGS TAB] Error fetching in-app listings: $e");
      _inAppListings.clear();
    } finally {
      _isLoadingInApp.value = false;
    }
  }

  List<WatchModel> _filterList(List<WatchModel> source) {
    return source.where((w) {
      final matchesBrand = _selectedBrand == 'All' ||
          w.brand.toLowerCase().contains(_selectedBrand.toLowerCase());
      final matchesQuery = _searchQuery.isEmpty ||
          w.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          w.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          w.model.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesBrand && matchesQuery;
    }).toList();
  }

  void _showBuyConfirmation(WatchModel watch) {
    final buyerName = _auth.currentUser.value?.name ?? "Buyer";

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, MediaQuery.of(context).padding.bottom + 24.h),
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Text(
              "Purchase Timepiece",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.primaryNav),
            ),
            SizedBox(height: 8.h),
            Text(
              "Purchase directly via the WatchBox order API. A purchase order will be created and payment confirmed on the backend.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5.sp, color: context.textSecondaryColor, height: 1.4),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.chipBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      width: 52.w,
                      height: 52.h,
                      color: context.surfaceBg,
                      child: watch.imageUrl.startsWith('http')
                          ? Image.network(watch.imageUrl, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => Image.asset('assets/images/8.png', fit: BoxFit.cover))
                          : Image.asset(watch.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          watch.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "\$${watch.price.toStringAsFixed(0)} USD",
                          style: TextStyle(fontSize: 13.sp, color: const Color(0xFFD97706), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryNav,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 0,
                ),
                onPressed: () async {
                  Get.back();
                  Get.showOverlay(
                    asyncFunction: () async {
                      await _searchCtrl.buyListing(watch, buyerName);
                    },
                    loadingWidget: Center(
                      child: Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(color: context.surfaceBg, borderRadius: BorderRadius.circular(16.r)),
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(context.primaryNav)),
                      ),
                    ),
                  ).then((_) {
                    _fetchInAppListings();
                    _fetchAllListings();
                  });
                },
                child: Text("Confirm Purchase", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openSellerChat(WatchModel watch) {
    final sellerId = watch.ownerId ?? watch.userId?.toString() ?? watch.idString;
    final sellerTitle = watch.ownerName != null ? "Seller • ${watch.ownerName}" : "Seller • ${watch.brand} ${watch.model}";
    Get.to(() => ChatScreen(
      chatId: "seller_${sellerId.isNotEmpty ? sellerId : watch.brand.toLowerCase()}",
      title: sellerTitle,
      subtitle: "\$${watch.price.toStringAsFixed(0)} ${watch.currency} • ${watch.platform}",
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: WatchBackground(
        showDialTicks: true,
        showGears: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Watch Listings",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Verified timepiece marketplace & in-app inventory",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.chat_bubble_outline_rounded, color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C)),
                          onPressed: () => Get.to(() => const ConversationsScreen()),
                          tooltip: "Dealer & Seller Messages",
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh_rounded, color: context.isDarkTheme ? Colors.white70 : const Color(0xFF07274C)),
                          onPressed: () {
                            _fetchAllListings();
                            _fetchInAppListings();
                          },
                          tooltip: "Refresh Listings",
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded, color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C)),
                          onPressed: () {
                            CreateListingSheet.show(context, onListingCreated: () {
                              _fetchInAppListings();
                              _fetchAllListings();
                              if (_tabController.index != 1) {
                                _tabController.animateTo(1);
                              }
                            });
                          },
                          tooltip: "List a Timepiece",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search Input Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor, width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchFieldController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: "Filter by brand, model, or reference...",
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchFieldController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Brand Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _brands.map((b) {
                    final isSelected = _selectedBrand == b;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBrand = b;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF07274C)
                                : (context.isDarkTheme ? AppColors.surfaceDark : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF07274C) : context.borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            b,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : context.textPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Segmented Tabs: "All Listings" vs "In-App Listings"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF07274C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: "All Listings"),
                      Tab(text: "In-App Listings"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListingsView(_allListings, _isLoadingAll, _fetchAllListings, isInAppTab: false),
                    _buildListingsView(_inAppListings, _isLoadingInApp, _fetchInAppListings, isInAppTab: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          CreateListingSheet.show(context, onListingCreated: () {
            _fetchInAppListings();
            _fetchAllListings();
            if (_tabController.index != 1) {
              _tabController.animateTo(1);
            }
          });
        },
        backgroundColor: context.primaryNav,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          "List Watch",
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildListingsView(
    RxList<WatchModel> source,
    RxBool loading,
    Future<void> Function() onRefresh, {
    required bool isInAppTab,
  }) {
    return Obx(() {
      if (loading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final filtered = _filterList(source);

      if (filtered.isEmpty) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: context.textSecondaryColor),
                      const SizedBox(height: 14),
                      Text(
                        isInAppTab ? "No In-App Listings Found" : "No Listings Available",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isInAppTab
                            ? "There are currently no peer trader listings. Pull to refresh or create your own listing."
                            : "No active marketplace listings match your query. Pull to refresh from server.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: context.textSecondaryColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final watch = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: _buildListingCard(watch, isInAppTab: isInAppTab),
            );
          },
        ),
      );
    });
  }

  Widget _buildListingCard(WatchModel watch, {required bool isInAppTab}) {
    final bool isEbay = watch.isEbay;
    final bool isInApp = !isEbay && (watch.isInApp || isInAppTab);
    final bool isSold = watch.isSold;

    return InkWell(
      onTap: () => Get.to(() => WatchDetailScreen(watch: watch)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 90,
                height: 90,
                color: context.isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                child: watch.imageUrl.startsWith('http')
                    ? Image.network(
                        watch.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Image.asset('assets/images/8.png', fit: BoxFit.cover),
                      )
                    : Image.asset(watch.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Platform Badge (Explicitly distinguishes eBay Marketplace vs In-App Listing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isEbay
                              ? const Color(0xFF0064D2).withValues(alpha: 0.12)
                              : (isInApp
                                  ? const Color(0xFFD97706).withValues(alpha: 0.15)
                                  : watch.platformColor.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isEbay
                                ? const Color(0xFF0064D2).withValues(alpha: 0.3)
                                : (isInApp
                                    ? const Color(0xFFD97706).withValues(alpha: 0.3)
                                    : watch.platformColor.withValues(alpha: 0.3)),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEbay
                                  ? Icons.shopping_bag_outlined
                                  : (isInApp ? Icons.verified_rounded : Icons.public_rounded),
                              size: 11,
                              color: isEbay
                                  ? const Color(0xFF0064D2)
                                  : (isInApp ? const Color(0xFFD97706) : watch.platformColor),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isEbay
                                  ? "EBAY MARKETPLACE"
                                  : (isInApp ? "IN-APP LISTING" : watch.platform.toUpperCase()),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isEbay
                                    ? const Color(0xFF0064D2)
                                    : (isInApp ? const Color(0xFFD97706) : watch.platformColor),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (watch.referenceNumber != null && watch.referenceNumber!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Text(
                            "Ref. ${watch.referenceNumber}",
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                        ),
                      if (isSold)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "SOLD",
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    watch.brand,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    watch.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$${watch.price.toStringAsFixed(0)} ${watch.currency}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Actions: Chat with Seller, Buy Watch (In-App), or View on eBay
                  Row(
                    children: [
                      // Chat with Seller Button
                      InkWell(
                        onTap: () => _openSellerChat(watch),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF07274C)),
                              SizedBox(width: 4),
                              Text(
                                "Chat",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF07274C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Buy Watch Button (for in-app listings)
                      if (isInApp)
                        InkWell(
                          onTap: isSold ? null : () => _showBuyConfirmation(watch),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSold
                                  ? Colors.grey.shade400
                                  : const Color(0xFF07274C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSold ? Icons.lock_outline_rounded : Icons.shopping_bag_outlined,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSold ? "Sold" : "Buy Watch",
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // eBay Action Button
                      if (isEbay)
                        InkWell(
                          onTap: () => Get.to(() => WatchDetailScreen(watch: watch)),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0064D2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "eBay",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
