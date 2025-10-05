import 'dart:io' show Platform;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safety_app/models/app_notification.dart';
import 'package:safety_app/screens/notificacion_detail_screen.dart';
import 'package:safety_app/screens/splash_screen.dart';
import 'package:safety_app/services/notification_service.dart';
import 'firebase_options.dart';

// Clave global para manejar la navegación desde fuera del árbol de widgets.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navega a la pantalla de detalles de la notificación.
void navigateToDetailScreen(Map<String, String?> payload) {
  final notificationId = payload['notification_id'];
  if (notificationId != null && navigatorKey.currentState != null) {
    navigatorKey.currentState!.push(MaterialPageRoute(
      builder: (_) => NotificationDetailScreen(notificationId: notificationId),
    ));
  }
}

/// Método que se ejecuta cuando se recibe una acción de notificación (ej. un toque).
@pragma("vm:entry-point")
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  if (receivedAction.payload?['notification_id'] != null) {
    navigateToDetailScreen(receivedAction.payload!);
  }
}

/// Manejador de mensajes de Firebase Cloud Messaging cuando la app está CERRADA.
@pragma("vm:entry-point")
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializamos los servicios básicos necesarios para que el handler funcione
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  // Nos aseguramos de que el adaptador y la caja de Hive estén listos
  if (!Hive.isAdapterRegistered(AppNotificationAdapter().typeId)) {
    Hive.registerAdapter(AppNotificationAdapter());
  }
  if (!Hive.isBoxOpen('notifications')) {
    await Hive.openBox<AppNotification>('notifications');
  }

  // ✅ CORRECCIÓN: Llamamos al método correcto del servicio.
  await NotificationService.saveAndShowNotification(message);
}

/// Inicializa todos los servicios necesarios para la aplicación de forma concurrente.
Future<void> _initializeServices() async {
  // Primer bloque de inicializaciones en paralelo.
  await Future.wait([
    dotenv.load(fileName: ".env"),
    // ✅ NOTA: Firebase se inicializa en main(), así que aquí ya está listo.
    Hive.initFlutter(),
  ]);

  Hive.registerAdapter(AppNotificationAdapter());

  await Future.wait([
    FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    ),
    Hive.openBox<AppNotification>('notifications'),
  ]);

  // Configuración de RevenueCat según la plataforma.
  String revenueCatApiKey = "";
  if (Platform.isAndroid) {
    revenueCatApiKey = dotenv.env['REVENUECAT_API_KEY_ANDROID'] ?? '';
  } else if (Platform.isIOS) {
    revenueCatApiKey = dotenv.env['REVENUECAT_API_KEY_IOS'] ?? '';
  }

  if (revenueCatApiKey.isNotEmpty) {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(revenueCatApiKey));
  }

  // Inicialización del servicio de notificaciones (listeners de primer plano, etc.).
  await NotificationService.initialize();
}

/// Punto de entrada principal de la aplicación.
Future<void> main() async { // ✅ MEJORA: main ahora es async
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ MEJORA: Inicializamos Firebase aquí, antes que nada.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ MEJORA: Registramos el manejador de segundo plano lo antes posible.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(MyApp(initialization: _initializeServices()));
}

/// Widget raíz de la aplicación.
class MyApp extends StatelessWidget {
  final Future<void> initialization;

  const MyApp({super.key, required this.initialization});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigatorKey,
      home: SplashScreen(initialization: initialization),
    );
  }
}