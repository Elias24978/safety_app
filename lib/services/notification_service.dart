import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:safety_app/models/notification_model.dart';
import 'package:logging/logging.dart'; // 1. IMPORTA EL PAQUETE

// 2. CREA UNA INSTANCIA DEL LOGGER
final _log = Logger('NotificationService');

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Box<NotificationModel> _notificationBox = Hive.box<NotificationModel>('notifications');

  Future<void> initNotifications() async {
    await _fcm.requestPermission();
    final fcmToken = await _fcm.getToken();
    _log.info('FCM Token: $fcmToken'); // 👈 PRINT REEMPLAZADO

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );
    _setupListeners();
  }

  void onSelectNotification(NotificationResponse response) {
    if (response.payload != null) {
      _log.info('Notificación local tocada, payload: ${response.payload}'); // 👈 PRINT REEMPLAZADO
      _handleNotificationTap({'notification_id': response.payload});
    }
  }

  void _setupListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log.info('Notificación recibida en primer plano: ${message.notification?.title}'); // 👈 PRINT REEMPLAZADO
      if (message.notification != null) {
        _showLocalNotification(message);
        _saveAndBadge(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log.info('App abierta desde notificación en segundo plano'); // 👈 PRINT REEMPLAZADO
      _handleNotificationTap(message.data);
    });

    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _log.info('App abierta desde notificación con la app terminada'); // 👈 PRINT REEMPLAZADO
        _handleNotificationTap(message.data);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notificaciones Importantes',
          channelDescription: 'Este canal es para notificaciones importantes.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['notification_id'],
    );
  }

  Future<void> _saveAndBadge(RemoteMessage message) async {
    final notificationData = message.notification;
    final uniqueId = message.data['notification_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final newNotification = NotificationModel(
      id: uniqueId,
      title: notificationData?.title ?? 'Sin Título',
      content: notificationData?.body ?? 'Sin Contenido',
      receivedDate: DateTime.now(),
      isRead: false,
    );
    await _notificationBox.put(uniqueId, newNotification);
    await updateBadgeCount();
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final notificationId = data['notification_id'];
    if (notificationId != null) {
      _log.info("Navegando a la pantalla de detalle para la notificación ID: $notificationId"); // 👈 PRINT REEMPLAZADO
    }
  }

  Future<void> updateBadgeCount() async {
    final unreadCount = _notificationBox.values.where((n) => !n.isRead).length;
    if (unreadCount > 0) {
      FlutterAppBadger.updateBadgeCount(unreadCount);
    } else {
      FlutterAppBadger.removeBadge();
    }
  }
}