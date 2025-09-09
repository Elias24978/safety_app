import 'dart:io' show Platform;
import 'package:awesome_notifications/awesome_notifications.dart';
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
import 'package:firebase_app_check/firebase_app_check.dart';

// --- HANDLERS Y NAVEGACIÓN ---
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

// --- FUNCIÓN DE INICIALIZACIÓN OPTIMIZADA ---
Future<void> _initializeServices() async {
  await Future.wait([
    dotenv.load(fileName: ".env"),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Hive.initFlutter(),
  ]);

  Hive.registerAdapter(AppNotificationAdapter());

  // ✅ --- CORRECCIÓN DE SINTAXIS AQUÍ ---
  // Ambas operaciones deben estar dentro de la lista, separadas por una coma.
  // El `await` va al principio de `Future.wait`.
  await Future.wait([
    FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    ), // <- La coma va aquí
    Hive.openBox<AppNotification>('notifications'),
  ]);
  // ------------------------------------

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

  await NotificationService.initialize();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// --- FUNCIÓN PRINCIPAL ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(initialization: _initializeServices()));
}

// --- WIDGETS DE LA APP ---
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