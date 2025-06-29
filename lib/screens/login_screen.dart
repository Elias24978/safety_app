import 'package:flutter/material.dart';
import 'package:safety_app/screens/register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Evita que el teclado redimensione todo
      backgroundColor: Colors.white,
      appBar: AppBar(
        // La flecha de "atrás" para volver a la WelcomeScreen
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
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            // Alinea el contenido verticalmente
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // Columna para los textos de bienvenida
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "¡Bienvenido de nuevo!",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Qué gusto verte. ¡De nuevo!",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              // Columna para los campos de texto y el botón
              Column(
                children: <Widget>[
                  const TextField(
                    decoration: InputDecoration(labelText: "Ingresa tu email"),
                  ),
                  const SizedBox(height: 20),
                  const TextField(
                    obscureText: true, // Para ocultar la contraseña
                    decoration: InputDecoration(labelText: "Ingresa tu contraseña"),
                  ),
                  const SizedBox(height: 10),
                  // Texto de "¿Olvidaste tu contraseña?"
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              // Botón de Login
              MaterialButton(
                minWidth: double.infinity,
                height: 60,
                onPressed: () {
                  // La lógica de Firebase irá aquí más adelante
                },
                color: const Color(0xff2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),

              // Texto para ir a la pantalla de Registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("¿No tienes una cuenta?"),
                  GestureDetector(
                    onTap: () {
                      // Navegamos a la pantalla de Registro
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      " Regístrate ahora",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}