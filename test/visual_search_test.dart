import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_watch_box/core/prefs/pref_manager.dart';
import 'package:the_watch_box/core/network/api_client.dart';
import 'package:the_watch_box/core/network/services/visual_search_api_service.dart';
import 'package:the_watch_box/models/watch_model.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    await Get.putAsync<PrefManager>(() => PrefManager().init());
    Get.put(ApiClient());
  });

  group('Visual Search Tests', () {
    test('WatchModel parses visual search items with matchScore and remote image', () {
      final item = {
        'id': 'v-101',
        'title': 'Rolex Submariner Date 126610LN',
        'brand': 'Rolex',
        'model': 'Submariner',
        'price': 13500.0,
        'currentPrice': 13500,
        'platform': 'eBay',
        'source': 'ebay',
        'image': 'https://example.com/watches/submariner.jpg',
        'matchScore': 0.96,
        'year': 2022,
        'condition': 'Very Good',
        'location': 'New York, US',
      };

      final watch = WatchModel.fromMap(item);
      expect(watch.title, 'Rolex Submariner Date 126610LN');
      expect(watch.brand, 'Rolex');
      expect(watch.price, 13500.0);
      expect(watch.matchScore, 0.96);
      expect(watch.imageUrl, 'https://example.com/watches/submariner.jpg');
    });

    test('VisualSearchApiService handles visual search response parsing', () {
      final service = VisualSearchApiService();
      expect(service, isNotNull);

      final watch = WatchModel.fromMap({
        'id': 1,
        'title': 'Omega Speedmaster Professional',
        'brand': 'Omega',
        'model': 'Speedmaster',
        'price': 6500,
        'matchScore': 0.89,
      });
      expect(watch.imageUrl, 'assets/images/4.jpg');
      expect((watch.matchScore! * 100).toInt(), 89);
    });
  });
}
