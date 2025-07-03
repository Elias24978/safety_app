import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/firebase_options.dart';
import 'package:safety_app/screens/login_screen.dart';
import 'package:safety_app/services/notification_service.dart';
import 'package:safety_app/utils/logger.dart';

/// Manejador para notificaciones recibidas cuando la app está CERRADA o en SEGUNDO PLANO.
/// Esta función DEBE ser una función de alto nivel (fuera de cualquier clase).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Es necesario inicializar Firebase aquí también.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  logger.i("Notificación en segundo plano recibida: ${message.messageId}");

  // Guardamos la notificación para que el usuario la vea cuando abra la app.
  // Es importante notar que aquí no podemos actualizar el estado de la UI directamente.
  await NotificationService().saveNotification(message);
}

Future<void> main() async {
  // Asegura que los bindings de Flutter estén listos.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registra el manejador de mensajes en segundo plano.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inicializa nuestro servicio de notificaciones para el foreground.
  await NotificationService().initNotifications();

  // Revisa si la app fue abierta desde una notificación cuando estaba terminada.
  final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    logger.i("App abierta desde notificación terminada.");
    await NotificationService().saveNotification(initialMessage);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safety App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const LoginScreen(),
    );
  }
}