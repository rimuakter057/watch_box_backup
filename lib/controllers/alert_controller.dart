import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/prefs/pref_manager.dart';
import '../models/alert_model.dart';
import 'auth_controller.dart';
import '../core/network/services/alerts_api_service.dart';

class AlertController extends GetxController {
  final PrefManager _pref = Get.find<PrefManager>();
  final AuthController _auth = Get.find<AuthController>();
  AlertsApiService get _alertsApi => Get.find<AlertsApiService>();

  final RxList<AlertModel> alertsList = <AlertModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_auth.currentUser, (user) {
      if (user != null) {
        fetchAlerts();
      } else {
        alertsList.clear();
        unreadCount.value = 0;
      }
    });

    if (_auth.currentUser.value != null) {
      fetchAlerts();
    }
  }

  Future<void> fetchAlerts() async {
    if (!_pref.hasToken) {
      debugPrint("❌ [ALERTS ERROR] Cannot fetch notifications: User not authorized (no access token). No fallback.");
      alertsList.clear();
      unreadCount.value = 0;
      return;
    }

    isLoading.value = true;
    try {
      final backendNotifications = await _alertsApi.getNotifications();
      if (backendNotifications != null) {
        final list = backendNotifications.map((m) => AlertModel.fromMap(m)).toList();
        alertsList.assignAll(list);
        unreadCount.value = list.where((a) => !a.isRead).length;
        debugPrint("✅ [ALERT CONTROLLER] Loaded ${list.length} notifications from backend API.");
      } else {
        debugPrint("❌ [ALERTS ERROR] Notifications API returned null / not authorized. No fallback.");
      }
    } catch (e) {
      debugPrint("❌ [ALERTS ERROR] Notifications API error: $e. No fallback.");
    } finally {
      isLoading.value = false;
    }
  }

  void onNewAlertReceived(AlertModel alert) {
    alertsList.insert(0, alert);
    if (!alert.isRead) {
      unreadCount.value++;
    }
    debugPrint("🔔 [ALERT CONTROLLER] Prepending new alert via real-time: ${alert.message}");
  }

  Future<void> markAsRead(int alertId) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [ALERTS ERROR] Cannot mark alert as read: User not authorized (no access token). No fallback.");
      return;
    }

    try {
      final ok = await _alertsApi.markAsRead(alertId.toString());
      if (!ok) {
        debugPrint("❌ [ALERTS ERROR] Backend rejected markAsRead for alert $alertId. No fallback.");
        return;
      }

      final idx = alertsList.indexWhere((a) => a.id == alertId);
      if (idx != -1) {
        alertsList[idx] = alertsList[idx].copyWith(isRead: true);
      }
      unreadCount.value = alertsList.where((a) => !a.isRead).length;
      debugPrint("✅ [ALERT CONTROLLER] Alert $alertId marked as read.");
    } catch (e) {
      debugPrint("❌ [ALERTS ERROR] Error marking alert as read: $e. No fallback.");
    }
  }

  Future<void> markAllAsRead() async {
    if (!_pref.hasToken) {
      debugPrint("❌ [ALERTS ERROR] Cannot mark all alerts as read: User not authorized (no access token). No fallback.");
      return;
    }

    try {
      final ok = await _alertsApi.markAllAsRead();
      if (!ok) {
        debugPrint("❌ [ALERTS ERROR] Backend rejected markAllAsRead. No fallback.");
        return;
      }

      for (int i = 0; i < alertsList.length; i++) {
        if (!alertsList[i].isRead) {
          alertsList[i] = alertsList[i].copyWith(isRead: true);
        }
      }
      unreadCount.value = 0;
      debugPrint("✅ [ALERT CONTROLLER] All alerts marked as read.");
    } catch (e) {
      debugPrint("❌ [ALERTS ERROR] Error marking all alerts as read: $e. No fallback.");
    }
  }

  Future<void> deleteAlert(int alertId) async {
    if (!_pref.hasToken) {
      debugPrint("❌ [ALERTS ERROR] Cannot delete alert: User not authorized (no access token). No fallback.");
      return;
    }

    try {
      final ok = await _alertsApi.deleteNotification(alertId.toString());
      if (!ok) {
        debugPrint("❌ [ALERTS ERROR] Backend rejected delete alert $alertId. No fallback.");
        return;
      }

      alertsList.removeWhere((a) => a.id == alertId);
      unreadCount.value = alertsList.where((a) => !a.isRead).length;
      debugPrint("✅ [ALERT CONTROLLER] Alert $alertId deleted.");
    } catch (e) {
      debugPrint("❌ [ALERTS ERROR] Error deleting alert: $e. No fallback.");
    }
  }
}
