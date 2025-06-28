import 'package:flutter/material.dart';
import 'package:safety_app/screens/login_screen.dart'; // Para navegar de vuelta al Login

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Permitimos que el teclado ajuste la pantalla
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context); // Vuelve a la pantalla anterior (Welcome)
          },
          icon: const Icon(Icons.arrow_back_ios,
              size: 20, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView( // Permite hacer scroll si el contenido no cabe
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          // Usamos la altura del dispositivo menos el espacio ya ocupado por el AppBar y el padding superior
          height: MediaQuery.of(context).size.height - 80,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuye el espacio
            children: <Widget>[
              Column(
                children: <Widget>[
                  // Textos principales
                  const Text(
                    "¡Regístrate!",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Crea una cuenta, es gratis",
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  )
                ],
              ),
              Column(
                children: <Widget>[
                  // Campo para el nombre de usuario
                  const TextField(
                    decoration: InputDecoration(labelText: 'Usuario'),
                  ),
                  const SizedBox(height: 20),
                  // Campo para el email
                  const TextField(
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 20),
                  // Campo para la contraseña
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Contraseña'),
                  ),
                  const SizedBox(height: 20),
                  // Campo para confirmar la contraseña
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Confirmar Contraseña'),
                  ),
                ],
              ),
              // Botón de Registro
              MaterialButton(
                minWidth: double.infinity,
                height: 60,
                onPressed: () {
                  // La lógica de registro con Firebase irá aquí
                },
                color: const Color(0xff2A2A2A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  "Registrarse",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              // Texto para ir a Iniciar Sesión si ya se tiene cuenta
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("¿Ya tienes una cuenta?"),
                  GestureDetector(
                    onTap: () {
                      // Navega a la pantalla de Login al tocar el texto
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    child: const Text(
                      " Inicia sesión",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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