import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:safety_app/screens/splash_screen.dart'; // Asegúrate de que este import esté aquí

Future<void> main() async {
  // Esta parte ya la teníamos, se asegura de cargar el .env
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Le decimos que la primera pantalla es la del logo
      home: const SplashScreen(),
    );
  }
}