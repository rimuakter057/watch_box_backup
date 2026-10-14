import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../models/watch_model.dart';
import '../home/watch_detail_screen.dart';
import '../../core/db/db_helper.dart';
import '../../core/network/services/visual_search_api_service.dart';

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen>
    with TickerProviderStateMixin {
  final DbHelper _dbHelper = DbHelper();
  VisualSearchApiService get _visualApi => Get.find<VisualSearchApiService>();

  late AnimationController _scannerAnimController;
  late Animation<double> _pulseAnimation;
  
  bool _isScanning = false;
  String _scanningMessage = "";
  
  // Local list of recent scans matching the mockup design
  final List<Map<String, String>> _recentScans = [
    {"name": "Submariner", "image": "assets/images/rolex_watch.png", "keyword": "Rolex"},
    {"name": "Speedmaster", "image": "assets/images/4.jpg", "keyword": "Omega"},
    {"name": "Nautilus", "image": "assets/images/5.png", "keyword": "Patek Philippe"},
    {"name": "GMT", "image": "assets/images/1.png", "keyword": "GMT-Master"},
  ].obs;

  // Identified matches matching the layout and watches in the mockup
  final RxList<WatchModel> _identifiedMatches = <WatchModel>[].obs;
  
  // Custom mock percentages to overlay on cards
  final List<int> _mockPercentages = [98, 92, 87, 84, 79, 72];

  @override
  void initState() {
    super.initState();
    
    // Scanner pulse animation controller
    _scannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _scannerAnimController, curve: Curves.easeInOut),
    );

    // Initial search to pre-populate identified matches like in the mockup
    _loadInitialMatches();
  }

  @override
  void dispose() {
    _scannerAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMatches() async {
    // Perform initial mock query for Submariner so matches populate immediately
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      "SELECT * FROM listings WHERE title LIKE ? OR brand LIKE ?",
      ["%Submariner%", "%Rolex%"],
    );
    _identifiedMatches.assignAll(
      results.map((m) => WatchModel.fromMap(m)).toList()
    );
  }

  // Triggered when gallery or camera is selected
  Future<void> _simulateImageAnalysis(String keyword, String label) async {
    setState(() {
      _isScanning = true;
      _scanningMessage = "Analyzing visual features...";
    });

    // 1.1 Attempt live visual AI analysis
    try {
      _visualApi.analyzeImage([1, 2, 3], "watch_query.jpg");
    } catch (_) {}
    // 1. First stage delay: scanning texture
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _scanningMessage = "Matching horology landmarks...";
    });

    // 2. Second stage delay: database lookup
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      "SELECT * FROM listings WHERE title LIKE ? OR brand LIKE ? OR model LIKE ?",
      ["%$keyword%", "%$keyword%", "%$keyword%"],
    );

    _identifiedMatches.assignAll(
      results.map((m) => WatchModel.fromMap(m)).toList()
    );

    // Add to recent scans if not already there
    final exists = _recentScans.any((element) => element["name"] == label);
    if (!exists) {
      // Find representative image
      String imageAsset = "assets/images/8.png";
      if (_identifiedMatches.isNotEmpty) {
        imageAsset = _identifiedMatches.first.imageUrl;
      }
      _recentScans.insert(0, {
        "name": label,
        "image": imageAsset,
        "keyword": keyword,
      });
    }

    setState(() {
      _isScanning = false;
    });

    Get.snackbar(
      "Visual Scan Successful",
      "Found ${_identifiedMatches.length} matching models for '$label'.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: context.primaryNav.withValues(alpha: 0.95),
      colorText: context.isDarkTheme ? AppColors.backgroundDark : Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // Pick random watch to scan for simulation
  void _startRandomScan() {
    final List<Map<String, String>> pool = [
      {"name": "Submariner", "keyword": "Submariner"},
      {"name": "Speedmaster", "keyword": "Speedmaster"},
      {"name": "Nautilus", "keyword": "Nautilus"},
      {"name": "Royal Oak", "keyword": "Royal Oak"},
      {"name": "Santos", "keyword": "Cartier"},
      {"name": "GMT Pepsi", "keyword": "Pepsi"},
    ];
    final selected = pool[Random().nextInt(pool.length)];
    _simulateImageAnalysis(selected["keyword"]!, selected["name"]!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceBg,
        elevation: context.isDarkTheme ? 0.0 : 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimaryColor, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Image Search",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Upload Box Card
                _buildUploadBox(),
                const SizedBox(height: 16),

                // 2. Camera Access Button
                _buildCameraAccessButton(),
                const SizedBox(height: 32),

                // 3. Recent Scans Header and Horizontal list
                Obx(() => _recentScans.isNotEmpty 
                  ? _buildRecentScansSection() 
                  : const SizedBox.shrink()
                ),
                Obx(() => _recentScans.isNotEmpty 
                  ? const SizedBox(height: 32) 
                  : const SizedBox.shrink()
                ),

                // 4. Identified Matches Header and Grid
                _buildIdentifiedMatchesSection(),
              ],
            ),
          ),

          // Scanning Overlay
          if (_isScanning) _buildScanningOverlay(),
        ],
      ),
    );
  }

  // Widget: Faint watch dial engraving behind upload option
  Widget _buildUploadBox() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFEDEDF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkTheme ? 0.25 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular watermark representing watch dial coordinates
            Opacity(
              opacity: 0.04,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _WatchDialWatermarkPainter(color: context.textPrimaryColor),
              ),
            ),
            
            // Upload Content
            InkWell(
              onTap: _startRandomScan,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Plus overlay circle icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.isDarkTheme ? const Color(0xFF0F3156) : const Color(0xFFD3E2F4),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          color: context.primaryNav,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Upload from Gallery",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select a clear photo of your timepiece from your library",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget: Camera access button matching mockup
  Widget _buildCameraAccessButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: context.primaryNav.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _startRandomScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryNav,
          foregroundColor: context.isDarkTheme ? AppColors.backgroundDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.camera_alt_rounded, size: 20),
            SizedBox(width: 12),
            Text(
              "Direct Camera Access",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget: Recent scans horizontal list section
  Widget _buildRecentScansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Scans",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                _recentScans.clear();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "CLEAR ALL",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.primaryNav,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recentScans.length,
            itemBuilder: (context, idx) {
              final item = _recentScans[idx];
              return Padding(
                padding: const EdgeInsets.only(right: 18.0),
                child: InkWell(
                  onTap: () => _simulateImageAnalysis(item["keyword"]!, item["name"]!),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // Thumbnail Watch Image
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderColor),
                          image: DecorationImage(
                            image: AssetImage(item["image"]!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item["name"]!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget: Grid of identified matches from DB search
  Widget _buildIdentifiedMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Identified Matches",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (_identifiedMatches.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded, 
                    size: 48, 
                    color: context.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No matches found yet",
                    style: TextStyle(fontSize: 14, color: context.textSecondaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Upload or snap a timepiece photo to detect matches",
                    style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _identifiedMatches.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.76,
            ),
            itemBuilder: (context, idx) {
              final watch = _identifiedMatches[idx];
              
              // Map mock percentage matching sequence
              final percentage = _mockPercentages[idx % _mockPercentages.length];
              final isHighMatch = percentage >= 90;

              return Card(
                color: context.cardBg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Get.to(() => WatchDetailScreen(watch: watch)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Half: Watch Image + Floating Badge
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              watch.imageUrl,
                              fit: BoxFit.cover,
                            ),
                            // Gradient shadow on image for text visibility
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Floating percentage badge in top-right
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isHighMatch 
                                      ? context.primaryNav 
                                      : context.textSecondaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "$percentage% Match",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom Half: Details Row
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Source platform tag
                            Text(
                              watch.platform == 'eBay' ? 'EBAY LUXURY' : watch.platform.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: watch.platformColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Watch name
                            Text(
                              watch.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Price row matching mockup
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Price",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                                Text(
                                  "\$${watch.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: watch.platformColor,
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
            },
          );
        }),
      ],
    );
  }

  // Scanning animated overlay
  Widget _buildScanningOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: context.primaryNav.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.primaryNav, width: 3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              _scanningMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                color: context.primaryNav,
                backgroundColor: Colors.white24,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw faint concentric circle markings
class _WatchDialWatermarkPainter extends CustomPainter {
  final Color color;
  _WatchDialWatermarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw concentric circles
    canvas.drawCircle(center, 40, paint);
    canvas.drawCircle(center, 70, paint);
    canvas.drawCircle(center, 95, paint);

    // Draw dial ticks
    for (int i = 0; i < 12; i++) {
      final double angle = i * 30 * pi / 180;
      final start = Offset(
        center.dx + 85 * cos(angle),
        center.dy + 85 * sin(angle),
      );
      final end = Offset(
        center.dx + 95 * cos(angle),
        center.dy + 95 * sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WatchDialWatermarkPainter oldDelegate) => oldDelegate.color != color;
}
