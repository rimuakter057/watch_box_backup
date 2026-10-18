import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/prefs/pref_manager.dart';
import 'core/theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/search_controller.dart';
import 'controllers/bookmark_controller.dart';
import 'controllers/alert_controller.dart';
import 'controllers/onboarding_controller.dart';
import 'views/splash/splash_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';
import 'views/profile/subscription_plans_screen.dart';
import 'views/profile/notifications_screen.dart';
import 'views/profile/account_settings_screen.dart';
import 'views/profile/change_password_screen.dart';
import 'core/db/db_helper.dart';
import 'core/network/api_client.dart';
import 'core/network/services/auth_api_service.dart';
import 'core/network/services/search_api_service.dart';
import 'core/network/services/visual_search_api_service.dart';
import 'core/network/services/listings_api_service.dart';
import 'core/network/services/recommendations_api_service.dart';
import 'core/network/services/alerts_api_service.dart';
import 'core/network/services/subscriptions_api_service.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized for SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize & Inject PrefManager first (asynchronous service)
  final pref = await Get.putAsync<PrefManager>(() => PrefManager().init());

  // Auto-login Alexander Thorne for developer mockup testing
  try {
    final dbHelper = DbHelper();
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: ['Alexander Thorne'],
    );
    int userId;
    if (maps.isEmpty) {
      userId = await db.insert('users', {
        'name': 'Alexander Thorne',
        'role': 'user',
        'plan': 'paid',
        'status': 'active',
      });
    } else {
      userId = maps.first['id'] as int;
      // Ensure plan is 'paid'
      await db.update('users', {'plan': 'paid'}, where: 'id = ?', whereArgs: [userId]);
    }

    // Ensure two sold listings for Alexander Thorne exist for verification testing
    // Listing 1 (with pre-generated invoice): Patek Philippe Nautilus
    final List<Map<String, dynamic>> existingNautilus = await db.query(
      'listings',
      where: 'user_id = ? AND title = ?',
      whereArgs: [userId, 'Patek Philippe Nautilus 5711/1A'],
    );
    if (existingNautilus.isEmpty) {
      final listingId = await db.insert('listings', {
        'user_id': userId,
        'title': 'Patek Philippe Nautilus 5711/1A',
        'brand': 'Patek Philippe',
        'model': 'Nautilus',
        'price': 119000.0,
        'platform': 'In-App',
        'year': 2020,
        'condition': 'Mint',
        'location': 'Geneva, Switzerland',
        'is_sold': 1,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await db.insert('invoices', {
        'listing_id': listingId,
        'buyer_name': 'Marcus Aurelius',
        'buyer_email': 'marcus@rome.gov',
        'invoice_no': 'INV-2026-8891',
        'date': '2026-06-11',
        'price': 119000.0,
      });
    }

    // Listing 2 (without invoice, pending details): Rolex Daytona
    final List<Map<String, dynamic>> existingDaytona = await db.query(
      'listings',
      where: 'user_id = ? AND title = ?',
      whereArgs: [userId, 'Rolex Daytona 116500LN Panda Dial'],
    );
    if (existingDaytona.isEmpty) {
      await db.insert('listings', {
        'user_id': userId,
        'title': 'Rolex Daytona 116500LN Panda Dial',
        'brand': 'Rolex',
        'model': 'Daytona',
        'price': 29500.0,
        'platform': 'In-App',
        'year': 2022,
        'condition': 'Mint',
        'location': 'London, UK',
        'is_sold': 1,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    await pref.setActiveUserId(userId);
    await pref.setActiveUserName('Alexander Thorne');
    await pref.setActiveUserRole('user');
    await pref.setActiveUserPlan('paid');
  } catch (e) {
    print("Auto-login error: $e");
  }

  // 1.1 Initialize Network API Client & Domain Services
  Get.put(ApiClient());
  Get.put(AuthApiService());
  Get.put(SearchApiService());
  Get.put(VisualSearchApiService());
  Get.put(ListingsApiService());
  Get.put(RecommendationsApiService());
  Get.put(AlertsApiService());
  Get.put(SubscriptionsApiService());
  // 2. Pre-instantiate core Controllers for global availability
  Get.put(AuthController());
  Get.put(WatchSearchController());
  Get.put(BookmarkController());
  Get.put(AlertController());

  runApp(const TheWatchBoxApp());
}

class TheWatchBoxApp extends StatelessWidget {
  const TheWatchBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final pref = Get.find<PrefManager>();
        return GetMaterialApp(
          title: 'The Watch Box',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: pref.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/splash',
          getPages: [
            GetPage(
              name: '/splash',
              page: () => const SplashScreen(),
            ),
            GetPage(
              name: '/onboarding',
              page: () => const OnboardingScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => OnboardingController());
              }),
            ),
            GetPage(
              name: '/login',
              page: () => const LoginScreen(),
            ),
            GetPage(
              name: '/home',
              page: () => const MainContainerScreen(),
            ),
            GetPage(
              name: '/subscription_plans',
              page: () => const SubscriptionPlansScreen(),
            ),
            GetPage(
              name: '/notifications',
              page: () => const ActivityNotificationsScreen(),
            ),
            GetPage(
              name: '/account_settings',
              page: () => const AccountSettingsScreen(),
            ),
            GetPage(
              name: '/change_password',
              page: () => const ChangePasswordScreen(),
            ),
          ],
        );
      },
    );
  }
}
