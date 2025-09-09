import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:safety_app/main.dart';
import 'package:safety_app/models/app_notification.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String channelKey = 'basic_channel';

  static Future<void> initialize() async {
    await _messaging.requestPermission();
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelKey: channelKey,
            channelName: 'Notificaciones Básicas',
            channelDescription: 'Canal para notificaciones generales.',
            importance: NotificationImportance.High,
            channelShowBadge: true)
      ],
      debug: kDebugMode,
    );
    AwesomeNotifications().setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  // ✅ NUEVA FUNCIÓN: Para actualizar el contador global de notificaciones
  static Future<void> updateGlobalBadge() async {
    final box = Hive.box<AppNotification>('notifications');
    final unreadCount = box.values.where((n) => !n.isRead).length;
    await AwesomeNotifications().setGlobalBadgeCounter(unreadCount);
  }

  static void setupListeners() {
    handleInitialMessage();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleMessage(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['notification_id'] != null) {
        navigateToDetailScreen(Map<String, String?>.from(message.data));
      }
    });
  }

  static Future<void> handleInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data['notification_id'] != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        navigateToDetailScreen(Map<String, String?>.from(initialMessage.data));
      });
    }
  }

  static Future<void> handleMessage(RemoteMessage message) async {
    final box = Hive.box<AppNotification>('notifications');
    final String uniqueId = message.data['notification_id'] ?? DateTime.now().toIso8601String();

    await box.put(
      uniqueId,
      AppNotification(
        id: uniqueId,
        title: message.data['title'] ?? message.notification?.title ?? 'Sin Título',
        content: message.data['body'] ?? message.notification?.body ?? 'Sin Contenido',
        receivedDate: DateTime.now().toUtc(),
      ),
    );

    final unreadCount = box.values.where((n) => !n.isRead).length;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: uniqueId.hashCode,
        channelKey: channelKey,
        title: message.data['title'] ?? message.notification?.title,
        body: message.data['body'] ?? message.notification?.body,
        payload: {'notification_id': uniqueId}, // ✅ Parámetro 'payload' definido
        notificationLayout: NotificationLayout.Default,
        badge: unreadCount,
      ),
    );
  }

  static Future<void> markAsReadAndUpdateBadge(String notificationId) async {
    final box = Hive.box<AppNotification>('notifications');
    final notification = box.get(notificationId);
    if (notification != null && !notification.isRead) {
      notification.isRead = true;
      await notification.save();
    }
    final unreadCount = box.values.where((n) => !n.isRead).length;
    await AwesomeNotifications().setGlobalBadgeCounter(unreadCount);
  }
}