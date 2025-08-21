import 'package:flutter/material.dart';
import 'package:safety_app/screens/login_screen.dart'; // Para navegar al Login
import 'package:safety_app/screens/register_screen.dart'; // Para navegar al Registro (la crearemos después)

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea( // SafeArea evita que el contenido se ponga detrás de la barra de notificaciones
        child: Container(
          width: double.infinity, // Ocupa todo el ancho disponible
          height: double.infinity, // Ocupa todo el alto disponible
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            // Alinea los elementos verticalmente
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Título principal
              const Text(
                "Bienvenido",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),

              // Contenedor para la imagen (usamos un placeholder por ahora)
              Container(
                height: MediaQuery.of(context).size.height / 3,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    // Más adelante cambiaremos esto por tu imagen de la planta
                    image: AssetImage("assets/images/logo.png"),
                  ),
                ),
              ),

              // Columna para los botones
              Column(
                children: <Widget>[
                  // Botón de Login
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      // Navegar a la pantalla de Login
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    color: const Color(0xff2A2A2A), // Color negro del diseño
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
                  const SizedBox(height: 20), // Espacio entre botones

                  // Botón de Registro
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      // Navegar a la pantalla de Registro
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    color: Colors.grey[200], // Color gris claro
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
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