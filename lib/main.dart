import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Importa messaging
import 'package:safety_app/firebase_options.dart';
import 'package:safety_app/screens/login_screen.dart';
import 'package:safety_app/services/notification_service.dart'; // Importa nuestro servicio

// --- MANEJADOR DE MENSAJES EN BACKGROUND/TERMINATED ---
// Debe registrarse aquí, fuera del runApp.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  logger.i("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  // Asegura que todos los bindings de Flutter estén listos antes de llamar a código nativo.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Registra el manejador de mensajes en segundo plano.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializa nuestro servicio de notificaciones.
  await NotificationService().initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const LoginScreen(),
    );
  }
}