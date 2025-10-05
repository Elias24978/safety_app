// lib/services/notification_service.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Novedad: Importamos Firestore
import 'package:firebase_core/firebase_core.dart'; // Novedad: Necesario para el background handler
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:safety_app/main.dart'; // Asegúrate que esta importación sea correcta
import 'package:safety_app/models/app_notification.dart';

// Novedad: Es REQUERIDO por Firebase que este handler sea una función de nivel superior (fuera de cualquier clase).
// Se encarga de procesar notificaciones cuando la app está cerrada (terminated).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializamos los servicios necesarios para que el handler funcione en segundo plano
  await Firebase.initializeApp();
  await Hive.openBox<AppNotification>('notifications');

  print("Handling a background message: ${message.messageId}");
  await NotificationService.saveAndShowNotification(message);
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String channelKey = 'basic_channel';

  static Future<void> initialize() async {
    // 1. Pedir permiso al usuario
    await _messaging.requestPermission();

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
    // Listener para cuando se interactúa con una notificación
    AwesomeNotifications().setListeners(onActionReceivedMethod: onActionReceivedMethod);

    // Listener para notificaciones en primer plano (app abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      saveAndShowNotification(message);
    });

    // Listener para cuando se abre la app desde una notificación (app en segundo plano)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['notification_id'] != null) {
        navigateToDetailScreen(Map<String, String?>.from(message.data));
      }
    });

    // Listener para cuando la app está cerrada y se abre desde la notificación
    handleInitialMessage();

    // Novedad: Asignamos nuestro handler de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Novedad: Función CLAVE para guardar el token del dispositivo en Firestore
  // Debes llamar a esta función justo después de que un usuario inicie sesión.
  static Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        print('No se pudo obtener el token FCM.');
        return;
      }

      final tokensCollection = FirebaseFirestore.instance.collection('fcm_tokens');

      // Usamos el ID del usuario como ID del documento para encontrarlo fácilmente
      await tokensCollection.doc(userId).set({
        'token': token,
        'lastUpdated': FieldValue.serverTimestamp(), // Guardamos la fecha para control
      });

      print('Token FCM para el usuario $userId guardado en Firestore.');
    } catch (e) {
      print('Error al guardar el token FCM: $e');
    }
  }

  // Novedad: Centralizamos la lógica de guardar en Hive y mostrar la notificación
  // para reutilizarla en primer y segundo plano.
  static Future<void> saveAndShowNotification(RemoteMessage message) async {
    final box = Hive.box<AppNotification>('notifications');
    // Usamos el messageId de FCM si está disponible, o creamos uno único.
    final String uniqueId = message.messageId ?? DateTime.now().toIso8601String();

    // Los datos pueden venir en la propiedad 'notification' o en 'data'
    final title = message.data['title'] ?? message.notification?.title ?? 'Sin Título';
    final body = message.data['body'] ?? message.notification?.body ?? 'Sin Contenido';

    // Guardamos en la base de datos local (Hive)
    await box.put(
      uniqueId,
      AppNotification(
        id: uniqueId,
        title: title,
        content: body,
        receivedDate: DateTime.now().toUtc(),
      ),
    );

    // Mostramos la notificación local al usuario usando AwesomeNotifications
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: uniqueId.hashCode, // AwesomeNotifications usa un entero para el ID
        channelKey: channelKey,
        title: title,
        body: body,
        payload: {'notification_id': uniqueId},
        notificationLayout: NotificationLayout.Default,
      ),
    );
    // Actualizamos el contador del ícono
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

  // Tu función para actualizar el badge (perfecta como está)
  static Future<void> updateGlobalBadge() async {
    final box = Hive.box<AppNotification>('notifications');
    final unreadCount = box.values.where((n) => !n.isRead).length;
    await AwesomeNotifications().setGlobalBadgeCounter(unreadCount);
  }

  // Tu función para marcar como leído (perfecta como está)
  static Future<void> markAsReadAndUpdateBadge(String notificationId) async {
    final box = Hive.box<AppNotification>('notifications');
    final notification = box.get(notificationId);
    if (notification != null && !notification.isRead) {
      notification.isRead = true;
      await notification.save();
    }
    await updateGlobalBadge();
  }
}