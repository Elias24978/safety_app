import 'package:flutter/material.dart';
import 'package:safety_app/screens/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  // Recibimos el Future de la inicialización desde main.dart
  final Future<void> initialization;

  const SplashScreen({super.key, required this.initialization});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Esta función ahora espera a que los servicios estén listos
  Future<void> _initializeApp() async {
    try {
      // Espera a que el Future que le pasamos se complete
      await widget.initialization;

      // Una vez completado, navega de forma segura
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    } catch (e) {
      // Aquí puedes manejar cualquier error que ocurra durante la inicialización
      debugPrint("Error durante la inicialización: $e");
      if (mounted) {
        // Opcional: mostrar una pantalla de error si algo falla
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al iniciar la aplicación.'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // La UI no cambia, sigue mostrando el logo
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/images/logo.png', height: 150),
      ),
    );
  }
}