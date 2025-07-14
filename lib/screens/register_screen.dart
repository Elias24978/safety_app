import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/screens/login_screen.dart';
import 'package:safety_app/screens/menu_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para cada campo de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Lógica para registrar al usuario
  Future<void> _signUp() async {
    // 1. Validar que las contraseñas coincidan
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      _showErrorDialog("Las contraseñas no coinciden.");
      return;
    }

    // Muestra un círculo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 2. Intentar crear el usuario en Firebase
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Si es exitoso, navega a la pantalla del menú
      if (mounted) {
        Navigator.pop(context); // Cierra el diálogo de carga
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Cierra el diálogo de carga

      // Muestra el error específico de Firebase
      _showErrorDialog(e.message ?? "Ocurrió un error desconocido.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error de Registro'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          height: MediaQuery.of(context).size.height - 80,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Column(
                children: <Widget>[
                  Text("¡Regístrate!", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Crea una cuenta, es gratis", style: TextStyle(fontSize: 15, color: Colors.grey)),
                ],
              ),
              Column(
                children: <Widget>[
                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 20),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
                  const SizedBox(height: 20),
                  TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar Contraseña')),
                ],
              ),
              MaterialButton(
                minWidth: double.infinity,
                height: 60,
                onPressed: _signUp, // Llama a la función de registro
                color: const Color(0xff2A2A2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                child: const Text("Registrarse", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("¿Ya tienes una cuenta?"),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                    child: const Text(" Inicia sesión", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}