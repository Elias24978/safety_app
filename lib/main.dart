// lib/main.dart

import 'dart:io' show Platform; // Import para detectar la plataforma
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- 1. IMPORTA DOTENV
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safety_app/models/app_notification.dart';
import 'package:safety_app/screens/notificacion_detail_screen.dart';
import 'package:safety_app/screens/splash_screen.dart';
import 'package:safety_app/services/notification_service.dart';
import 'firebase_options.dart';

// --- HANDLERS Y NAVEGACIÓN (NIVEL SUPERIOR) ---
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void navigateToDetailScreen(Map<String, String?> payload) {
  final notificationId = payload['notification_id'];
  if (notificationId != null && navigatorKey.currentState != null) {
    navigatorKey.currentState!.push(MaterialPageRoute(
      builder: (_) => NotificationDetailScreen(notificationId: notificationId),
    ));
  }
}

@pragma("vm:entry-point")
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  if (receivedAction.payload?['notification_id'] != null) {
    navigateToDetailScreen(receivedAction.payload!);
  }
}

@pragma("vm:entry-point")
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(AppNotificationAdapter().typeId)) {
    Hive.registerAdapter(AppNotificationAdapter());
  }
  await NotificationService.handleMessage(message);
}

// --- FUNCIÓN PRINCIPAL ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 2. INICIALIZA DOTENV AL PRINCIPIO DE TODO ---
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- 3. CAMBIO: CARGAR CLAVES DE REVENUECAT DESDE .ENV ---
  String revenueCatApiKey = "";
  if (Platform.isAndroid) {
    revenueCatApiKey = dotenv.env['REVENUECAT_API_KEY_ANDROID']!;
  } else if (Platform.isIOS) {
    revenueCatApiKey = dotenv.env['REVENUECAT_API_KEY_IOS']!;
  }

  if (revenueCatApiKey.isNotEmpty) {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(revenueCatApiKey));
  }
  // ------------------------------------

  await Hive.initFlutter();
  Hive.registerAdapter(AppNotificationAdapter());
  await Hive.openBox<AppNotification>('notifications');

  await NotificationService.initialize();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// --- WIDGETS DE LA APP ---
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.setupListeners();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Cambiado a un color más consistente con la app
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}