import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../controllers/search_controller.dart';
import '../../../models/watch_model.dart';
import '../../../core/theme/app_colors.dart';
import 'invoice_preview_screen.dart';
import '../widgets/create_listing_sheet.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  final WatchSearchController _searchCtrl = Get.find<WatchSearchController>();
  late TabController _tabController;

  List<WatchModel> _activeListings = [];
  List<WatchModel> _soldListings = [];
  Map<String, Map<String, dynamic>> _invoices = {}; // listingIdString -> invoiceMap
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllListings() async {
    setState(() {
      _isLoading = true;
    });

    final active = await _searchCtrl.getUserListings(isSold: false);
    final sold = await _searchCtrl.getUserListings(isSold: true);

    // Query invoices for sold listings
    final Map<String, Map<String, dynamic>> invoiceMap = {};
    for (var watch in sold) {
      final idStr = watch.idString;
      if (idStr.isNotEmpty) {
        final inv = await _searchCtrl.getInvoice(idStr);
        if (inv != null) {
          invoiceMap[idStr] = inv;
        }
      }
    }

    if (mounted) {
      setState(() {
        _activeListings = active;
        _soldListings = sold;
        _invoices = invoiceMap;
        _isLoading = false;
      });
    }
  }

  void _showAddListingSheet() {
    CreateListingSheet.show(context, onListingCreated: () {
      _loadAllListings();
      if (_tabController.index != 0) {
        _tabController.animateTo(0);
      }
    });
  }

  void _showGenerateInvoiceDialog(WatchModel watch) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          "Generate Billing Invoice",
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.primaryNav),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter the buyer details below. Standard invoice parameters will be auto-compiled.",
                style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: nameCtrl,
                style: TextStyle(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  labelText: "Buyer's Name",
                  labelStyle: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: emailCtrl,
                style: TextStyle(color: context.textPrimaryColor),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Buyer's Email",
                  labelStyle: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required";
                  if (!GetUtils.isEmail(value)) return "Invalid email address";
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel", style: TextStyle(color: context.textSecondaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryNav,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await _searchCtrl.generateInvoice(
                  listingId: watch.idString,
                  buyerName: nameCtrl.text.trim(),
                  buyerEmail: emailCtrl.text.trim(),
                  price: watch.price,
                );
                if (success) {
                  Get.back();
                  await _loadAllListings();
                  
                  // Instantly navigate to invoice preview
                  final inv = _invoices[watch.idString];
                  if (inv != null) {
                    Get.to(() => InvoicePreviewScreen(watch: watch, invoiceData: inv));
                  }
                }
              }
            },
            child: Text("Generate", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "My Listings",
          style: TextStyle(color: context.primaryNav, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primaryNav),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.primaryNav),
            onPressed: _loadAllListings,
            tooltip: "Refresh Listings",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.primaryNav,
          unselectedLabelColor: context.textSecondaryColor,
          indicatorColor: const Color(0xFFCA8A04),
          indicatorWeight: 3.0,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
          tabs: const [
            Tab(text: "Active Listings"),
            Tab(text: "Sold Listings"),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.primaryNav),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(),
                _buildSoldTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddListingSheet,
        backgroundColor: context.primaryNav,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_activeListings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAllListings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 60.h),
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell_outlined, size: 64.w, color: context.borderColor),
                  SizedBox(height: 16.h),
                  Text(
                    "You don't have any active listings",
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textSecondaryColor),
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: _showAddListingSheet,
                    child: const Text("Create Your First Listing", style: TextStyle(color: Color(0xFFCA8A04), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllListings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        itemCount: _activeListings.length,
        itemBuilder: (context, index) {
        final watch = _activeListings[index];
        final formattedPrice = '\$${watch.price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}';

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: context.borderColor, width: 1.5),
          ),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Image
                Container(
                  width: 56.w,
                  height: 56.h,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: context.chipBg,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: watch.imageUrl.startsWith('http')
                      ? Image.network(
                          watch.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/8.png',
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(watch.imageUrl, fit: BoxFit.contain),
                ),
                SizedBox(width: 14.w),
                // Title and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        watch.brand.toUpperCase(),
                        style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w900, color: const Color(0xFFCA8A04)),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        watch.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "Year: ${watch.year} • ${watch.condition} • ${watch.location}",
                        style: TextStyle(fontSize: 10.sp, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                // Price
                Text(
                  formattedPrice,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: context.primaryNav),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoldTab() {
    if (_soldListings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAllListings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 60.h),
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64.w, color: context.borderColor),
                  SizedBox(height: 16.h),
                  Text(
                    "No sold listings yet",
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllListings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        itemCount: _soldListings.length,
        itemBuilder: (context, index) {
        final watch = _soldListings[index];
        final invoice = _invoices[watch.idString];
        final hasInvoice = invoice != null;

        final formattedPrice = '\$${watch.price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}';

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: context.borderColor, width: 1.5),
          ),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                Row(
                  children: [
                    // Image
                    Container(
                      width: 56.w,
                      height: 56.h,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: context.chipBg,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: watch.imageUrl.startsWith('http')
                          ? Image.network(
                              watch.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'assets/images/8.png',
                                fit: BoxFit.contain,
                              ),
                            )
                          : Image.asset(watch.imageUrl, fit: BoxFit.contain),
                    ),
                    SizedBox(width: 14.w),
                    // Title and Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            watch.brand.toUpperCase(),
                            style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w900, color: const Color(0xFFEF4444)),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            watch.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Sold for: $formattedPrice",
                            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Divider(height: 1, color: context.borderColor),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (hasInvoice) ...[
                      Text(
                        "Invoice generated",
                        style: TextStyle(fontSize: 11.sp, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 12.w),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryNav,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        ),
                        onPressed: () {
                          Get.to(() => InvoicePreviewScreen(watch: watch, invoiceData: invoice));
                        },
                        child: Text("View Invoice", style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      Text(
                        "Billing details pending",
                        style: TextStyle(fontSize: 11.sp, color: const Color(0xFFEF4444), fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 12.w),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCA8A04),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        ),
                        onPressed: () => _showGenerateInvoiceDialog(watch),
                        child: Text("Generate Invoice", style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
