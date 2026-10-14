import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/search_controller.dart';
import '../../../controllers/bookmark_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/watch_model.dart';
import '../watch_detail_screen.dart';
import '../../widgets/watch_background.dart';
import '../../search/image_search_screen.dart';

class SearchTab extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const SearchTab({super.key, this.onBackToHome});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final WatchSearchController _search = Get.find<WatchSearchController>();
  final BookmarkController _bookmark = Get.find<BookmarkController>();

  final TextEditingController _queryController = TextEditingController();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _queryController.text = _search.queryText.value;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String val) {
    _search.executeSearch(val);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SearchFilterBottomSheet(
        search: _search,
        onApply: () {
          _search.executeSearch(_queryController.text);
        },
      ),
    );
  }

  void _showImageSearchMockDialog() {
    Get.to(() => const ImageSearchScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: WatchBackground(
        showGears: true,
        showDialTicks: true,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 8),

              // 1. TOP APP BAR (< Timepieces Sliders)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C),
                        size: 20,
                      ),
                      onPressed: widget.onBackToHome,
                    ),
                    Text(
                      "Timepieces",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C),
                        size: 22,
                      ),
                      onPressed: _showFilterBottomSheet,
                    ),
                  ],
                ),
              ),

              // 2. SEARCH INPUT FIELD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _queryController,
                    onSubmitted: _onSearchSubmit,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: "Rolex Submariner",
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14.5,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF07274C),
                          size: 22,
                        ),
                        onPressed: _showImageSearchMockDialog,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 3. SOURCES FILTER PILLS ROW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const Text(
                      "Sources: ",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Obx(() {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildSourcePill(
                                label: "Chrono24",
                                isSelected: _search.searchChrono24.value,
                                activeColor: const Color(0xFF002244),
                                onToggle: () {
                                  _search.searchChrono24.toggle();
                                  _search.executeSearch(_queryController.text);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildSourcePill(
                                label: "eBay",
                                isSelected: _search.searchEbay.value,
                                activeColor: const Color(0xFFE53238),
                                onToggle: () {
                                  _search.searchEbay.toggle();
                                  _search.executeSearch(_queryController.text);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildSourcePill(
                                label: "Grailzee",
                                isSelected: _search.searchGrailzee.value,
                                activeColor: const Color(0xFF18181B),
                                onToggle: () {
                                  _search.searchGrailzee.toggle();
                                  _search.executeSearch(_queryController.text);
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. INSIGHTS BANNER CARD (EBAY INSIGHTS)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A1D36), Color(0xFF0F2C50)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF07274C).withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Chart Icon Box
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF07274C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.bar_chart_rounded,
                            color: Color(0xFF38BDF8),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  "\u2022 4.3M Listings",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Obx(() {
                              final avg = _search.avgPrice.value > 0
                                  ? "\$${_search.avgPrice.value.toStringAsFixed(2)}"
                                  : "\$33.85";
                              return Text(
                                "Avg: $avg USD",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      // eBay Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text("e", style: TextStyle(color: Color(0xFFE53238), fontWeight: FontWeight.w900, fontSize: 13)),
                            Text("b", style: TextStyle(color: Color(0xFF0064D2), fontWeight: FontWeight.w900, fontSize: 13)),
                            Text("a", style: TextStyle(color: Color(0xFFF5AF02), fontWeight: FontWeight.w900, fontSize: 13)),
                            Text("y", style: TextStyle(color: Color(0xFF86B817), fontWeight: FontWeight.w900, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. RESULTS SUBHEADER (COUNT + GRID/LIST TOGGLE)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      final count = _search.searchResults.length;
                      return Text(
                        "$count TIMEPIECES FOUND",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () => setState(() => _isGridView = !_isGridView),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 6. MAIN CONTENT BODY (EMPTY STATE OR RESULTS)
              Expanded(
                child: Obx(() {
                  if (_search.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF07274C)),
                    );
                  }

                  if (_search.searchResults.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return _isGridView ? _buildResultsGridView() : _buildResultsListView();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Source Pill Button
  Widget _buildSourcePill({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : context.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : context.borderColor,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State matching Screenshot 1
  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Circular Compass Icon Container
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF64748B),
                width: 3.2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.explore_rounded,
                color: Color(0xFF64748B),
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Start your Horology search",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Type a model name above to query API marketplace endpoints.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),

          // Quick Filter Tag Pills
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickTagPill("Rolex"),
              _buildQuickTagPill("Submariner"),
              _buildQuickTagPill("Omega"),
              _buildQuickTagPill("Speedmaster"),
              _buildQuickTagPill("Patek Philippe"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTagPill(String keyword) {
    return InkWell(
      onTap: () {
        _queryController.text = keyword;
        _search.executeSearch(keyword);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          keyword,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  // 1-column Vertical ListView
  Widget _buildResultsListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _search.searchResults.length,
      itemBuilder: (context, index) {
        final watch = _search.searchResults[index];
        return _buildWatchListCard(watch);
      },
    );
  }

  Widget _buildWatchListCard(WatchModel watch) {
    final priceStr = watch.price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return InkWell(
      onTap: () => Get.to(() => WatchDetailScreen(watch: watch)),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkTheme ? 0.2 : 0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: context.isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    child: Image.asset(watch.imageUrl, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07274C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "TOP VERIFIED",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Obx(() {
                    final isSaved = _bookmark.isBookmarked(watch.id!);
                    return GestureDetector(
                      onTap: () => _bookmark.toggleBookmark(watch),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: context.chipBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isSaved ? Colors.red : context.textSecondaryColor,
                          size: 18,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    watch.brand.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          watch.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "\$$priceStr",
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF07274C),
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

  // 2-column GridView
  Widget _buildResultsGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: _search.searchResults.length,
      itemBuilder: (context, index) {
        final watch = _search.searchResults[index];
        final priceStr = watch.price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

        return InkWell(
          onTap: () => Get.to(() => WatchDetailScreen(watch: watch)),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDarkTheme ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Container(
                      color: context.isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      child: Image.asset(watch.imageUrl, fit: BoxFit.contain, width: double.infinity),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        watch.brand.toUpperCase(),
                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        watch.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$$priceStr",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF07274C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------
// DEDICATED SEARCH FILTER BOTTOM SHEET (SCREENSHOT 2)
// ----------------------------------------------------
class _SearchFilterBottomSheet extends StatefulWidget {
  final WatchSearchController search;
  final VoidCallback onApply;

  const _SearchFilterBottomSheet({
    required this.search,
    required this.onApply,
  });

  @override
  State<_SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<_SearchFilterBottomSheet> {
  late bool _chrono24;
  late bool _ebay;
  late bool _grailzee;

  @override
  void initState() {
    super.initState();
    _chrono24 = widget.search.searchChrono24.value;
    _ebay = widget.search.searchEbay.value;
    _grailzee = widget.search.searchGrailzee.value;
  }

  void _resetAll() {
    setState(() {
      _chrono24 = true;
      _ebay = true;
      _grailzee = true;
    });
  }

  void _apply() {
    widget.search.searchChrono24.value = _chrono24;
    widget.search.searchEbay.value = _ebay;
    widget.search.searchGrailzee.value = _grailzee;
    Navigator.pop(context);
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header (Search Filters & Reset All)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Search Filters",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: _resetAll,
                  child: const Text(
                    "Reset All",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF07274C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Marketplace Platforms
            const Text(
              "Marketplace Platforms",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),

            // Platform Filter Chips
            Row(
              children: [
                // Chrono24
                _buildFilterSheetChip(
                  label: "Chrono24",
                  isSelected: _chrono24,
                  activeColor: const Color(0xFF002244),
                  iconWidget: const Icon(Icons.explore, size: 14, color: Colors.white70),
                  onTap: () => setState(() => _chrono24 = !_chrono24),
                ),
                const SizedBox(width: 8),

                // eBay
                _buildFilterSheetChip(
                  label: "eBay",
                  isSelected: _ebay,
                  activeColor: const Color(0xFFE53238),
                  iconWidget: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  onTap: () => setState(() => _ebay = !_ebay),
                ),
                const SizedBox(width: 8),

                // Grailzee
                _buildFilterSheetChip(
                  label: "Grailzee",
                  isSelected: _grailzee,
                  activeColor: const Color(0xFF18181B),
                  iconWidget: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  onTap: () => setState(() => _grailzee = !_grailzee),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Big Apply Filters Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07274C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Apply Filters",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSheetChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : context.chipBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : context.borderColor,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              iconWidget,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

