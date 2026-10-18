import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/search_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/watch_background.dart';
import '../watch_detail_screen.dart';
import '../../../models/watch_model.dart';
import 'bookmarks_tab.dart';
import '../../search/image_search_screen.dart';
import '../../profile/my_listings_screen.dart';
import '../../../core/network/services/recommendations_api_service.dart';

class HomeTab extends StatefulWidget {
  final Function(int)? onTabChangeRequested;

  const HomeTab({super.key, this.onTabChangeRequested});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  final AuthController _auth = Get.find<AuthController>();
  final WatchSearchController _search = Get.find<WatchSearchController>();
  RecommendationsApiService get _recomApi => Get.find<RecommendationsApiService>();

  final RxList<WatchModel> _recommendedWatches = <WatchModel>[].obs;
  final Rx<WatchModel?> _dailyHighlight = Rx<WatchModel?>(null);
  final Rx<Map<String, dynamic>?> _marketInsights = Rx<Map<String, dynamic>?>(null);
  final RxBool _isLoadingHome = true.obs;

  late AnimationController _fadeInController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadHomeData() async {
    try {
      final recs = await _recomApi.getHomeRecommendations();
      if (recs != null) {
        final list = recs['watches'] ?? recs['items'] ?? recs['recommendations'];
        if (list is List) {
          final items = list.whereType<Map>().map((m) => WatchModel.fromMap(Map<String, dynamic>.from(m))).toList();
          _recommendedWatches.assignAll(items);
        }
        if (recs['highlight'] is Map) {
          _dailyHighlight.value = WatchModel.fromMap(Map<String, dynamic>.from(recs['highlight']));
        }
      }
      if (_recommendedWatches.isEmpty) {
        final forYou = await _recomApi.getForYou();
        if (forYou != null && forYou.isNotEmpty) {
          _recommendedWatches.assignAll(forYou);
        }
      }

      // If highlight not explicitly provided, use the top recommended watch from API
      if (_dailyHighlight.value == null && _recommendedWatches.isNotEmpty) {
        _dailyHighlight.value = _recommendedWatches.first;
      }

      final insights = await _recomApi.getMarketInsights();
      if (insights != null && insights.isNotEmpty) {
        _marketInsights.value = insights;
      } else {
        _marketInsights.value = null;
      }
    } catch (e) {
      debugPrint("❌ [HOME TAB] Error loading home API data: $e. No fallback.");
    } finally {
      _isLoadingHome.value = false;
    }
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  void _openImageSearchScreen() {
    Get.to(() => const ImageSearchScreen());
  }

  void _onBrandSelect(String brand) {
    _search.executeSearch(brand);
    widget.onTabChangeRequested?.call(1); // Navigate to Search tab
  }

  @override
  Widget build(BuildContext context) {
    final String username = _auth.currentUser.value?.name ?? "Collector";

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: WatchBackground(
        showDialTicks: true,
        showGears: false,
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // 1. TOP HEADER (WATCHBOX PRO, Welcome back, Avatar & Bell)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Amber PRO Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      "WATCHBOX PRO",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Welcome back,",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bell Button with Red Dot
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.notifications_none_rounded,
                                  color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C),
                                  size: 22,
                                ),
                                onPressed: () => widget.onTabChangeRequested?.call(3),
                              ),
                              Positioned(
                                top: 9,
                                right: 11,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Profile Avatar Button
                        GestureDetector(
                          onTap: () => widget.onTabChangeRequested?.call(4),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF07274C),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Color(0xFF07274C),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. SEARCH BAR WITH EMBEDDED VISUAL AI BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.borderColor, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: context.isDarkTheme ? Colors.white70 : const Color(0xFF07274C),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onTabChangeRequested?.call(1),
                              behavior: HitTestBehavior.opaque,
                              child: const Text(
                                "Search Rolex, Patek, Daytona, Re...",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13.5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          // Visual AI pill button
                          InkWell(
                            onTap: _openImageSearchScreen,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFEBF3FC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.camera_alt_outlined, color: Color(0xFF07274C), size: 16),
                                  SizedBox(width: 5),
                                  Text(
                                    "Visual AI",
                                    style: TextStyle(
                                      color: Color(0xFF07274C),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. DAILY HIGHLIGHT HERO BANNER
                  Obx(() {
                    final highlight = _dailyHighlight.value;
                    if (highlight == null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF091C36), Color(0xFF0F2E54)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF07274C).withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                                ),
                                child: const Text(
                                  "DAILY HIGHLIGHT",
                                  style: TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.watch_later_outlined, color: Colors.white70, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          "No highlight today",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          "Check back soon for curated daily picks and marketplace highlights.",
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF091C36), Color(0xFF0F2E54)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF07274C).withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -24,
                              top: -24,
                              child: Opacity(
                                opacity: 0.12,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 22),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD97706).withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                                      ),
                                      child: const Text(
                                        "DAILY HIGHLIGHT",
                                        style: TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            "FEATURED PICK",
                                            style: TextStyle(
                                              color: Color(0xFF10B981),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  highlight.brand.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  highlight.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: RichText(
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          text: "\$${highlight.price.toStringAsFixed(0)} ",
                                          style: const TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                          children: const [
                                            TextSpan(
                                              text: "USD",
                                              style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        Get.to(() => WatchDetailScreen(watch: highlight));
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              "Explore",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),

                  // 4. SAVED TIMEPIECES & ALERTS CARD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: InkWell(
                      onTap: () => Get.to(() => const BookmarksTab()), // Saved tab
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDBEAFE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bookmark_rounded, color: Color(0xFF2563EB), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Saved Timepieces & Alerts",
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Access watch bookmarks & market price alerts",
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. BRAND FILTER PILLS ROW
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildBrandPill(
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                          "Rolex",
                        ),
                        const SizedBox(width: 10),
                        _buildBrandPill(
                          Text(
                            "\u03A9",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          "Omega",
                        ),
                        const SizedBox(width: 10),
                        _buildBrandPill(
                          const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFFD97706)),
                          "Patek Philippe",
                        ),
                        const SizedBox(width: 10),
                        _buildBrandPill(
                          const Icon(Icons.shield_outlined, size: 15, color: Color(0xFF64748B)),
                          "Audemars Piguet",
                        ),
                        const SizedBox(width: 10),
                        _buildBrandPill(
                          const Icon(Icons.diamond_outlined, size: 15, color: Color(0xFF0284C7)),
                          "Cartier",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6. LIVE MARKET INSIGHTS SECTION HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3.5,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF07274C),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Live Market Insights",
                              style: TextStyle(
                                color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          "REALTIME API",
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 7. LIVE MARKET INSIGHTS CARDS
                  Obx(() {
                    final insights = _marketInsights.value;
                    if (insights == null || insights.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.borderColor, width: 1.2),
                          ),
                          child: Center(
                            child: Text(
                              "No market insights available at this moment.",
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final indexTitle = (insights['query'] ?? insights['indexTitle'] ?? "Market Index").toString();
                    final indexSub = (insights['marketplaceId'] ?? insights['indexSubtitle'] ?? "Verified Market Sample").toString();
                    final rawAvg = insights['marketAveragePrice'] ?? insights['indexPrice'];
                    final indexPrice = rawAvg != null ? "\$${rawAvg is num ? rawAvg.toStringAsFixed(0) : rawAvg}" : "Live Average";
                    final indexTrend = (insights['indexTrend'] ?? insights['trend'] ?? "+1.5%").toString();

                    final topProduct = insights['trendingUpwardProduct'] ?? insights['mostSearchedProduct'];
                    final topTitle = topProduct is Map
                        ? (topProduct['title'] ?? topProduct['query'] ?? 'Market Model').toString()
                        : (insights['topTitle'] ?? 'Featured Timepiece').toString();
                    final topSub = topProduct is Map
                        ? (topProduct['basis'] ?? topProduct['brand'] ?? 'Top Trending').toString()
                        : (insights['topSubtitle'] ?? 'Active Market Demand').toString();
                    final rawTopPrice = topProduct is Map ? (topProduct['price'] ?? topProduct['marketAveragePrice']) : insights['topPrice'];
                    final topPrice = rawTopPrice != null ? "\$${rawTopPrice is num ? rawTopPrice.toStringAsFixed(0) : rawTopPrice}" : "Trending";
                    final topTrend = topProduct is Map && topProduct['upDownPercentage'] != null
                        ? "+${topProduct['upDownPercentage']}%"
                        : (insights['topTrend'] ?? "+2.1%").toString();

                    return Column(
                      children: [
                        _buildMarketInsightTile(
                          overline: "LIVE MARKET AVERAGE",
                          title: indexTitle,
                          subtitle: indexSub,
                          price: indexPrice,
                          trend: indexTrend,
                        ),
                        const SizedBox(height: 10),
                        _buildMarketInsightTile(
                          overline: "TOP MARKET MODEL",
                          title: topTitle,
                          subtitle: topSub,
                          price: topPrice,
                          trend: topTrend,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),

                  // 8. DUAL MARKETPLACE BANNERS (Traders Collections & Sell Your Watch)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Card: Traders Collections
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.onTabChangeRequested?.call(2),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 185),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF002D5C),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF002D5C).withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      color: Color(0xFFEAB308),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Traders Collections",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Buy directly from verified dealers.",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFFCBD5E1),
                                          fontSize: 11,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          "Browse",
                                          style: TextStyle(
                                            color: Color(0xFFEAB308),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, color: Color(0xFFEAB308), size: 12),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Right Card: Sell Your Watch
                        Expanded(
                          child: InkWell(
                            onTap: () => Get.to(() => const MyListingsScreen()),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 185),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE69500),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE69500).withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Color(0xFF0F172A),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Sell Your Watch",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "List timepieces directly to API.",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFF451A03),
                                          fontSize: 11,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          "List Now",
                                          style: TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A), size: 12),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // 10. RECOMMENDED FOR YOU SECTION HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3.5,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF07274C),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Recommended For You",
                              style: TextStyle(
                                color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => widget.onTabChangeRequested?.call(1),
                          child: const Text(
                            "View All",
                            style: TextStyle(
                              color: Color(0xFF07274C),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 11. RECOMMENDED WATCH CARDS
                  Obx(() {
                    if (_recommendedWatches.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Center(
                            child: Text(
                              "Search or bookmark timepieces to see recommendations",
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _recommendedWatches.length,
                        itemBuilder: (context, idx) {
                          final watch = _recommendedWatches[idx];
                          return Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: _buildRecommendWatchCard(context, watch),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Brand pill button
  Widget _buildBrandPill(Widget icon, String brandName) {
    return InkWell(
      onTap: () => _onBrandSelect(brandName),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: context.borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              brandName,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Live Market Insight Tile
  Widget _buildMarketInsightTile({
    required String overline,
    required String title,
    required String subtitle,
    required String price,
    required String trend,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    overline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      trend,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Recommended Watch Card
  Widget _buildRecommendWatchCard(BuildContext context, WatchModel watch) {
    final img = watch.imageUrl;
    final isNetwork = img.startsWith('http');

    return InkWell(
      onTap: () => Get.to(() => WatchDetailScreen(watch: watch)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                    child: isNetwork
                        ? Image.network(
                            img,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/images/8.png',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            img,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: watch.isEbay
                            ? const Color(0xFF0064D2)
                            : (watch.isInApp ? const Color(0xFFD97706) : Colors.black87),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        watch.isEbay
                            ? "eBay"
                            : (watch.isInApp ? "In-App" : watch.platform),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.favorite_border_rounded, size: 14, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    watch.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    watch.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$${watch.price.toStringAsFixed(0)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF07274C),
                    ),
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
