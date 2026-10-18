import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_watch_box/core/prefs/pref_manager.dart';
import 'package:the_watch_box/core/network/api_client.dart';
import 'package:the_watch_box/core/network/services/listings_api_service.dart';
import 'package:the_watch_box/models/watch_model.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'auth_access_token': 'mock_token'});
    await Get.putAsync<PrefManager>(() => PrefManager().init());
    Get.put(ApiClient());
    Get.put(ListingsApiService());
  });

  group('Marketplace and Listings Tests', () {
    test('WatchModel parses in-app and marketplace listings correctly', () {
      final item = {
        'id': 'listing-501',
        'title': 'Rolex Daytona 116500LN',
        'brand': 'Rolex',
        'model': 'Daytona',
        'price': 34500.0,
        'platform': 'In-App',
        'year': 2023,
        'condition': 'Unworn',
        'location': 'Geneva, Switzerland',
        'image': 'https://images.example.com/daytona.jpg',
        'isSold': false,
      };

      final watch = WatchModel.fromMap(item);
      expect(watch.title, 'Rolex Daytona 116500LN');
      expect(watch.brand, 'Rolex');
      expect(watch.platform, 'In-App');
      expect(watch.price, 34500.0);
      expect(watch.isSold, isFalse);
      expect(watch.imageUrl, 'https://images.example.com/daytona.jpg');
    });

    test('WatchModel accurately reflects sold status', () {
      final soldItem = {
        'id': 'listing-502',
        'title': 'Patek Philippe Nautilus 5711',
        'brand': 'Patek Philippe',
        'model': 'Nautilus',
        'price': 115000.0,
        'platform': 'In-App',
        'is_sold': 1,
      };

      final watch = WatchModel.fromMap(soldItem);
      expect(watch.isSold, isTrue);
    });

    test('ListingsApiService instance is registered and operational', () {
      final service = Get.find<ListingsApiService>();
      expect(service, isNotNull);
    });

    test('Listing API payload contains exact backend expected fields', () {
      final payload = {
        'title': 'Rolex Submariner Date 126610LN',
        'brand': 'Rolex',
        'model': 'Submariner',
        'referenceNumber': '126610LN',
        'price': 14250.0,
        'currency': 'USD',
        'year': 2023,
        'condition': 'Mint',
        'description': 'Full set with warranty card and original box.',
      };

      expect(payload['title'], 'Rolex Submariner Date 126610LN');
      expect(payload['brand'], 'Rolex');
      expect(payload['model'], 'Submariner');
      expect(payload['referenceNumber'], '126610LN');
      expect(payload['price'], 14250.0);
      expect(payload['currency'], 'USD');
      expect(payload['year'], 2023);
      expect(payload['condition'], 'Mint');
      expect(payload['description'], isNotEmpty);
    });

    test('WatchModel parses full API listing object with image and reference', () {
      final apiListing = {
        'id': 'listing-999',
        'title': 'Cartier Santos Medium',
        'brand': 'Cartier',
        'model': 'Santos',
        'referenceNumber': 'WSSA0029',
        'price': 7200,
        'currency': 'USD',
        'image': 'https://api.mywatchbox.net/uploads/santos.jpg',
        'condition': 'Mint',
        'year': 2022,
        'isSold': false,
      };

      final watch = WatchModel.fromMap(apiListing);
      expect(watch.title, 'Cartier Santos Medium');
      expect(watch.brand, 'Cartier');
      expect(watch.model, 'Santos');
      expect(watch.price, 7200.0);
      expect(watch.imageUrl, 'https://api.mywatchbox.net/uploads/santos.jpg');
      expect(watch.condition, 'Mint');
      expect(watch.year, 2022);
    });

    test('WatchModel parses backend API response with nested data object', () {
      final backendResponseItem = {
        "id": "6a9049db67026d4af0f4ba54",
        "resource": "listings",
        "ownerId": "6a79c8f027c5edce74d06942",
        "scope": {},
        "data": {
          "title": "TEST 20365",
          "price": 10003,
          "currency": "USD",
          "condition": "mint",
          "platform": "eBay",
          "referenceNumber": "16013",
          "image": null
        },
        "status": "active",
        "createdAt": "2026-08-27T14:29:47.918Z",
        "updatedAt": "2026-08-27T14:29:47.918Z",
        "owner": {
          "id": "6a79c8f027c5edce74d06942",
          "username": "watchcollector",
          "email": "collector@example.com"
        }
      };

      final watch = WatchModel.fromMap(backendResponseItem);
      expect(watch.idString, '6a9049db67026d4af0f4ba54');
      expect(watch.title, 'TEST 20365');
      expect(watch.price, 10003.0);
      expect(watch.currency, 'USD');
      expect(watch.condition, 'Mint');
      expect(watch.platform, 'eBay');
      expect(watch.referenceNumber, '16013');
      expect(watch.ownerId, '6a79c8f027c5edce74d06942');
      expect(watch.ownerName, 'watchcollector');
      expect(watch.isSold, isFalse);
      expect(watch.isEbay, isTrue);
      expect(watch.isInApp, isFalse);
      expect(watch.marketplaceDisplayName, 'eBay Marketplace');
    });

    test('WatchModel identifies in-app peer trader listing correctly', () {
      final inAppItem = {
        "id": "6a9049db67026d4af0f4ba99",
        "resource": "listings",
        "ownerId": "6a79c8f027c5edce74d06942",
        "data": {
          "title": "Rolex Submariner 124060",
          "price": 12500,
          "currency": "USD",
          "condition": "mint",
          "platform": "in-app",
          "referenceNumber": "124060",
        },
        "status": "active",
      };

      final watch = WatchModel.fromMap(inAppItem);
      expect(watch.isEbay, isFalse);
      expect(watch.isInApp, isTrue);
      expect(watch.marketplaceDisplayName, 'In-App Listing');
      expect(watch.platformColor, const Color(0xFFD97706));
    });

    test('WatchModel generates proper eBay redirectUrl', () {
      final ebayItem = {
        'id': 'v1|123456789|0',
        'title': 'Rolex Sapphire Crystal 25-295-CAR',
        'source': 'ebay',
        'sourceUrl': 'https://www.ebay.com/itm/123456789',
        'price': 148.0,
      };

      final watch = WatchModel.fromMap(ebayItem);
      expect(watch.isEbay, isTrue);
      expect(watch.isInApp, isFalse);
      expect(watch.redirectUrl, 'https://www.ebay.com/itm/123456789');

      // Test fallback eBay redirect link when sourceUrl is absent
      final ebayNoUrl = {
        'id': '987654321',
        'title': 'Omega Speedmaster Professional',
        'platform': 'eBay',
        'price': 5200.0,
      };
      final watchFallback = WatchModel.fromMap(ebayNoUrl);
      expect(watchFallback.isEbay, isTrue);
      expect(watchFallback.redirectUrl, 'https://www.ebay.com/itm/987654321');
    });

    test('WatchModel parses saved-products record correctly without crashing on null int id', () {
      final savedProductRecord = {
        "id": "6a9049db67026d4af0f4ba88",
        "resource": "saved-products",
        "ownerId": "6a79c8f027c5edce74d06942",
        "scope": {
          "source": "ebay",
          "productId": "v1|33445566|0"
        },
        "data": {
          "source": "ebay",
          "id": "v1|33445566|0",
          "productId": "v1|33445566|0",
          "title": "Rolex Sapphire Crystal 25-295-CAR Submariner GMT",
          "price": 148,
          "currency": "USD",
          "sourceUrl": "https://www.ebay.com/itm/33445566"
        }
      };

      final watch = WatchModel.fromMap(savedProductRecord);
      expect(watch.id, isNull);
      expect(watch.idString, 'v1|33445566|0');
      expect(watch.isEbay, isTrue);
      expect(watch.isInApp, isFalse);
      expect(watch.marketplaceDisplayName, 'eBay Marketplace');
      expect(watch.redirectUrl, 'https://www.ebay.com/itm/33445566');
    });

    test('ApiClient handles session refresh check correctly', () async {
      final client = ApiClient.to;
      expect(client, isNotNull);

      final pref = Get.find<PrefManager>();
      await pref.setRefreshToken(null);
      final failedRefresh = await client.attemptTokenRefresh();
      expect(failedRefresh, isFalse);
    });
  });
}
