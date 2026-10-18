import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/alert_controller.dart';

class ActivityNotificationsScreen extends StatefulWidget {
  const ActivityNotificationsScreen({super.key});

  @override
  State<ActivityNotificationsScreen> createState() => _ActivityNotificationsScreenState();
}

class _ActivityNotificationsScreenState extends State<ActivityNotificationsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _listAnimController;

  // Exact mockup notifications list
  final List<Map<String, dynamic>> _todayItems = [
    {
      "id": 1,
      "type": "price_drop",
      "title": "Price Drop Alert",
      "message": "The Rolex Submariner 126610LN you followed has dropped by 4.2% to \$12,450.",
      "time": "2h ago",
      "image": "assets/images/5.png", // Submariner
      "hasButton": true,
      "buttonText": "SEE ANALYSIS",
      "isOutlineButton": false,
      "isRead": false,
    },
    {
      "id": 2,
      "type": "market_shift",
      "title": "Market Shift",
      "message": "Patek Philippe Nautilus references are seeing increased volume. Check updated valuations.",
      "time": "5h ago",
      "icon": Icons.trending_up_rounded,
      "iconBg": const Color(0xFF002952),
      "hasButton": false,
      "isRead": false,
    }
  ];

  final List<Map<String, dynamic>> _yesterdayItems = [
    {
      "id": 3,
      "type": "new_listing",
      "title": "New Listing Match",
      "message": "A Mint Condition Omega Speedmaster Moonwatch just entered the market at \$6,200.",
      "time": "1d ago",
      "image": "assets/images/1.png", // Speedmaster
      "hasButton": true,
      "buttonText": "VIEW LISTING",
      "isOutlineButton": true,
      "isRead": true,
    }
  ];

  final List<Map<String, dynamic>> _olderItems = [
    {
      "id": 4,
      "type": "security",
      "title": "Security Alert",
      "message": "Your account was accessed from a new device in Geneva, Switzerland.",
      "time": "3d ago",
      "icon": Icons.person_outline_rounded,
      "iconBg": const Color(0xFFEFF6FF),
      "iconColor": const Color(0xFF2563EB),
      "isRead": true,
    },
    {
      "id": 5,
      "type": "portfolio",
      "title": "Portfolio Update",
      "message": "Your total collection value has increased by \$2,840 this month.",
      "time": "1w ago",
      "icon": Icons.bookmark_outline_rounded,
      "iconBg": const Color(0xFFEFF6FF),
      "iconColor": const Color(0xFF2563EB),
      "isRead": true,
    }
  ];

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  void _markAllAsRead() {
    try {
      Get.find<AlertController>().markAllAsRead();
    } catch (_) {}
    setState(() {
      for (var item in _todayItems) {
        item["isRead"] = true;
      }
      for (var item in _yesterdayItems) {
        item["isRead"] = true;
      }
      for (var item in _olderItems) {
        item["isRead"] = true;
      }
    });
    Get.snackbar(
      "Marked All",
      "All notifications marked as read.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: context.primaryNav,
      colorText: context.isDarkTheme ? AppColors.backgroundDark : Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              "MARK ALL AS READ",
              style: TextStyle(
                color: context.primaryNav,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODAY SECTION
            if (_todayItems.isNotEmpty) ...[
              _buildSectionHeader("TODAY"),
              ...List.generate(_todayItems.length, (idx) {
                final item = _todayItems[idx];
                return _buildAnimatedCard(item, idx, 0);
              }),
              const SizedBox(height: 20),
            ],

            // YESTERDAY SECTION
            if (_yesterdayItems.isNotEmpty) ...[
              _buildSectionHeader("YESTERDAY"),
              ...List.generate(_yesterdayItems.length, (idx) {
                final item = _yesterdayItems[idx];
                return _buildAnimatedCard(item, idx, _todayItems.length);
              }),
              const SizedBox(height: 20),
            ],

            // OLDER SECTION
            if (_olderItems.isNotEmpty) ...[
              _buildSectionHeader("OLDER"),
              ...List.generate(_olderItems.length, (idx) {
                final item = _olderItems[idx];
                return _buildAnimatedCard(item, idx, _todayItems.length + _yesterdayItems.length);
              }),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(Map<String, dynamic> item, int index, int offset) {
    final int delay = offset + index;
    final double start = delay * 0.1;
    final double end = start + 0.5;

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimController,
        curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutBack),
      ),
    );

    final slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _listAnimController,
        curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: _buildNotificationCard(item),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final bool isRead = item["isRead"] ?? true;
    final bool hasBtn = item["hasButton"] ?? false;

    return Card(
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      elevation: 0,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon / Watch Avatar
                _buildAvatar(item),
                const SizedBox(width: 14),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item["title"],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          Text(
                            item["time"],
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item["message"],
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                      if (hasBtn) ...[
                        const SizedBox(height: 12),
                        _buildButton(item),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Unread Blue Dot
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: isRead ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: AnimatedScale(
                scale: isRead ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: context.primaryNav,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> item) {
    final hasImg = item.containsKey("image");
    
    if (hasImg) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          item["image"],
          fit: BoxFit.cover,
        ),
      );
    } else {
      final bool isDark = context.isDarkTheme;
      final Color bg = isDark
          ? (item["iconBg"] == const Color(0xFFEFF6FF)
              ? const Color(0xFF1E3A8A)
              : const Color(0xFF334155))
          : (item["iconBg"] ?? const Color(0xFFEFF6FF));
      final Color fg = isDark
          ? (item["iconColor"] == const Color(0xFF2563EB)
              ? const Color(0xFF93C5FD)
              : Colors.white)
          : (item["iconColor"] ?? Colors.white);
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          item["icon"],
          color: fg,
          size: 20,
        ),
      );
    }
  }

  Widget _buildButton(Map<String, dynamic> item) {
    final bool isOutline = item["isOutlineButton"] ?? false;
    final String text = item["buttonText"];

    if (isOutline) {
      return SizedBox(
        height: 32,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              item["isRead"] = true;
            });
            Get.snackbar(
              "Redirecting",
              "Opening listing details panel...",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: context.primaryNav,
              colorText: context.isDarkTheme ? AppColors.backgroundDark : Colors.white,
            );
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.primaryNav),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: context.primaryNav,
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              item["isRead"] = true;
            });
            Get.snackbar(
              "Opening Analysis",
              "Loading market charts & trend evaluation...",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: context.primaryNav,
              colorText: context.isDarkTheme ? AppColors.backgroundDark : Colors.white,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryNav,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            elevation: 0,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: context.isDarkTheme ? AppColors.backgroundDark : Colors.white,
            ),
          ),
        ),
      );
    }
  }
}
