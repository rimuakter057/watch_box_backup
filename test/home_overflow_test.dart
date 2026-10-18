import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_watch_box/controllers/alert_controller.dart';
import 'package:the_watch_box/controllers/auth_controller.dart';
import 'package:the_watch_box/controllers/bookmark_controller.dart';
import 'package:the_watch_box/controllers/search_controller.dart';
import 'package:the_watch_box/core/network/api_client.dart';
import 'package:the_watch_box/core/network/services/listings_api_service.dart';
import 'package:the_watch_box/core/prefs/pref_manager.dart';
import 'package:the_watch_box/views/home/tabs/home_tab.dart';
import 'package:the_watch_box/views/widgets/navbar/custom_navbar.dart';

void main() {
  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'auth_token': 'test_token',
      'username': 'HorologyCollectorVeryLongNameThatCouldOverflow',
    });
    await Get.putAsync<PrefManager>(() => PrefManager().init());
    Get.put(ApiClient());
    Get.put(ListingsApiService());
    Get.put(AuthController());
    Get.put(WatchSearchController());
    Get.put(BookmarkController());
    Get.put(AlertController());
  });

  testWidgets('HomeTab renders without overflow on narrow viewport and high font scale', (WidgetTester tester) async {
    // 320px width represents narrow mobile devices
    tester.view.physicalSize = const Size(320 * 2, 700 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.2),
          ),
          child: const Scaffold(
            body: HomeTab(),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('CustomNavBar renders without overflow on narrow screen and high font scale', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.25),
          ),
          child: Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: CustomNavBar(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomNavBar), findsOneWidget);
  });
}
