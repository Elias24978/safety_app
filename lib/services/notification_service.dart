import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// --- MANEJADOR DE MENSAJES EN SEGUNDO PLANO ---
// Esta función DEBE estar fuera de una clase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.i("Handling a background message: ${message.messageId}");
  // Aquí podrías, por ejemplo, guardar el dato en SharedPreferences, etc.
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Inicializa todo el sistema de notificaciones.
  Future<void> initNotifications() async {
    // 1. Solicitar permisos al usuario.
    await _requestPermissions();

    // 2. Obtener el token FCM del dispositivo.
    final fcmToken = await getFCMToken();
    logger.i('Token FCM del dispositivo: $fcmToken');
    // En una app real, enviarías este token a tu backend para guardar
    // y poder enviar notificaciones a este usuario específico.

    // 3. Inicializar notificaciones locales y configurar manejadores.
    await _initLocalNotifications();
    _initPushNotificationListeners();
  }

  /// Solicita permisos de notificación al usuario (iOS y Android 13+).
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    logger.i('Permisos de usuario concedidos: ${settings.authorizationStatus}');
  }

  /// Obtiene el token FCM único para este dispositivo.
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Inicializa el plugin de notificaciones locales.
  Future<void> _initLocalNotifications() async {
    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/ic_notification'); // Usa el mismo ícono

    // Configuración para iOS (puedes dejarla básica por ahora)
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);
  }

  /// Muestra una notificación local.
  void showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Define los detalles de la notificación para Android.
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // Mismo ID de canal que en AndroidManifest.xml
      'High Importance Notifications',
      channelDescription: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    // Define los detalles para iOS.
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails notificationDetails = NotificationDetails(
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

  /// Configura los "listeners" para los diferentes estados de la app.
  void _initPushNotificationListeners() {
    // --- APP EN PRIMER PLANO (FOREGROUND) ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('¡Mensaje recibido en primer plano!');
      logger.d('Data: ${message.data}');

      if (message.notification != null) {
        logger.d('La notificación contiene: ${message.notification}');
        // Muestra la notificación visualmente usando el plugin de notificaciones locales.
        showLocalNotification(message);
      }
    });

    // --- APP EN SEGUNDO PLANO (BACKGROUND) Y SE ABRE AL TOCAR LA NOTIFICACIÓN ---
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i('El usuario ha abierto la app desde una notificación.');
      // Aquí puedes navegar a una pantalla específica basada en los datos del mensaje.
      // Ejemplo: if (message.data['screen'] == 'offers') { ... }
    });
  }
}