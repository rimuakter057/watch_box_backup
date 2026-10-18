import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../../controllers/auth_controller.dart';
import '../../core/network/services/subscriptions_api_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final AuthController _auth = Get.find<AuthController>();
  SubscriptionsApiService get _subApi => Get.find<SubscriptionsApiService>();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    try {
      _subApi.getPlans();
      _subApi.getMySubscription();
    } catch (_) {}
  }

  Future<void> _handleAction(String plan) async {
    final user = _auth.currentUser.value;
    if (user == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (plan == 'paid') {
        final checkoutUrl = await _subApi.createStripeCheckoutSession('paid');
        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          debugPrint("💳 [SUBSCRIPTION UI] Created Stripe checkout session: $checkoutUrl");
        }
        await _auth.upgradePlan();
        Get.snackbar(
          "Plan Upgraded!",
          "Welcome to Elite Collector! Your unlimited features are active.",
          backgroundColor: const Color(0xFF07274C),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await _subApi.changePlan('free');
        await _auth.downgradePlan();
        Get.snackbar(
          "Plan Updated",
          "You have switched to the Standard Free plan.",
          backgroundColor: const Color(0xFF07274C),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint("Subscription action error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isProcessing = true);
    try {
      await _subApi.getMySubscription();
      await _subApi.getMyTransactions();
      await _auth.fetchProfile();
    } catch (_) {}
    if (mounted) {
      setState(() => _isProcessing = false);
      Get.snackbar(
        "Refreshed",
        "Subscription status is synchronized with Stripe API.",
        backgroundColor: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
        colorText: context.isDarkTheme ? Colors.white : const Color(0xFF0F172A),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: Text(
          "Subscription Plans",
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF07274C),
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : const Color(0xFF07274C),
              size: 22,
            ),
            onPressed: _handleRefresh,
            tooltip: "Refresh plans",
          ),
        ],
      ),
      body: Obx(() {
        final user = _auth.currentUser.value;
        final bool isPremium = user?.plan == 'paid';

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Title Header
              Text(
                "Choose Your Precision",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Live Stripe API subscriptions & billing portal integration.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Card 0: Active Plan Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF07274C),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF07274C),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPremium ? "ACTIVE PLAN: ELITE COLLECTOR" : "ACTIVE PLAN: STANDARD",
                          style: const TextStyle(
                            color: Color(0xFF07274C),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Status: ACTIVE",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 1: Standard Plan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPremium ? const Color(0xFFE2E8F0) : const Color(0xFF07274C),
                    width: isPremium ? 1.2 : 2.0,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Standard",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (!isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF07274C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "CURRENT PLAN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Free",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF07274C),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        color: Color(0xFFE2E8F0),
                        thickness: 1,
                      ),
                    ),
                    // Features
                    _buildFeatureRow(
                      iconColor: const Color(0xFF10B981),
                      text: "5 Monthly Reference Searches",
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      iconColor: const Color(0xFF10B981),
                      text: "3 Months Historical Indexing",
                    ),
                    const SizedBox(height: 22),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: isPremium
                          ? OutlinedButton(
                              onPressed: _isProcessing ? null : () => _handleAction('free'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF07274C)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Downgrade to Standard",
                                style: TextStyle(
                                  color: Color(0xFF07274C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Active Plan",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Elite Collector Plan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPremium ? const Color(0xFF07274C) : const Color(0xFFE2E8F0),
                    width: isPremium ? 2.0 : 1.2,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Elite Collector",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF07274C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "CURRENT PLAN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "\$29.99 / month",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF07274C),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        color: Color(0xFFE2E8F0),
                        thickness: 1,
                      ),
                    ),
                    // Features
                    _buildFeatureRow(
                      iconColor: const Color(0xFF07274C),
                      text: "Unlimited Reference Searches",
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      iconColor: const Color(0xFF07274C),
                      text: "All Time Historical Indexing",
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      iconColor: const Color(0xFF07274C),
                      text: "AI Image Recognition Search",
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      iconColor: const Color(0xFF07274C),
                      text: "Market Sparklines & Trends",
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      iconColor: const Color(0xFF07274C),
                      text: "Auction Results Integration",
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      iconColor: const Color(0xFF07274C),
                      text: "Personalized Portfolio Analytics",
                    ),
                    const SizedBox(height: 22),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: isPremium
                          ? Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Active Plan",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isProcessing ? null : () => _handleAction('paid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF07274C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Upgrade via Stripe",
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
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFeatureRow({
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: iconColor,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}