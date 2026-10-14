import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/prefs/pref_manager.dart';
import '../../widgets/watch_background.dart';
import '../../profile/subscription_plans_screen.dart';
import '../../profile/account_settings_screen.dart';
import '../../profile/change_password_screen.dart';
import '../../profile/my_listings_screen.dart';
import '../../profile/notifications_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthController _auth = Get.find<AuthController>();
  
  bool _darkMode = false;
  bool _isEbayConnected = true;
  String _selectedCurrency = "USD";

  @override
  void initState() {
    super.initState();
    _darkMode = Get.find<PrefManager>().isDarkMode;
  }

  void _toggleEbayConnection() {
    setState(() {
      _isEbayConnected = !_isEbayConnected;
    });
    Get.snackbar(
      _isEbayConnected ? "eBay Connected" : "eBay Disconnected",
      _isEbayConnected 
          ? "Your eBay trading account has been reconnected." 
          : "Your eBay account was disconnected from live syncing.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
      colorText: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final currencies = [
      {"code": "USD", "name": "US Dollar (\$)", "symbol": "\$"},
      {"code": "EUR", "name": "Euro (â‚¬)", "symbol": "â‚¬"},
      {"code": "GBP", "name": "British Pound (Â£)", "symbol": "Â£"},
      {"code": "CHF", "name": "Swiss Franc (CHF)", "symbol": "CHF"},
      {"code": "JPY", "name": "Japanese Yen (Â¥)", "symbol": "Â¥"},
      {"code": "AED", "name": "UAE Dirham (AED)", "symbol": "AED"},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              "Select Preferred Currency",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ...currencies.map((curr) {
              final isSelected = _selectedCurrency == curr["code"];
              return ListTile(
                title: Text(
                  curr["name"]!,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF07274C) : null,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCurrency = curr["code"]!;
                  });
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Log Out",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: const Text("Are you sure you want to log out of your account?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: Text(
          "Profile & Preferences",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF07274C),
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: WatchBackground(
        showGears: false,
        showDialTicks: true,
        child: Obx(() {
          final user = _auth.currentUser.value;
          final bool isPremium = user?.plan == 'paid';
          final String name = user?.name ?? "Alexander Thorne";
          final String email = name.toLowerCase().contains("alexander")
              ? "customer@example.com"
              : "${name.toLowerCase().replaceAll(' ', '')}@example.com";
          final String role = (user?.role ?? "USER").toUpperCase();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. User Avatar & Info
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 46,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF07274C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Current Membership Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.credit_card_outlined,
                            color: Color(0xFF07274C),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Current Membership",
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPremium ? "Elite Tier" : "Standard Tier",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Status: ACTIVE",
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Get.to(() => const SubscriptionPlansScreen()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF07274C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Upgrade Plan",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. eBay Connected Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isEbayConnected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // eBay Logo Badge
                      Container(
                        width: 48,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(text: 'e', style: TextStyle(color: Color(0xFFE53238))),
                                TextSpan(text: 'b', style: TextStyle(color: Color(0xFF0064D2))),
                                TextSpan(text: 'a', style: TextStyle(color: Color(0xFFF5AF02))),
                                TextSpan(text: 'y', style: TextStyle(color: Color(0xFF86B817))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEbayConnected ? "eBay Connected" : "eBay Disconnected",
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _isEbayConnected 
                                  ? "Connected & Active \u2022 Tap to manage"
                                  : "Disconnected \u2022 Tap to reconnect",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _isEbayConnected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _toggleEbayConnection,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: _isEbayConnected ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isEbayConnected ? Icons.link_off_rounded : Icons.link_rounded,
                                color: _isEbayConnected ? const Color(0xFFEF4444) : const Color(0xFF07274C),
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isEbayConnected ? "Disconnect" : "Connect",
                                style: TextStyle(
                                  color: _isEbayConnected ? const Color(0xFFEF4444) : const Color(0xFF07274C),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Setting Navigation Cards
                _buildSettingCard(
                  context: context,
                  icon: Icons.account_circle_outlined,
                  title: "Account Settings",
                  onTap: () => Get.to(() => const AccountSettingsScreen()),
                ),
                _buildSettingCard(
                  context: context,
                  icon: Icons.lock_outline_rounded,
                  title: "Change Password",
                  onTap: () => Get.to(() => const ChangePasswordScreen()),
                ),
                _buildSettingCard(
                  context: context,
                  icon: Icons.storefront_outlined,
                  title: "My Listings & Dealer Hub",
                  onTap: () => Get.to(() => const MyListingsScreen()),
                ),
                _buildSettingCard(
                  context: context,
                  icon: Icons.sync_alt_rounded,
                  title: "Preferred Currency ($_selectedCurrency)",
                  onTap: () => _showCurrencyPicker(context),
                ),
                _buildSettingCard(
                  context: context,
                  icon: Icons.notifications_none_rounded,
                  title: "Notification Preferences",
                  onTap: () => Get.to(() => const ActivityNotificationsScreen()),
                ),

                // 5. Dark Mode Card
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Dark Mode",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: CupertinoSwitch(
                          value: _darkMode,
                          activeTrackColor: const Color(0xFF07274C),
                          onChanged: (val) {
                            setState(() {
                              _darkMode = val;
                            });
                            final pref = Get.find<PrefManager>();
                            pref.setDarkMode(val);
                            Get.changeThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 6. Log Out Button
                Container(
                  width: double.infinity,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: OutlinedButton(
                    onPressed: _showLogoutConfirmDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Log Out",
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF07274C),
                  size: 21,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF64748B),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}