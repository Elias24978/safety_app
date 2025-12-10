import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/screens/menu_screen.dart';
// Importamos la pantalla de verificación que creamos/vamos a crear
import 'package:safety_app/screens/verify_email_screen.dart';
import 'package:safety_app/screens/welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Si todavía está esperando la conexión, muestra un círculo de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Si tiene datos (un usuario ha iniciado sesión)
        if (snapshot.hasData) {
          final user = snapshot.data!;

          // --- FILTRO DE SEGURIDAD ---
          // Verificamos si el correo tiene la "palomita" de validado en Firebase
          if (user.emailVerified) {
            // Si está verificado, pasa al menú principal
            return const MenuScreen();
          } else {
            // Si NO está verificado, lo enviamos a la sala de espera
            return const VerifyEmailScreen();
          }
        }

        // 3. Si no hay usuario, muestra la pantalla de bienvenida
        return const WelcomeScreen();
      },
    );
  }
}