import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:safety_app/models/app_notification.dart';
import 'package:safety_app/screens/notificacion_detail_screen.dart';
import 'package:safety_app/screens/splash_screen.dart';
import 'package:safety_app/services/notification_service.dart';
import 'package:safety_app/services/airtable_service.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/services/purchase_service.dart';
import 'firebase_options.dart';

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
  if (!Hive.isBoxOpen('notifications')) {
    await Hive.openBox<AppNotification>('notifications');
  }

  await NotificationService.saveAndShowNotification(message);
}

Future<void> _initializeSecondaryServices() async {
  try {
    debugPrint("🚀 Iniciando servicios secundarios...");
    await Future.wait([
      MobileAds.instance.initialize(),
      NotificationService.initialize(),
    ]);
    debugPrint("✅ Servicios secundarios listos");
  } catch (e) {
    debugPrint("⚠️ Error en servicios secundarios: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carga crítica inicial
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();

  // 2. Inicializar el Singleton de compras antes de la UI
  await PurchaseService().init();

  if (!Hive.isAdapterRegistered(AppNotificationAdapter().typeId)) {
    Hive.registerAdapter(AppNotificationAdapter());
  }

  // 4. Corrección de App Check para compilación
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug, // ✅ CORREGIDO: Usando AppleProvider
    );
  } catch (e) {
    debugPrint("⚠️ AppCheck warning: $e");
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  _initializeSecondaryServices();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AirtableService()),
        Provider(create: (_) => BolsaTrabajoService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // ✅ Eliminado el parámetro initialization

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      home: const SplashScreen(initialization: null), // Se pasa null intencionalmente
    );
  }
}