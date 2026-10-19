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
import '../../chat/chat_screen.dart';
import '../../chat/conversations_screen.dart';
import 'package:image_picker/image_picker.dart';

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
    final pref = Get.find<PrefManager>();
    _darkMode = pref.isDarkMode;
    _selectedCurrency = pref.preferredCurrency;
    debugPrint("📱 [PROFILE TAB] Initializing ProfileTab -> Initial Currency: $_selectedCurrency | DarkMode: $_darkMode");
    _auth.fetchProfile().then((u) {
      if (mounted && u != null) {
        setState(() {
          _darkMode = u.darkMode;
          _selectedCurrency = u.currency;
        });
        debugPrint("📱 [PROFILE TAB] ProfileTab state updated with live backend profile -> Name: ${u.name} | Currency: ${u.currency} | Dark: ${u.darkMode}");
      }
    });
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

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final filename = image.name;

      Get.showOverlay(
        asyncFunction: () async {
          await _auth.updateAvatar(bytes, filename);
        },
        loadingWidget: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07274C)),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ [PROFILE TAB] Image pick error: $e");
      Get.snackbar("Error", "Could not pick image: $e");
    }
  }

  void _showProfilePhotoPicker() {
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
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Change Profile Photo",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: Color(0xFF07274C)),
              title: const Text("Take Photo", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF07274C)),
              title: const Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final currencies = [
      {"code": "USD", "name": "US Dollar (\$)", "symbol": "\$"},
      {"code": "EUR", "name": "Euro (€)", "symbol": "€"},
      {"code": "GBP", "name": "British Pound (£)", "symbol": "£"},
      {"code": "CHF", "name": "Swiss Franc (CHF)", "symbol": "CHF"},
      {"code": "JPY", "name": "Japanese Yen (¥)", "symbol": "¥"},
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
                  final newCurr = curr["code"]!;
                  debugPrint("📱 [PROFILE TAB] User picked preferred currency: $newCurr");
                  setState(() {
                    _selectedCurrency = newCurr;
                  });
                  _auth.updatePreferences(currency: newCurr);
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
          final bool isPremium = user?.isPaid ?? false;
          final String name = user?.name.isNotEmpty == true ? user!.name : (user != null ? "Collector" : "");
          final String email = user?.email.isNotEmpty == true ? user!.email : "";
          final String role = (user?.role ?? "USER").toUpperCase();
          final String? avatarUrl = user?.avatarUrl;
          final String? country = user?.country;
          final String? phone = user?.phone;
          final bool emailVerified = user?.emailVerified ?? false;

          return RefreshIndicator(
            onRefresh: () async {
              debugPrint("📱 [PROFILE TAB] Pull-to-refresh: Syncing user profile from backend...");
              await _auth.fetchProfile();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. User Avatar & Info (Interactive Profile Picture Change)
                  Center(
                    child: GestureDetector(
                      onTap: _showProfilePhotoPicker,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF07274C),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(
                                      avatarUrl,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : (user != null ? "C" : "U"),
                                          style: TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF07274C),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : (user != null ? "C" : "U"),
                                        style: TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF07274C),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          // Camera edit button badge
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF07274C),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                          if (emailVerified)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
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
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (country != null && country.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          country,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  icon: Icons.chat_bubble_outline_rounded,
                  title: "Messages & Dealer Chats",
                  onTap: () => Get.to(() => const ConversationsScreen()),
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
                            debugPrint("📱 [PROFILE TAB] Dark mode switch toggled: $val");
                            setState(() {
                              _darkMode = val;
                            });
                            _auth.updatePreferences(darkMode: val);
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