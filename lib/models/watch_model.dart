import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_colors.dart';

class WatchModel {
  final int? id;
  final String? stringId;
  final int? userId;
  final String? ownerId;
  final String? ownerName;
  final String title;
  final String brand;
  final String model;
  final double price;
  final String currency;
  final String platform; // 'Chrono24', 'eBay', 'Grailzee', 'In-App'
  final int year;
  final String condition; // 'New', 'Mint', 'Very Good', 'Good', 'Fair'
  final String location;
  final bool isSold;
  final String timestamp;
  final String? rawImage;
  final double? matchScore;
  final String? referenceNumber;
  final String? description;
  final String? sourceUrl;

  WatchModel({
    this.id,
    this.stringId,
    this.userId,
    this.ownerId,
    this.ownerName,
    required this.title,
    required this.brand,
    required this.model,
    required this.price,
    this.currency = 'USD',
    required this.platform,
    required this.year,
    required this.condition,
    required this.location,
    required this.isSold,
    required this.timestamp,
    this.rawImage,
    this.matchScore,
    this.referenceNumber,
    this.description,
    this.sourceUrl,
  });

  String get idString => stringId ?? (id != null ? id.toString() : '');

  String? get redirectUrl {
    if (sourceUrl != null && sourceUrl!.isNotEmpty && sourceUrl!.startsWith('http')) {
      return sourceUrl;
    }
    if (isEbay) {
      final itemId = stringId ?? (id != null ? id.toString() : '');
      if (itemId.isNotEmpty) {
        final cleanId = itemId.replaceFirst('ebay:', '');
        return 'https://www.ebay.com/itm/$cleanId';
      }
    }
    return null;
  }

  bool get isEbay {
    final p = platform.toLowerCase();
    return p == 'ebay' || p.contains('ebay');
  }

  bool get isInApp {
    if (isEbay) return false;
    final p = platform.toLowerCase();
    if (p.contains('chrono24') || p.contains('grailzee')) return false;
    return p == 'in-app' || p == 'local' || p.isEmpty || userId != null || ownerId != null;
  }

  String get marketplaceDisplayName {
    if (isEbay) return 'eBay Marketplace';
    if (isInApp) return 'In-App Listing';
    if (platform.toLowerCase().contains('chrono24')) return 'Chrono24';
    if (platform.toLowerCase().contains('grailzee')) return 'Grailzee';
    return platform.isNotEmpty ? platform : 'In-App Listing';
  }

  factory WatchModel.fromMap(Map<String, dynamic> map) {
    // 1. Unwrap nested 'data' and 'scope' objects if backend wraps listing attributes
    final innerData = (map['data'] is Map)
        ? Map<String, dynamic>.from(map['data'] as Map)
        : null;
    final scope = (map['scope'] is Map)
        ? Map<String, dynamic>.from(map['scope'] as Map)
        : null;

    // 2. ID parsing (support hex string MongoDB IDs & standard integer IDs)
    final bool isSavedRecord = map['resource'] == 'saved-products';
    final rawId = isSavedRecord
        ? (innerData?['productId'] ?? innerData?['id'] ?? scope?['productId'] ?? map['id'] ?? map['_id'])
        : (innerData?['id'] ?? innerData?['_id'] ?? innerData?['productId'] ?? map['id'] ?? map['_id'] ?? scope?['productId']);
    int? parsedId;
    String? stringId;
    if (rawId != null) {
      stringId = rawId.toString();
      parsedId = int.tryParse(stringId);
    }

    // 3. User & Owner ID parsing
    int? parsedUserId;
    final rawUserId = map['user_id'] ?? map['userId'] ?? innerData?['user_id'] ?? innerData?['userId'];
    if (rawUserId is int) {
      parsedUserId = rawUserId;
    } else if (rawUserId != null) {
      parsedUserId = int.tryParse(rawUserId.toString());
    }

    final rawOwner = map['owner'] is Map
        ? Map<String, dynamic>.from(map['owner'] as Map)
        : (innerData?['owner'] is Map ? Map<String, dynamic>.from(innerData!['owner'] as Map) : null);
    final String? parsedOwnerId = isSavedRecord
        ? (innerData?['ownerId'] ?? innerData?['owner_id'])?.toString()
        : (map['ownerId'] ?? map['owner_id'] ?? innerData?['ownerId'] ?? innerData?['owner_id'] ?? rawOwner?['id'] ?? rawOwner?['_id'])?.toString();
    final String? parsedOwnerName = (rawOwner?['username'] ?? rawOwner?['name'] ?? rawOwner?['email'])?.toString();

    // 4. Price parsing
    double parsedPrice = 0.0;
    final rawPrice = innerData?['price'] ??
        map['price'] ??
        innerData?['currentPrice'] ??
        map['currentPrice'] ??
        innerData?['marketAveragePrice'] ??
        map['marketAveragePrice'] ??
        innerData?['lowestPrice'] ??
        map['lowestPrice'];
    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice != null) {
      parsedPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    }

    // 5. Currency
    final parsedCurrency = (innerData?['currency'] ?? map['currency'] ?? 'USD').toString();

    // 6. Year
    int parsedYear = DateTime.now().year;
    final rawYear = innerData?['year'] ?? map['year'] ?? innerData?['productionYear'] ?? map['productionYear'];
    if (rawYear is int) {
      parsedYear = rawYear;
    } else if (rawYear is num) {
      parsedYear = rawYear.toInt();
    } else if (rawYear != null) {
      parsedYear = int.tryParse(rawYear.toString()) ?? parsedYear;
    }

    // 7. Sold status
    bool parsedIsSold = false;
    final rawStatus = (map['status'] ?? innerData?['status'] ?? '').toString().toLowerCase();
    final rawSold = innerData?['is_sold'] ?? innerData?['isSold'] ?? innerData?['sold'] ?? map['is_sold'] ?? map['isSold'] ?? map['sold'];
    if (rawStatus == 'sold') {
      parsedIsSold = true;
    } else if (rawSold is bool) {
      parsedIsSold = rawSold;
    } else if (rawSold is num) {
      parsedIsSold = rawSold == 1;
    }

    // 8. Match score for visual search
    double? parsedMatchScore;
    final rawScore = innerData?['matchScore'] ?? map['matchScore'] ?? innerData?['similarityScore'] ?? map['similarityScore'] ?? map['confidence'];
    if (rawScore is num) {
      parsedMatchScore = rawScore.toDouble();
    } else if (rawScore != null) {
      parsedMatchScore = double.tryParse(rawScore.toString());
    }

    // 9. Reference number & Description
    final parsedRef = (innerData?['referenceNumber'] ?? innerData?['ref'] ?? map['referenceNumber'] ?? map['ref'] ?? '').toString().trim();
    final parsedDesc = (innerData?['description'] ?? map['description'] ?? '').toString().trim();

    // 10. Title, Brand, Model inference
    final parsedTitle = (innerData?['title'] ?? map['title'] ?? innerData?['name'] ?? map['name'] ?? 'Luxury Timepiece').toString().trim();
    String parsedBrand = (innerData?['brand'] ?? map['brand'] ?? '').toString().trim();
    String parsedModel = (innerData?['model'] ?? map['model'] ?? '').toString().trim();

    if (parsedBrand.isEmpty) {
      final lowerTitle = parsedTitle.toLowerCase();
      if (lowerTitle.contains('rolex') || parsedRef.startsWith('16') || parsedRef.startsWith('11') || parsedRef.startsWith('12')) {
        parsedBrand = 'Rolex';
      } else if (lowerTitle.contains('omega') || lowerTitle.contains('speedmaster') || lowerTitle.contains('seamaster')) {
        parsedBrand = 'Omega';
      } else if (lowerTitle.contains('patek') || lowerTitle.contains('nautilus') || lowerTitle.contains('aquanaut')) {
        parsedBrand = 'Patek Philippe';
      } else if (lowerTitle.contains('audemars') || lowerTitle.contains('royal oak')) {
        parsedBrand = 'Audemars Piguet';
      } else if (lowerTitle.contains('cartier') || lowerTitle.contains('santos') || lowerTitle.contains('tank')) {
        parsedBrand = 'Cartier';
      } else if (lowerTitle.contains('breitling') || lowerTitle.contains('navitimer')) {
        parsedBrand = 'Breitling';
      } else if (lowerTitle.contains('tudor') || lowerTitle.contains('black bay')) {
        parsedBrand = 'Tudor';
      } else {
        final words = parsedTitle.split(' ');
        if (words.isNotEmpty && words.first.isNotEmpty && words.first.length > 2) {
          parsedBrand = words.first;
        } else {
          parsedBrand = 'WatchBox';
        }
      }
    }

    if (parsedModel.isEmpty) {
      if (parsedRef.isNotEmpty) {
        parsedModel = 'Ref. $parsedRef';
      } else {
        parsedModel = parsedTitle;
      }
    }

    // 11. Platform
    final rawPlatform = (innerData?['platform'] ??
            innerData?['source'] ??
            innerData?['marketplace'] ??
            scope?['source'] ??
            map['platform'] ??
            map['source'] ??
            map['marketplace'] ??
            (map['resource'] == 'listings' ? 'In-App' : ''))
        .toString()
        .trim();
    final finalPlatform = rawPlatform.isEmpty ? 'In-App' : rawPlatform;

    // 12. Condition & Location
    final rawCondition = (innerData?['condition'] ?? map['condition'] ?? 'Very Good').toString();
    final capitalizedCondition = rawCondition.isEmpty
        ? 'Very Good'
        : (rawCondition[0].toUpperCase() + (rawCondition.length > 1 ? rawCondition.substring(1) : ''));

    final parsedLocation = (innerData?['location'] ?? map['location'] ?? rawOwner?['location'] ?? 'Global').toString();

    // 13. Timestamp
    final parsedTimestamp = (map['createdAt'] ?? map['timestamp'] ?? innerData?['createdAt'] ?? DateTime.now().toIso8601String()).toString();

    // 14. Image
    final parsedImage = (innerData?['image'] ?? innerData?['imageUrl'] ?? innerData?['photoUrl'] ?? map['image'] ?? map['imageUrl'] ?? map['photoUrl'])?.toString();

    // 15. Source / Redirect URL
    final parsedSourceUrl = (innerData?['sourceUrl'] ??
            innerData?['url'] ??
            innerData?['itemWebUrl'] ??
            innerData?['originalUrl'] ??
            map['sourceUrl'] ??
            map['url'] ??
            map['itemWebUrl'] ??
            map['originalUrl'])
        ?.toString();

    return WatchModel(
      id: parsedId,
      stringId: stringId,
      userId: parsedUserId,
      ownerId: parsedOwnerId,
      ownerName: parsedOwnerName,
      title: parsedTitle,
      brand: parsedBrand,
      model: parsedModel,
      price: parsedPrice,
      currency: parsedCurrency,
      platform: finalPlatform,
      year: parsedYear,
      condition: capitalizedCondition,
      location: parsedLocation,
      isSold: parsedIsSold,
      timestamp: parsedTimestamp,
      rawImage: parsedImage,
      matchScore: parsedMatchScore,
      referenceNumber: parsedRef.isNotEmpty ? parsedRef : null,
      description: parsedDesc.isNotEmpty ? parsedDesc : null,
      sourceUrl: parsedSourceUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (stringId != null) 'string_id': stringId,
      if (userId != null) 'user_id': userId,
      if (ownerId != null) 'ownerId': ownerId,
      if (ownerName != null) 'ownerName': ownerName,
      'title': title,
      'brand': brand,
      'model': model,
      'price': price,
      'currency': currency,
      'platform': platform,
      'year': year,
      'condition': condition,
      'location': location,
      'is_sold': isSold ? 1 : 0,
      'timestamp': timestamp,
      if (rawImage != null) 'image': rawImage,
      if (matchScore != null) 'matchScore': matchScore,
      if (referenceNumber != null) 'referenceNumber': referenceNumber,
      if (description != null) 'description': description,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
    };
  }

  /// Returns a local asset path or remote URL for this watch based on brand/model.
  String get imageUrl {
    if (rawImage != null && rawImage!.isNotEmpty) {
      return rawImage!;
    }
    final b = brand.toLowerCase();
    final m = model.toLowerCase();
    final t = title.toLowerCase();

    if (b.contains("rolex")) {
      if (m.contains("gmt") || t.contains("gmt")) {
        return "assets/images/1.png";
      } else if (m.contains("daytona") || t.contains("daytona")) {
        return "assets/images/2.png";
      }
      return "assets/images/rolex_watch.png";
    } else if (b.contains("omega")) {
      if (m.contains("seamaster") || t.contains("seamaster")) {
        return "assets/images/3.jpg";
      }
      return "assets/images/4.jpg";
    } else if (b.contains("patek") || b.contains("philip")) {
      return "assets/images/5.png";
    } else if (b.contains("audemars") || b.contains("ap") || b.contains("piguet")) {
      return "assets/images/6.jpg";
    } else if (b.contains("cartier")) {
      return "assets/images/7.png";
    }
    return "assets/images/8.png";
  }

  Color get platformColor {
    final bool isDark = Get.isDarkMode;
    if (isEbay) {
      return AppColors.ebay;
    }
    if (isInApp) {
      return const Color(0xFFD97706);
    }
    switch (platform.toLowerCase()) {
      case 'chrono24':
        return isDark ? const Color(0xFF60A5FA) : AppColors.chrono24;
      case 'grailzee':
        return isDark ? Colors.white : AppColors.grailzee;
      default:
        return isDark ? AppColors.accent : AppColors.primary;
    }
  }

  String get platformAbbrev {
    if (isEbay) return 'eBay';
    if (isInApp) return 'App';
    switch (platform.toLowerCase()) {
      case 'chrono24':
        return 'C24';
      case 'grailzee':
        return 'GZ';
      default:
        return 'App';
    }
  }
}
