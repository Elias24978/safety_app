// IMPORTACIONES AÑADIDAS PARA CORREGIR ERRORES
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safety_app/utils/logger.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.i("Handling a background message: ${message.messageId}");
}

// CÓDIGO COMPLETO DE LA CLASE CON LOS MÉTODOS IMPLEMENTADOS
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initNotifications() async {
    await _requestPermissions();
    final fcmToken = await getFCMToken(); // 'getFCMToken' en lugar de '_getFCMToken'
    logger.i('Token FCM del dispositivo: $fcmToken');
    await _initLocalNotifications();
    _initPushNotificationListeners();
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    logger.i('Permisos de usuario concedidos: ${settings.authorizationStatus}');
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(initializationSettings);
  }

  void showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
    );
  }

  void _initPushNotificationListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('¡Mensaje recibido en primer plano!');
      if (message.notification != null) {
        showLocalNotification(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i('El usuario ha abierto la app desde una notificación.');
    });
  }

  Future<void> saveTokenToDatabase() async {
    final String? fcmToken = await getFCMToken();
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (fcmToken != null && userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': fcmToken,
          'lastUpdated': Timestamp.now(),
        });
        logger.i('Token FCM guardado en Firestore para el usuario: $userId');
      } catch (e) {
        logger.e('Error al guardar el token en Firestore', error: e);
      }
    }
  }
}