import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../../controllers/search_controller.dart';
import '../../../models/watch_model.dart';
import 'watch_detail_screen.dart';

class TradersCollectionsScreen extends StatefulWidget {
  const TradersCollectionsScreen({super.key});

  @override
  State<TradersCollectionsScreen> createState() => _TradersCollectionsScreenState();
}

class _TradersCollectionsScreenState extends State<TradersCollectionsScreen> {
  final WatchSearchController _searchCtrl = Get.find<WatchSearchController>();
  String _selectedBrandFilter = 'All';
  List<WatchModel> _allTraderListings = [];
  List<WatchModel> _filteredListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
    });
    final listings = await _searchCtrl.getTraderListings();
    if (mounted) {
      setState(() {
        _allTraderListings = listings;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedBrandFilter == 'All') {
      _filteredListings = _allTraderListings;
    } else {
      _filteredListings = _allTraderListings
          .where((w) => w.brand.toLowerCase() == _selectedBrandFilter.toLowerCase())
          .toList();
    }
  }

  void _onFilterChanged(String brand) {
    setState(() {
      _selectedBrandFilter = brand;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brands = ['All', 'Rolex', 'Omega', 'Cartier', 'Patek Philippe'];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Traders Collections",
          style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.textPrimaryColor),
            onPressed: _loadListings,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Title subheader
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Text(
              "Browse and purchase luxury timepieces directly from certified peer collectors and private traders.",
              style: TextStyle(color: context.textSecondaryColor, fontSize: 13.sp, height: 1.4),
            ),
          ),

          // 2. Horizontal filter chips
          SizedBox(
            height: 38.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                final isSelected = _selectedBrandFilter == brand;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ChoiceChip(
                    label: Text(
                      brand,
                      style: TextStyle(
                        color: isSelected 
                            ? (context.isDarkTheme ? AppColors.backgroundDark : Colors.white) 
                            : context.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: context.primaryNav,
                    backgroundColor: context.chipBg,
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : context.borderColor,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                    onSelected: (val) {
                      if (val) _onFilterChanged(brand);
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),

          // 3. Grid of Listings
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(context.primaryNav),
                    ),
                  )
                : _filteredListings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront_rounded, 
                              size: 64.w, 
                              color: context.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "No active trader listings found",
                              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: context.textSecondaryColor),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14.w,
                          mainAxisSpacing: 14.h,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: _filteredListings.length,
                        itemBuilder: (context, index) {
                          final watch = _filteredListings[index];
                          return _buildWatchCard(watch);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchCard(WatchModel watch) {
    final formattedPrice = '\$${watch.price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';

    return GestureDetector(
      onTap: () async {
        // Navigate to watch detail screen and reload if return
        await Get.to(() => WatchDetailScreen(watch: watch));
        _loadListings();
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkTheme ? 0.25 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: context.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    padding: EdgeInsets.all(12.w),
                    child: Hero(
                      tag: 'watch-image-${watch.id}',
                      child: watch.imageUrl.startsWith('http')
                          ? Image.network(
                              watch.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'assets/images/8.png',
                                fit: BoxFit.contain,
                              ),
                            )
                          : Image.asset(
                              watch.imageUrl,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: watch.isSold 
                            ? const Color(0xFFEF4444) 
                            : const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        watch.isSold ? "SOLD" : "ACTIVE",
                        style: TextStyle(
                          fontSize: 9.sp, 
                          color: Colors.white, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: context.chipBg,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        watch.condition,
                        style: TextStyle(
                          fontSize: 8.sp, 
                          color: context.textSecondaryColor, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title & Info
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    watch.brand.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp, 
                      fontWeight: FontWeight.w900, 
                      color: context.textSecondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    watch.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp, 
                      fontWeight: FontWeight.w800, 
                      color: context.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedPrice,
                        style: TextStyle(
                          fontSize: 14.sp, 
                          fontWeight: FontWeight.w900, 
                          color: context.isDarkTheme ? const Color(0xFFF59E0B) : const Color(0xFFCA8A04),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 10.w, color: context.textSecondaryColor),
                          SizedBox(width: 2.w),
                          Text(
                            watch.location,
                            style: TextStyle(fontSize: 10.sp, color: context.textSecondaryColor),
                          ),
                        ],
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
