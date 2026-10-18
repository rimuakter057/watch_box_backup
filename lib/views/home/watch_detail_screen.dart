import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/bookmark_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/search_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/watch_model.dart';
import '../widgets/custom_chart.dart';
import '../chat/chat_screen.dart';

class WatchDetailScreen extends StatefulWidget {
  final WatchModel watch;

  const WatchDetailScreen({super.key, required this.watch});

  @override
  State<WatchDetailScreen> createState() => _WatchDetailScreenState();
}

class _WatchDetailScreenState extends State<WatchDetailScreen>
    with TickerProviderStateMixin {
  final BookmarkController _bookmark = Get.find<BookmarkController>();
  final AuthController _auth = Get.find<AuthController>();
  final WatchSearchController _search = Get.find<WatchSearchController>();

  late ScrollController _scrollController;
  late AnimationController _staggerController;
  late AnimationController _pulseController;
  late AnimationController _priceCounterController;

  // Stagger animations for each section
  late Animation<double> _heroFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _priceSlide;
  late Animation<double> _priceFade;
  late Animation<Offset> _specsSlide;
  late Animation<double> _specsFade;
  late Animation<Offset> _dealerSlide;
  late Animation<double> _dealerFade;
  late Animation<Offset> _analyticsSlide;
  late Animation<double> _analyticsFade;
  late Animation<Offset> _descSlide;
  late Animation<double> _descFade;
  late Animation<Offset> _similarSlide;
  late Animation<double> _similarFade;

  // Pulse for CTA button glow
  late Animation<double> _pulseAnimation;

  // Price counter animation
  late Animation<double> _priceCountAnimation;

  double _imageParallaxOffset = 0;
  bool _isDescExpanded = false;
  bool _isSoldLocal = false;

  @override
  void initState() {
    super.initState();
    _isSoldLocal = widget.watch.isSold;
    _scrollController = ScrollController()..addListener(_onScroll);

    // Main stagger controller
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Pulse for CTA glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Price counter
    _priceCounterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _priceCountAnimation = CurvedAnimation(
      parent: _priceCounterController,
      curve: Curves.easeOutCubic,
    );

    // Build staggered animations
    _heroFade = _buildFade(0.0, 0.2);
    _titleSlide = _buildSlide(0.1, 0.35);
    _titleFade = _buildFade(0.1, 0.35);
    _priceSlide = _buildSlide(0.18, 0.42);
    _priceFade = _buildFade(0.18, 0.42);
    _specsSlide = _buildSlide(0.25, 0.50);
    _specsFade = _buildFade(0.25, 0.50);
    _dealerSlide = _buildSlide(0.32, 0.58);
    _dealerFade = _buildFade(0.32, 0.58);
    _analyticsSlide = _buildSlide(0.38, 0.65);
    _analyticsFade = _buildFade(0.38, 0.65);
    _descSlide = _buildSlide(0.45, 0.72);
    _descFade = _buildFade(0.45, 0.72);
    _similarSlide = _buildSlide(0.52, 0.80);
    _similarFade = _buildFade(0.52, 0.80);

    _staggerController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _priceCounterController.forward();
    });
  }

  Animation<double> _buildFade(double begin, double end) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: Curves.easeOut),
      ),
    );
  }

  Animation<Offset> _buildSlide(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  void _onScroll() {
    setState(() {
      _imageParallaxOffset = _scrollController.offset * 0.4;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _staggerController.dispose();
    _pulseController.dispose();
    _priceCounterController.dispose();
    super.dispose();
  }

  String _formatPrice(double val) {
    return '\$${val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';
  }

  Future<void> _openRedirectLink() async {
    final urlStr = widget.watch.redirectUrl;
    if (urlStr != null && urlStr.isNotEmpty) {
      final uri = Uri.tryParse(urlStr);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    _showRedirectBottomSheet(urlStr ?? 'https://www.ebay.com');
  }

  void _showRedirectBottomSheet(String url) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF0064D2).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.open_in_new_rounded, color: Color(0xFF0064D2), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              "Redirect to ${widget.watch.platform}",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Open this listing directly on ${widget.watch.platform} or copy the redirect link.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.chipBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp, color: context.textPrimaryColor, fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Get.snackbar("Copied", "Listing link copied to clipboard");
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text("Close", style: TextStyle(color: context.textPrimaryColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0064D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Open Link", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final watch = widget.watch;
    final double priceVal = watch.price;
    final double marketAvg = priceVal * 0.97;
    final double lowestPrice = priceVal * 0.88;
    final double highestPrice = priceVal * 1.15;
    final double priceDelta = ((priceVal - marketAvg) / marketAvg * 100);

    final trendPoints = [
      priceVal * 0.92,
      priceVal * 0.94,
      priceVal * 0.91,
      priceVal * 0.96,
      priceVal * 0.98,
      priceVal * 1.02,
      priceVal * 1.01,
      priceVal * 1.05,
      priceVal * 1.00,
    ];

    // Similar Listings from live search results
    final similarWatches = _search.searchResults.where((w) => w.id != watch.id).take(5).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. HERO IMAGE SECTION with parallax
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _staggerController,
                  builder: (ctx, _) {
                    return FadeTransition(
                      opacity: _heroFade,
                      child: _buildHeroImage(watch),
                    );
                  },
                ),
              ),

              // 2. Content body
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _staggerController,
                  builder: (ctx, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Reference
                        _buildAnimatedSection(
                          slide: _titleSlide,
                          fade: _titleFade,
                          child: _buildTitleSection(watch),
                        ),

                        // Price Cards
                        _buildAnimatedSection(
                          slide: _priceSlide,
                          fade: _priceFade,
                          child: _buildPriceCards(priceVal, marketAvg, priceDelta),
                        ),

                        // Specs Grid
                        _buildAnimatedSection(
                          slide: _specsSlide,
                          fade: _specsFade,
                          child: _buildSpecsGrid(watch),
                        ),

                        // Dealer Card
                        _buildAnimatedSection(
                          slide: _dealerSlide,
                          fade: _dealerFade,
                          child: _buildDealerCard(watch),
                        ),

                        // Market Analytics Section
                        _buildAnimatedSection(
                          slide: _analyticsSlide,
                          fade: _analyticsFade,
                          child: _buildMarketAnalyticsSection(
                            priceVal, marketAvg, lowestPrice, highestPrice, trendPoints,
                          ),
                        ),

                        // Description
                        _buildAnimatedSection(
                          slide: _descSlide,
                          fade: _descFade,
                          child: _buildDescriptionSection(watch),
                        ),

                        // Similar Listings
                        if (similarWatches.isNotEmpty)
                          _buildAnimatedSection(
                            slide: _similarSlide,
                            fade: _similarFade,
                            child: _buildSimilarListings(similarWatches),
                          ),

                        const SizedBox(height: 100), // Bottom padding for CTA
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // Custom AppBar overlay
          _buildCustomAppBar(watch),

          // Sticky bottom CTA
          _buildBottomCTA(watch),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({
    required Animation<Offset> slide,
    required Animation<double> fade,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: _staggerController,
        builder: (ctx, _) {
          return Transform.translate(
            offset: slide.value,
            child: child,
          );
        },
      ),
    );
  }

  // ==========================================
  // 1. HERO IMAGE with parallax dark gradient
  // ==========================================
  Widget _buildHeroImage(WatchModel watch) {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1628),
            Color(0xFF0F1E36),
            Color(0xFF162A4A),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle radial highlight
          Positioned.fill(
            child: CustomPaint(painter: _HeroBgPainter()),
          ),

          // Watch image with parallax
          Center(
            child: Transform.translate(
              offset: Offset(0, -_imageParallaxOffset * 0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
                child: Hero(
                  tag: 'watch_${watch.id}',
                  child: watch.imageUrl.startsWith('http')
                      ? Image.network(
                          watch.imageUrl,
                          fit: BoxFit.contain,
                          height: 260,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/8.png',
                            fit: BoxFit.contain,
                            height: 260,
                          ),
                        )
                      : Image.asset(
                          watch.imageUrl,
                          fit: BoxFit.contain,
                          height: 260,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================
  // 2. TITLE SECTION
  // ==================================
  Widget _buildTitleSection(WatchModel watch) {
    final bool isEbay = watch.isEbay;
    final bool isInApp = watch.isInApp;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marketplace Platform Tag & Redirect Link Option
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      size: 13,
                      color: isEbay
                          ? const Color(0xFF0064D2)
                          : (isInApp ? const Color(0xFFD97706) : watch.platformColor),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isEbay
                          ? "EBAY MARKETPLACE"
                          : (isInApp ? "IN-APP PEER LISTING" : watch.platform.toUpperCase()),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isEbay
                            ? const Color(0xFF0064D2)
                            : (isInApp ? const Color(0xFFD97706) : watch.platformColor),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEbay) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _openRedirectLink,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0064D2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          "REDIRECT LINK",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            watch.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: context.textPrimaryColor,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Reference ${watch.model}",
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================
  // 3. PRICE CARDS
  // ==================================
  Widget _buildPriceCards(double price, double marketAvg, double delta) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
      child: Row(
        children: [
          // Current Price Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: context.primaryNav,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CURRENT PRICE",
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AnimatedBuilder(
                    animation: _priceCountAnimation,
                    builder: (ctx, _) {
                      final val = price * _priceCountAnimation.value;
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatPrice(val),
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      "+${delta.abs().toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Market Avg Card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.borderColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MARKET AVG",
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: context.textSecondaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AnimatedBuilder(
                    animation: _priceCountAnimation,
                    builder: (ctx, _) {
                      final val = marketAvg * _priceCountAnimation.value;
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatPrice(val),
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          size: 10.sp, color: context.textSecondaryColor),
                      SizedBox(width: 2.w),
                      Text(
                        "STABLE",
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: context.textSecondaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================
  // 4. SPECS GRID
  // ==================================
  Widget _buildSpecsGrid(WatchModel watch) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSpecItem(
                    Icons.calendar_today_rounded,
                    "YEAR",
                    watch.year.toString(),
                  ),
                ),
                Expanded(
                  child: _buildSpecItem(
                    Icons.verified_rounded,
                    "CONDITION",
                    watch.condition,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSpecItem(
                    Icons.settings_rounded,
                    "MOVEMENT",
                    "Automatic",
                  ),
                ),
                Expanded(
                  child: _buildSpecItem(
                    Icons.inventory_2_outlined,
                    "SCOPE",
                    "Full Set",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.chipBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: context.textSecondaryColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: context.textSecondaryColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================================
  // 5. DEALER CARD
  // ==================================
  Widget _buildDealerCard(WatchModel watch) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: GestureDetector(
        onTap: () {
          Get.to(() => ChatScreen(
            chatId: "dealer_${watch.id ?? watch.brand.toLowerCase()}",
            title: "${watch.platform} Verified Dealer",
            subtitle: watch.title,
          ));
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: watch.platformColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.storefront_rounded,
                    color: watch.platformColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      watch.isEbay
                          ? "eBay Marketplace Seller"
                          : (watch.isInApp
                              ? (watch.ownerName != null ? "Trader • ${watch.ownerName}" : "In-App Verified Trader")
                              : "${watch.platform} Dealer"),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                          size: 12,
                          color: const Color(0xFFF59E0B),
                        )),
                        const SizedBox(width: 6),
                        Text(
                          watch.isEbay
                              ? "eBay Top Rated (Verified)"
                              : (watch.isInApp ? "Verified Community Trader" : "4.9/5 Rating (240+ sales)"),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    size: 16, color: context.primaryNav),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================
  // 6. MARKET ANALYTICS SECTION
  // ==================================
  Widget _buildMarketAnalyticsSection(
    double price,
    double marketAvg,
    double lowest,
    double highest,
    List<double> trendPoints,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text(
                "MARKET ANALYTICS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: context.primaryNav,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: context.primaryNav,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Average Market Price card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AVERAGE MARKET PRICE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: context.textSecondaryColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedBuilder(
                      animation: _priceCountAnimation,
                      builder: (ctx, _) {
                        final val = marketAvg * _priceCountAnimation.value;
                        return Text(
                          _formatPrice(val),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimaryColor,
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded,
                            size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        const Text(
                          "+2.4%",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Lowest / Highest row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LOWEST",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: context.textSecondaryColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedBuilder(
                            animation: _priceCountAnimation,
                            builder: (ctx, _) {
                              final val = lowest * _priceCountAnimation.value;
                              return Text(
                                _formatPrice(val),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: context.textPrimaryColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: context.borderColor,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "HIGHEST",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: context.textSecondaryColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedBuilder(
                              animation: _priceCountAnimation,
                              builder: (ctx, _) {
                                final val = highest * _priceCountAnimation.value;
                                return Text(
                                  _formatPrice(val),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: context.textPrimaryColor,
                                  ),
                                );
                              },
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
          const SizedBox(height: 16),

          // Price Trend Chart
          PriceTrendChart(
            dataPoints: trendPoints,
            averagePrice: marketAvg,
          ),
          const SizedBox(height: 16),

          // Liquidity / Volume / Volatility indicators
          _buildIndicatorTile(
            Icons.water_drop_rounded,
            "LIQUIDITY SCORE",
            "High",
            _buildLiquidityBar(),
          ),
          const SizedBox(height: 10),
          _buildIndicatorTile(
            Icons.bar_chart_rounded,
            "LISTINGS VOLUME",
            "124",
            Text(
              "-4%",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildIndicatorTile(
            Icons.speed_rounded,
            "VOLATILITY",
            "Low",
            _buildVolatilityIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorTile(
    IconData icon, String label, String value, Widget trailing,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: context.primaryNav),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: context.textSecondaryColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildLiquidityBar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 0.82),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            color: context.chipBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVolatilityIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 0.25),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            color: context.chipBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================================
  // 7. DESCRIPTION SECTION
  // ==================================
  Widget _buildDescriptionSection(WatchModel watch) {
    final desc = "Up for sale is a stunning ${watch.year} ${watch.brand} "
        "${watch.model}, Reference ${watch.model}. This piece is in truly "
        "${watch.condition.toLowerCase()} condition, still retaining some "
        "factory stickers. Featuring the new 41mm case design and the Calibre "
        "3235 movement with a 70-hour power reserve. This is the quintessence of "
        "horological excellence, combining robust engineering with timeless "
        "aesthetics. The ceramic bezel insert provides exceptional scratch "
        "resistance and color stability. Complete with box, papers, warranty "
        "card, and all original accessories.";

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Description",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.primaryNav,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              desc,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              desc,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
                height: 1.6,
              ),
            ),
            crossFadeState: _isDescExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
            child: Row(
              children: [
                Text(
                  _isDescExpanded ? "Show Less" : "Read More",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.primaryNav,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isDescExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: context.primaryNav,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================
  // 8. SIMILAR LISTINGS
  // ==================================
  Widget _buildSimilarListings(List<WatchModel> similar) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Similar Listings",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.primaryNav,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: similar.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: index < similar.length - 1 ? 14 : 0),
                  child: _buildSimilarCard(similar[index], index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarCard(WatchModel w, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => Get.off(() => WatchDetailScreen(watch: w)),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: context.isDarkTheme
                    ? Colors.white.withValues(alpha: 0.01)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    color: context.chipBg,
                    child: Image.asset(
                      w.imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.brand.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: context.textSecondaryColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      w.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrice(w.price),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: context.primaryNav,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================
  // CUSTOM APP BAR
  // ==================================
  Widget _buildCustomAppBar(WatchModel watch) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Builder(
        builder: (ctx) {
          final scrolled = _scrollController.hasClients && _scrollController.offset > 280;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
            ),
            decoration: BoxDecoration(
              color: scrolled ? context.surfaceBg : Colors.transparent,
              boxShadow: scrolled
                  ? [
                      BoxShadow(
                        color: context.isDarkTheme
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scrolled
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: scrolled ? context.textPrimaryColor : Colors.white,
                      ),
                    ),
                  ),
                  // Title (appears on scroll)
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: scrolled ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Center(
                        child: Text(
                          watch.title,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  // Bookmark button
                  Obx(() {
                    final isSaved = _bookmark.isBookmarked(watch.idString);
                    return IconButton(
                      onPressed: () => _bookmark.toggleBookmark(watch),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scrolled
                              ? Colors.transparent
                              : Colors.black.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: isSaved
                              ? Colors.red
                              : (scrolled ? const Color(0xFF0F172A) : Colors.white),
                        ),
                      ),
                    );
                  }),
                  // Share button
                  IconButton(
                    onPressed: _showShareSheet,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scrolled
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: scrolled ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // MARKETPLACE SHARE & BUY OPTIONS
  // ==========================================
  void _showShareSheet() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Share Listing",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.primaryNav),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareOption("WhatsApp", Icons.chat_outlined, const Color(0xFF25D366)),
                _buildShareOption("Facebook", Icons.groups_outlined, const Color(0xFF1877F2)),
                _buildShareOption("Messenger", Icons.message_rounded, const Color(0xFF0084FF)),
                _buildShareOption("Copy Link", Icons.link_rounded, const Color(0xFF64748B)),
              ],
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Get.back(); // Dismiss share sheet
        Get.showOverlay(
          asyncFunction: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          loadingWidget: Center(
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(color: context.surfaceBg, borderRadius: BorderRadius.circular(16.r)),
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(context.primaryNav)),
            ),
          ),
        ).then((_) {
          Get.snackbar(
            "Shared Successfully",
            "\"${widget.watch.title}\" shared to $label!",
            backgroundColor: context.primaryNav,
            colorText: Colors.white,
          );
        });
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  void _showBuyConfirmSheet() {
    final buyerName = _auth.currentUser.value?.name ?? "Collector";
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Text(
              "Confirm Purchase",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.primaryNav),
            ),
            SizedBox(height: 12.h),
            Text(
              "You are about to purchase this watch directly from the trader. A transaction record will be logged and the seller will be notified.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor, height: 1.4),
            ),
            SizedBox(height: 18.h),
            // Watch info preview
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.chipBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.h,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: widget.watch.imageUrl.startsWith('http')
                        ? Image.network(
                            widget.watch.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/images/8.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(widget.watch.imageUrl, fit: BoxFit.contain),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.watch.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatPrice(widget.watch.price),
                          style: TextStyle(fontSize: 13.sp, color: const Color(0xFFCA8A04), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryNav,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 0,
                ),
                onPressed: () async {
                  Get.back(); // Close bottom sheet
                  Get.showOverlay(
                    asyncFunction: () async {
                      await _search.buyListing(widget.watch, buyerName);
                    },
                    loadingWidget: Center(
                      child: Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(color: context.surfaceBg, borderRadius: BorderRadius.circular(16.r)),
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(context.primaryNav)),
                      ),
                    ),
                  ).then((_) {
                    setState(() {
                      _isSoldLocal = true;
                    });
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        title: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Purchase Successful!",
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.primaryNav),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "You have successfully purchased this watch listing. The trader has been notified to generate your billing invoice receipt.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text("Close", style: TextStyle(color: context.primaryNav, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    );
                  });
                },
                child: Text("Confirm Purchase", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================
  // BOTTOM CTA
  // ==================================
  Widget _buildBottomCTA(WatchModel watch) {
    final bool isInApp = watch.isInApp;
    final currentUserId = _auth.currentUser.value?.backendId ?? _auth.currentUser.value?.id?.toString();
    final currentUserName = _auth.currentUser.value?.name;
    final bool isOwnListing = !watch.isEbay && (
        (watch.userId != null && watch.userId == _auth.currentUser.value?.id) ||
        (watch.ownerId != null && currentUserId != null && watch.ownerId == currentUserId) ||
        (watch.ownerName != null && currentUserName != null && currentUserName.isNotEmpty && watch.ownerName == currentUserName)
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24.w, 16.h, 24.w, MediaQuery.of(context).padding.bottom + 16.h,
        ),
        decoration: BoxDecoration(
          color: context.surfaceBg,
          boxShadow: [
            BoxShadow(
              color: context.isDarkTheme
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Action: Link/Redirect for eBay or Chat with Seller for in-app
            InkWell(
              onTap: watch.isEbay
                  ? () => _showRedirectBottomSheet(watch.redirectUrl ?? 'https://www.ebay.com')
                  : () {
                      final sellerId = watch.ownerId ?? watch.userId?.toString() ?? watch.idString;
                      final sellerTitle = watch.ownerName != null ? "Seller • ${watch.ownerName}" : "Seller • ${watch.brand} ${watch.model}";
                      Get.to(() => ChatScreen(
                        chatId: "seller_${sellerId.isNotEmpty ? sellerId : watch.brand.toLowerCase()}",
                        title: sellerTitle,
                        subtitle: "\$${watch.price.toStringAsFixed(0)} ${watch.currency} • ${watch.platform}",
                      ));
                    },
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                width: 54.w,
                height: 54.h,
                decoration: BoxDecoration(
                  color: context.chipBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: Center(
                  child: Icon(
                    watch.isEbay ? Icons.link_rounded : Icons.chat_bubble_outline_rounded,
                    size: 22.sp,
                    color: watch.isEbay ? const Color(0xFF0064D2) : context.primaryNav,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            // Main CTA button with pulse glow
            Expanded(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (ctx, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: (watch.isEbay ? const Color(0xFF0064D2) : context.primaryNav).withValues(
                            alpha: 0.15 + (0.1 * _pulseAnimation.value),
                          ),
                          blurRadius: 16 + (8 * _pulseAnimation.value),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: SizedBox(
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: isOwnListing
                        ? null
                        : (_isSoldLocal
                            ? null
                            : (isInApp ? _showBuyConfirmSheet : _openRedirectLink)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSoldLocal
                          ? (context.isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade400)
                          : (watch.isEbay ? const Color(0xFF0064D2) : context.primaryNav),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _isSoldLocal
                          ? (context.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300)
                          : context.chipBg,
                      disabledForegroundColor: _isSoldLocal
                          ? (context.isDarkTheme ? Colors.grey.shade500 : Colors.grey.shade600)
                          : context.textSecondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isOwnListing
                              ? "My Listing"
                              : (_isSoldLocal
                                  ? "SOLD"
                                  : (isInApp
                                      ? "Buy Watch"
                                      : (watch.isEbay ? "View on eBay" : "Visit Listing"))),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          isOwnListing
                              ? Icons.check_circle_outline_rounded
                              : (_isSoldLocal
                                  ? Icons.lock_outline_rounded
                                  : (watch.isEbay ? Icons.open_in_new_rounded : Icons.arrow_forward_rounded)),
                          size: 18.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}

// Background painter for hero section - subtle concentric circles
class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 8; i++) {
      paint.color = Colors.white.withValues(alpha: 0.03);
      canvas.drawCircle(center, i * 30.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
