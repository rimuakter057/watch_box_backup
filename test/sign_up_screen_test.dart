import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_watch_box/controllers/auth_controller.dart';
import 'package:the_watch_box/core/prefs/pref_manager.dart';
import 'package:the_watch_box/core/network/services/auth_api_service.dart';
import 'package:the_watch_box/core/network/services/subscriptions_api_service.dart';
import 'package:the_watch_box/core/network/api_client.dart';
import 'package:the_watch_box/views/auth/sign_up_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    await Get.putAsync<PrefManager>(() => PrefManager().init());
    Get.put(ApiClient());
    Get.put(AuthApiService());
    Get.put(SubscriptionsApiService());
    Get.put(AuthController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('SignUpScreen renders all required API form fields and controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: SignUpScreen(),
      ),
    );

    await tester.pump();

    // Verify Title & Subtitle
    expect(find.text('The Watch Box'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('SECURE API'), findsOneWidget);

    // Verify Form Fields
    expect(find.text('Full Name / Display Name *'), findsOneWidget);
    expect(find.text('Email Address *'), findsOneWidget);
    expect(find.text('Phone Number (Optional)'), findsOneWidget);
    expect(find.text('Country / Regional Hub'), findsOneWidget);
    expect(find.text('Password * (Min 8 characters)'), findsOneWidget);
    expect(find.text('Confirm Password *'), findsOneWidget);

    // Verify Register Button
    expect(find.text('Complete Registration'), findsOneWidget);
  });
}
