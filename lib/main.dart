import 'dart:io' show Platform;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';

// Importaciones de tus archivos locales
// Asegúrate de que estos archivos existan en tu proyecto
import 'package:safety_app/models/app_notification.dart';
import 'package:safety_app/screens/notificacion_detail_screen.dart';
import 'package:safety_app/screens/splash_screen.dart';
import 'package:safety_app/services/notification_service.dart';
import 'package:safety_app/services/airtable_service.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
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

// ✅ CAMBIO: Servicios ESENCIALES para el arranque
Future<void> _initializeCoreServices() async {
  final stopwatch = Stopwatch()..start();
  debugPrint("Core initialization started...");

  // 1. Carga DotEnv e inicializa Hive
  await Future.wait([
    dotenv.load(fileName: ".env"),
    Hive.initFlutter(),
  ]);

  // 2. Registra el adaptador de Hive
  // Asegúrate de haber generado el adaptador con build_runner
  if (!Hive.isAdapterRegistered(AppNotificationAdapter().typeId)) {
    Hive.registerAdapter(AppNotificationAdapter());
  }

  // 3. ✅ CAMBIO: Activamos App Check aquí.
  // Es vital que esto se ejecute ANTES de cualquier llamada a Firebase (Auth, Firestore, etc.)
  try {
    await FirebaseAppCheck.instance.activate(
      // Usar AndroidProvider.playIntegrity en producción
      androidProvider: AndroidProvider.debug,
      // Usar AppleProvider.appAttest en producción
      appleProvider: AppleProvider.debug,
    );
    debugPrint("  ✅ Firebase AppCheck activated.");
  } catch (e) {
    debugPrint("  ⚠️ Error activating AppCheck: $e");
  }

  debugPrint("✅ Core initialization finished: ${stopwatch.elapsedMilliseconds}ms total");
}

// ✅ FUNCIÓN DE SERVICIOS SECUNDARIOS
// Esta función puede ser llamada desde el SplashScreen para cargar el resto sin bloquear la UI inicial
Future<void> initializeSecondaryServices() async {
  try {
    final stopwatch = Stopwatch()..start();
    debugPrint("Secondary initialization started...");

    // ✅ CAMBIO: AppCheck ya se inicializó en el Core
    await Future.wait([
      MobileAds.instance.initialize(),
      NotificationService.initialize(), // Abre la caja de notificaciones
    ]);

    debugPrint("  ✅ Ads & Notifications done: ${stopwatch.elapsedMilliseconds}ms");

    // Configuración de RevenueCat
    String revenueCatApiKey = "";
    if (Platform.isAndroid) {
      revenueCatApiKey = dotenv.env['REVENUECAT_API_KEY_ANDROID'] ?? '';
    } else if (Platform.isIOS) {
      revenueCatApiKey = dotenv.env['REVENUECAT_API_KEY_IOS'] ?? '';
    }

    if (revenueCatApiKey.isNotEmpty) {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(revenueCatApiKey));
      debugPrint("  ✅ RevenueCat configured: ${stopwatch.elapsedMilliseconds}ms");
    }

    debugPrint("✅ Secondary initialization finished: ${stopwatch.elapsedMilliseconds}ms total");

  } catch (e) {
    debugPrint("Error during secondary initialization: $e");
  }
}

/// Punto de entrada principal de la aplicación.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mantenemos solo Firebase.initializeApp aquí como punto de partida crítico
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registramos el manejador de segundo plano para notificaciones
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Preparamos la inicialización Core para pasarla al Splash
  final coreServicesInitialization = _initializeCoreServices();

  runApp(
    MultiProvider(
      providers: [
        // Servicios globales disponibles en toda la app
        Provider(create: (_) => AirtableService()),
        Provider(create: (_) => BolsaTrabajoService()),
      ],
      // Pasamos la promesa de inicialización al widget raíz
      child: MyApp(initialization: coreServicesInitialization),
    ),
  );
}

/// Widget raíz de la aplicación.
class MyApp extends StatelessWidget {
  final Future<void> initialization;

  const MyApp({super.key, required this.initialization});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigatorKey,
      // El Splash Screen se encargará de esperar 'initialization' y luego llamar a 'initializeSecondaryServices'
      home: SplashScreen(initialization: initialization),
    );
  }
}