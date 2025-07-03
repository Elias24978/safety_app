import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:safety_app/models/notification_model.dart';
import 'package:safety_app/utils/logger.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicializa todo el sistema de notificaciones.
  Future<void> initNotifications() async {
    await _requestPermissions();
    await _initLocalNotifications();
    _initPushNotificationListeners();
  }

  /// Solicita permisos de notificación al usuario.
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    logger.i('Permisos de usuario: ${settings.authorizationStatus}');
  }

  /// Obtiene el token FCM único para este dispositivo.
  Future<String?> getToken() async {
    final token = await _firebaseMessaging.getToken();
    logger.i('Token FCM del dispositivo: $token');
    return token;
  }

  /// Guarda o actualiza el token en la base de datos del usuario.
  Future<void> saveTokenToDatabase() async {
    final token = await getToken();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (token != null && userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastUpdated': Timestamp.now(),
        });
        logger.i('Token FCM guardado en Firestore para el usuario: $userId');
      } catch (e) {
        logger.e('Error al guardar token en Firestore', error: e);
      }
    }
  }

  /// Inicializa el plugin de notificaciones locales para mostrar alertas en primer plano.
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings);
  }

  /// Muestra una notificación local.
  void showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Canal para notificaciones importantes.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinInitializationSettings();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data['notification_id'],
    );
  }

  /// Guarda una notificación en Firestore.
  Future<void> saveNotification(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || message.notification == null) return;

    final newNotification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification!.title ?? 'Sin Título',
      body: message.notification!.body ?? 'Sin Contenido',
      receivedDate: DateTime.now(),
      type: message.data['type'] ?? 'info',
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .add(newNotification.toMap());

    logger.i('Notificación guardada en Firestore.');
  }

  /// Configura los listeners para los diferentes estados de la app.
  void _initPushNotificationListeners() {
    // App en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('¡Mensaje recibido en primer plano!');
      if (message.notification != null) {
        showLocalNotification(message);
        saveNotification(message);
      }
    });

    // App en segundo plano, se abre al tocar la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i('App abierta desde notificación en segundo plano.');
      saveNotification(message);
    });
  }
}