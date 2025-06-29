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
  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Variables para visibilidad de contraseñas
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  // Función para registrar
  Future<void> signUp() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Validación 1: Campos vacíos
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Por favor, rellena todos los campos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validación 2: Contraseñas no coinciden
    if (_passwordController.text != _confirmPasswordController.text) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Intento de creación de usuario en Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );

    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos de Firebase en español
      String errorMessage = "Error: Revisa tus datos e inténtalo de nuevo.";

      if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es muy débil (mín. 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Este correo electrónico ya está registrado.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El formato del correo electrónico no es válido.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'No hay conexión a internet. Por favor, revisa tu red.';
      }

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios,
              size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          width: double.infinity,
          child: Column(
            children: <Widget>[
              const Column(
                children: <Widget>[
                  Text(
                    "Regístrate",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Crea una cuenta, es gratis",
                      style: TextStyle(fontSize: 15, color: Colors.grey))
                ],
              ),
              const SizedBox(height: 40),
              Column(
                children: <Widget>[
                  TextField(
                    decoration: const InputDecoration(labelText: 'Usuario (opcional)'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    decoration: InputDecoration(
                      labelText: 'Contraseña (mín. 6 caracteres)',
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmPasswordObscured,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              MaterialButton(
                minWidth: double.infinity,
                height: 60,
                onPressed: signUp,
                color: const Color(0xff2A2A2A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                child: const Text(
                  "Registrarse",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("¿Ya tienes una cuenta?"),
                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> const LoginScreen()));
                    },
                    child: const Text(" Inicia sesión", style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.blue,
                    )),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}