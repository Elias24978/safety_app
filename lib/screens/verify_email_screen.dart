import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/screens/menu_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    // 1. Verificar estado inicial
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      // 2. Si no está verificado, enviar el correo inmediatamente
      sendVerificationEmail();

      // 3. Iniciar un timer para revisar cada 3 segundos si ya hizo clic en el enlace
      timer = Timer.periodic(
        const Duration(seconds: 3),
            (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // Recargar los datos del usuario para ver si cambió el estado en Firebase
    await FirebaseAuth.instance.currentUser?.reload();

    // --- CORRECCIÓN PARA EL ERROR DEL LOG ---
    if (!mounted) return; // Si la pantalla ya no está visible, detenemos aquí.

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    // Si ya se verificó, cancelar el timer y navegar al menú
    if (isEmailVerified) {
      timer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // --- IDIOMA ESPAÑOL ---
      // Esta línea fuerza a Firebase a usar la plantilla en español
      await FirebaseAuth.instance.setLanguageCode("es");

      await user.sendEmailVerification();

      // --- CORRECCIÓN DE SEGURIDAD ---
      // Verificamos 'mounted' antes de usar setState para evitar errores si el usuario sale
      if (mounted) {
        setState(() => canResendEmail = false);
      }

      // Esperar 5 segundos antes de permitir reenviar para evitar spam
      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        setState(() => canResendEmail = true);
      }
    } catch (e) {
      debugPrint("Error enviando correo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si ya está verificado, mostramos el Menú (por seguridad si el timer falla)
    if (isEmailVerified) {
      return const MenuScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Verifica tu correo"),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Quitar flecha de volver
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 100, color: Color(0xff2A2A2A)),
            const SizedBox(height: 30),
            const Text(
              '¡Casi listo!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Hemos enviado un correo de verificación a:\n${FirebaseAuth.instance.currentUser?.email}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Por favor revisa tu bandeja y da clic en el enlace para continuar. Esta pantalla se actualizará automáticamente.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Botón Reenviar
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2A2A2A),
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.email, color: Colors.white),
              label: const Text(
                'Reenviar Correo',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: canResendEmail ? sendVerificationEmail : null,
            ),

            const SizedBox(height: 20),

            // Botón Cancelar (Cerrar Sesión) por si se equivocó de correo
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () async {
                timer?.cancel();
                await FirebaseAuth.instance.signOut();
                // El AuthGate se encargará de mostrar el Login automáticamente
              },
              child: const Text(
                'Cancelar / Cambiar correo',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}