import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'tabs/home_tab.dart';
import 'tabs/search_tab.dart';
import 'tabs/alerts_tab.dart';
import 'tabs/profile_tab.dart';
import '../widgets/navbar/custom_navbar.dart';
import 'traders_collections_screen.dart';
import '../profile/my_listings_screen.dart';

import 'tabs/listings_tab.dart';

class MainContainerScreen extends StatefulWidget {
  final int initialIndex;
  const MainContainerScreen({super.key, this.initialIndex = 0});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  // Swipe tracking
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['tabIndex'] is int) {
      _currentIndex = args['tabIndex'] as int;
    } else if (args is Map && args['initialIndex'] is int) {
      _currentIndex = args['initialIndex'] as int;
    } else {
      _currentIndex = widget.initialIndex;
    }
    _tabs = [
      HomeTab(
        onTabChangeRequested: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      SearchTab(
        onBackToHome: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      const ListingsTab(),
      const AlertsTab(),
      const ProfileTab(),
    ];
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // No-op: we resolve on drag end
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300 && _currentIndex < _tabs.length - 1) {
      setState(() => _currentIndex++);
    } else if (velocity > 300 && _currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MARKETPLACE & LISTINGS BOTTOM SHEET (EXACT SCREENSHOT DESIGN)
// ---------------------------------------------------------------------------
class MarketplaceListingsBottomSheet extends StatelessWidget {
  const MarketplaceListingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header (Marketplace & Listings + Close button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Marketplace & Listings",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card 1: Trader Collections
            _buildOptionCard(
              context: context,
              title: "Trader Collections",
              subtitle: "Browse in-app listings from other community traders",
              icon: Icons.storefront_rounded,
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const TradersCollectionsScreen());
              },
            ),
            const SizedBox(height: 14),

            // Card 2: My Listings
            _buildOptionCard(
              context: context,
              title: "My Listings",
              subtitle: "View and manage your active and sold watch listings",
              icon: Icons.inventory_2_outlined,
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const MyListingsScreen());
              },
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: const Color(0xFF07274C),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Chevron Arrow
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF64748B),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}