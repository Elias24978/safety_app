import 'package:flutter/material.dart';
import 'package:safety_app/screens/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  // Parámetro opcional para mantener compatibilidad con flujos de test o carga externa
  final Future<void>? initialization;

  const SplashScreen({super.key, this.initialization});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Si main.dart ya inicializó todo, solo esperamos un poco por la animación del logo
      if (widget.initialization != null) {
        await widget.initialization;
      } else {
        await Future.delayed(const Duration(seconds: 2));
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    } catch (e) {
      debugPrint("Error durante la carga: $e");
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          height: 150,
          errorBuilder: (c, o, s) => const Icon(Icons.security, size: 100, color: Colors.blue),
        ),
      ),
    );
  }
}