// lib/services/notification_service.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Asegúrate de importar hive_flutter
import 'package:safety_app/main.dart';
import 'package:safety_app/models/app_notification.dart';

// El handler de segundo plano (cuando la app está CERRADA)
// (Está correcto, no se necesita ningún cambio aquí)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Se asegura de que Hive esté listo para el handler
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(AppNotificationAdapter().typeId)) {
    Hive.registerAdapter(AppNotificationAdapter());
  }
  if (!Hive.isBoxOpen('notifications')) {
    await Hive.openBox<AppNotification>('notifications');
  }

  debugPrint("Handling a background message: ${message.messageId}");
  await NotificationService.saveAndShowNotification(message);
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String channelKey = 'basic_channel';

  static Future<void> initialize() async {
    final stopwatch = Stopwatch()..start();
    debugPrint("  NotificationService initialization started...");

    // ✅ CAMBIO CLAVE: Abrimos la caja de notificaciones aquí.
    // Esto se ejecuta en segundo plano (desde initializeSecondaryServices)
    // y prepara la caja para recibir notificaciones en primer plano (onMessage).
    try {
      if (!Hive.isBoxOpen('notifications')) {
        await Hive.openBox<AppNotification>('notifications');
        debugPrint("  ✅ Hive box 'notifications' opened by NotificationService: ${stopwatch.elapsedMilliseconds}ms");
      } else {
        debugPrint("  ℹ️ Hive box 'notifications' was already open.");
      }
    } catch (e) {
      debugPrint("  ⚠️ Error opening notifications box in NotificationService: $e");
    }

    // 1. Pedir permiso al usuario
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Inicializar Awesome Notifications
    await AwesomeNotifications().initialize(
      null, // sin icono por ahora
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Notificaciones Básicas',
          channelDescription: 'Canal para notificaciones generales.',
          importance: NotificationImportance.High,
          channelShowBadge: true,
        )
      ],
      debug: kDebugMode,
    );

    // 3. Configurar listeners
    AwesomeNotifications().setListeners(onActionReceivedMethod: onActionReceivedMethod);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      saveAndShowNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['notification_id'] != null) {
        navigateToDetailScreen(Map<String, String?>.from(message.data));
      }
    });

    handleInitialMessage();

    // Asignamos nuestro handler de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    debugPrint("  ✅ NotificationService fully initialized: ${stopwatch.elapsedMilliseconds}ms");
  }

  // (El resto de tu archivo: saveTokenToFirestore, saveAndShowNotification, etc.
  // no necesita cambios, ya estaba correcto.)

  static Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('No se pudo obtener el token FCM.');
        return;
      }

      final tokensCollection = FirebaseFirestore.instance.collection('fcm_tokens');

      await tokensCollection.doc(userId).set({
        'token': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      debugPrint('Token FCM para el usuario $userId guardado en Firestore.');
    } catch (e) {
      debugPrint('Error al guardar el token FCM: $e');
    }
  }

  static Future<void> saveAndShowNotification(RemoteMessage message) async {
    // Asegurarnos de que la caja esté abierta (doble chequeo por seguridad)
    if (!Hive.isBoxOpen('notifications')) {
      debugPrint("Save attempt failed: 'notifications' box is closed.");
      // Intentamos abrirla de nuevo si falló
      try {
        await Hive.openBox<AppNotification>('notifications');
        debugPrint("Re-opened 'notifications' box.");
      } catch (e) {
        debugPrint("Failed to re-open 'notifications' box: $e");
        return; // No podemos continuar si la caja no abre
      }
    }

    final box = Hive.box<AppNotification>('notifications');
    final String uniqueId = message.messageId ?? DateTime.now().toIso8601String();

    final title = message.data['title'] ?? message.notification?.title ?? 'Sin Título';
    final body = message.data['body'] ?? message.notification?.body ?? 'Sin Contenido';

    // Guardamos en la base de datos local (Hive)
    await box.put(
      uniqueId,
      AppNotification(
        id: uniqueId,
        title: title,
        content: body, // Asumiendo que 'body' es el contenido principal
        receivedDate: DateTime.now().toUtc(),
      ),
    );

    // Mostramos la notificación local al usuario
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: uniqueId.hashCode,
        channelKey: channelKey,
        title: title,
        body: body,
        payload: {'notification_id': uniqueId},
        notificationLayout: NotificationLayout.Default,
      ),
    );
    await updateGlobalBadge();
  }

  static Future<void> handleInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data['notification_id'] != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        navigateToDetailScreen(Map<String, String?>.from(initialMessage.data));
      });
    }
  }

  static Future<void> updateGlobalBadge() async {
    if (!Hive.isBoxOpen('notifications')) {
      await Hive.openBox<AppNotification>('notifications');
    }
    final box = Hive.box<AppNotification>('notifications');
    final unreadCount = box.values.where((n) => !n.isRead).length;
    await AwesomeNotifications().setGlobalBadgeCounter(unreadCount);
  }

  static Future<void> markAsReadAndUpdateBadge(String notificationId) async {
    if (!Hive.isBoxOpen('notifications')) {
      await Hive.openBox<AppNotification>('notifications');
    }
    final box = Hive.box<AppNotification>('notifications');
    final notification = box.get(notificationId);
    if (notification != null && !notification.isRead) {
      notification.isRead = true;
      await notification.save();
    }
    await updateGlobalBadge();
  }
}