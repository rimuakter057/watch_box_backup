import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/alert_controller.dart';
import '../../../core/theme/app_colors.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkTheme ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: context.borderColor,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: _buildStandardNavItem(context, 0, Icons.home_rounded, Icons.home_outlined, "Home"),
              ),
              Expanded(
                child: _buildStandardNavItem(context, 1, Icons.search_rounded, Icons.search_rounded, "Search"),
              ),
              Expanded(
                child: _buildCenterListingItem(context, 2),
              ),
              Expanded(
                child: Obx(() {
                  int? badge;
                  if (Get.isRegistered<AlertController>()) {
                    final c = Get.find<AlertController>().unreadCount.value;
                    badge = c > 0 ? c : null;
                  } else {
                    badge = 1;
                  }
                  return _buildStandardNavItem(
                    context,
                    3,
                    Icons.notifications_rounded,
                    Icons.notifications_none_rounded,
                    "Alerts",
                    badgeCount: badge,
                  );
                }),
              ),
              Expanded(
                child: _buildStandardNavItem(context, 4, Icons.person_rounded, Icons.person_outline_rounded, "Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label, {
    int? badgeCount,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? const Color(0xFF07274C) : const Color(0xFF64748B),
                  size: 22,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$badgeCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF07274C) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Raised Circular Center Button for "Listings"
  Widget _buildCenterListingItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF07274C),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF07274C).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "Listings",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}