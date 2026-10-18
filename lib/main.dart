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
import 'core/network/services/chat_api_service.dart';
import 'core/network/socket_service.dart';
import 'controllers/chat_controller.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized for SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize & Inject PrefManager first (asynchronous service)
  final pref = await Get.putAsync<PrefManager>(() => PrefManager().init());

  // 1.1 Initialize Network API Client & Domain Services
  Get.put(ApiClient());
  Get.put(AuthApiService());
  Get.put(SearchApiService());
  Get.put(VisualSearchApiService());
  Get.put(ListingsApiService());
  Get.put(RecommendationsApiService());
  Get.put(AlertsApiService());
  Get.put(SubscriptionsApiService());
  Get.put(ChatApiService());
  Get.put(SocketService());

  // 2. Pre-instantiate core Controllers for global availability
  final authController = Get.put(AuthController());
  Get.put(WatchSearchController());
  Get.put(BookmarkController());
  Get.put(AlertController());
  Get.put(ChatController());

  // 3. Restore session state via PrefManager using stored JWT token
  if (pref.hasToken || pref.activeUserId != null) {
    await authController.restoreSession();
  }

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
