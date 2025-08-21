import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/screens/menu_screen.dart';
import 'package:safety_app/screens/welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si todavía está esperando la conexión, muestra un círculo de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si tiene datos (un usuario), muestra el menú principal
        if (snapshot.hasData) {
          return const MenuScreen();
        }

        // Si no, muestra la pantalla de bienvenida para iniciar sesión/registrarse
        return const WelcomeScreen();
      },
    );
  }
}