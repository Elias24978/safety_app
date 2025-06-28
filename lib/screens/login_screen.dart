import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Evita que el teclado redimensione todo
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Añadimos la flecha de "atrás" automáticamente
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            // Este comando cierra la pantalla actual y vuelve a la anterior
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribuye el espacio
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Textos de bienvenida basados en tu diseño
                const Text(
                  "¡Bienvenido de nuevo!",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Qué gusto verte. ¡De nuevo!",
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                const SizedBox(height: 40),

                // Campo para el correo
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Ingresa tu email',
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                ),
                const SizedBox(height: 20),

                // Campo para la contraseña
                const TextField(
                  obscureText: true, // Para ocultar la contraseña
                  decoration: InputDecoration(
                    labelText: 'Ingresa tu contraseña',
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    // Añadiremos el ícono del ojo más adelante
                  ),
                ),
                const SizedBox(height: 10),

                // Texto para "¿Olvidaste tu contraseña?"
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),

            // Botón de Login
            MaterialButton(
              minWidth: double.infinity,
              height: 60,
              onPressed: () {}, // La lógica de Firebase irá aquí
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
            const SizedBox(height: 20),

            // Textos finales de la pantalla
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("¿No tienes una cuenta?"),
                Text(
                  " Regístrate ahora",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30), // Espacio al final
          ],
        ),
      ),
    );
  }
}