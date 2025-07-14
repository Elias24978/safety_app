import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:safety_app/models/app_notification.dart';
import 'package:safety_app/screens/notificacion_detail_screen.dart'; // Import correcto
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'SafetyApp',
      home: const SplashScreen(), // Asegúrate de tener este archivo
    );
  }
}