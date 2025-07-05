import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // ✅ 1. IMPORTAR PARA kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import 'package:safety_app/firebase_options.dart';
import 'package:safety_app/models/notification_model.dart';
import 'package:safety_app/screens/splash_screen.dart';

// --- Imports para Navegación ---
import 'package:safety_app/services/navigation_service.dart';
// ❌ 2. ELIMINAR IMPORT SIN USAR: import 'package:safety_app/screens/notificaciones_list_screen.dart';
import 'package:safety_app/screens/notificacion_detail_screen.dart'; // ✅ 3. AÑADIR IMPORT FALTANTE

void _setupLogging() {
  // Esta configuración es correcta, solo muestra logs en modo debug.
  if (kDebugMode) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // El print dentro de kDebugMode es una práctica aceptable.
      if (kDebugMode) {
        print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
      }
    });
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(NotificationModelAdapter());
  await Hive.openBox<NotificationModel>('notifications');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      title: 'SafetyMex',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      routes: {
        '/notification_detail': (context) {
          final String notificationId = ModalRoute.of(context)!.settings.arguments as String;
          // Ahora 'NotificationDetailScreen' ya no dará error.
          return NotificationDetailScreen(notificationId: notificationId);
        }
      },
    );
  }
}