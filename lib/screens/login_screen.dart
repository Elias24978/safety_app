import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/screens/menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ Si el login es exitoso, navega al menú
      if (mounted) {
        Navigator.pop(context); // Cierra el diálogo de carga
        Navigator.pushReplacement( // Reemplaza la pantalla de login por la del menú
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorDialog(e.message ?? "Ocurrió un error desconocido.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error al Iniciar Sesión'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (El resto de la UI es idéntico al código que te di antes)
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text("¡Bienvenido de nuevo!", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Qué gusto verte. ¡De nuevo!", style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                const SizedBox(height: 40),
                TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Ingresa tu email')),
                const SizedBox(height: 20),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Ingresa tu contraseña')),
                const SizedBox(height: 10),
                const Align(alignment: Alignment.centerRight, child: Text("¿Olvidaste tu contraseña?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                const SizedBox(height: 40),
              ],
            ),
            MaterialButton(
              minWidth: double.infinity,
              height: 60,
              onPressed: _signIn,
              color: const Color(0xff2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              child: const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
            ),
            const SizedBox(height: 20),
            // ... (El texto para ir a registrarse)
          ],
        ),
      ),
    );
  }
}