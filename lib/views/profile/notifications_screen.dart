import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/alert_controller.dart';
import '../../models/alert_model.dart';

class ActivityNotificationsScreen extends StatefulWidget {
  const ActivityNotificationsScreen({super.key});

  @override
  State<ActivityNotificationsScreen> createState() => _ActivityNotificationsScreenState();
}

class _ActivityNotificationsScreenState extends State<ActivityNotificationsScreen> with SingleTickerProviderStateMixin {
  final AlertController _alert = Get.find<AlertController>();
  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _alert.fetchAlerts();
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
    _alert.markAllAsRead();
    Get.snackbar(
      "Marked All",
      "All notifications marked as read.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: context.primaryNav,
      colorText: context.isDarkTheme ? AppColors.backgroundDark : Colors.white,
    );
  }

  String _formatTimeAgo(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) {
        return "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        return "${diff.inHours}h ago";
      } else if (diff.inDays < 7) {
        return "${diff.inDays}d ago";
      } else {
        return "${(diff.inDays / 7).floor()}w ago";
      }
    } catch (_) {
      return "recently";
    }
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
      body: Obx(() {
        if (_alert.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: context.primaryNav),
          );
        }

        final alerts = _alert.alertsList;
        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, size: 64, color: context.borderColor),
                const SizedBox(height: 16),
                Text(
                  "No notifications yet",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "You're all caught up with market updates and price drops.",
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("ACTIVITY ALERTS"),
              ...List.generate(alerts.length, (idx) {
                final alert = alerts[idx];
                return _buildAnimatedCard(alert, idx);
              }),
            ],
          ),
        );
      }),
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

  Widget _buildAnimatedCard(AlertModel alert, int index) {
    final double start = (index * 0.08).clamp(0.0, 0.6);
    final double end = (start + 0.4).clamp(0.0, 1.0);

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ),
    );

    final slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _listAnimController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: _buildNotificationCard(alert),
      ),
    );
  }

  Widget _buildNotificationCard(AlertModel alert) {
    final bool isRead = alert.isRead;
    final bool hasBtn = alert.type == 'price_drop' || alert.type == 'new_listing';

    return Card(
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor, width: 1.0),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () {
          if (!alert.isRead && alert.id != null) {
            _alert.markAsRead(alert.id!);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(alert),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ),
                            Text(
                              _formatTimeAgo(alert.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          alert.message,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.textSecondaryColor,
                            height: 1.4,
                          ),
                        ),
                        if (hasBtn) ...[
                          const SizedBox(height: 12),
                          _buildButton(alert),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }

  Widget _buildAvatar(AlertModel alert) {
    IconData icon;
    Color bg;
    Color fg;

    switch (alert.type.toLowerCase()) {
      case 'price_drop':
        icon = Icons.trending_down_rounded;
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case 'market_shift':
      case 'market_insight':
        icon = Icons.trending_up_rounded;
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case 'new_listing':
        icon = Icons.watch_rounded;
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF10B981);
        break;
      case 'security':
        icon = Icons.shield_outlined;
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.notifications_rounded;
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
    }

    final bool isDark = context.isDarkTheme;
    if (isDark) {
      bg = const Color(0xFF1E293B);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: fg,
        size: 20,
      ),
    );
  }

  Widget _buildButton(AlertModel alert) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () {
          if (!alert.isRead && alert.id != null) {
            _alert.markAsRead(alert.id!);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryNav,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          elevation: 0,
        ),
        child: Text(
          "VIEW DETAILS",
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
