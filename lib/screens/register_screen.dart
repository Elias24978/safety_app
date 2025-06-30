import 'package:flutter/material.dart';
import 'package:safety_app/screens/menu_screen.dart';
import 'package:safety_app/services/auth_service.dart'; // Importamos nuestro nuevo servicio

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Clave para identificar y validar nuestro formulario.
  final _formKey = GlobalKey<FormState>();

  // Controladores para obtener el texto de los campos.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Instancia de nuestro servicio de autenticación.
  final AuthService _authService = AuthService();

  // Variable de estado para controlar la visualización del indicador de carga.
  bool _isLoading = false;

  @override
  void dispose() {
    // Es una buena práctica limpiar los controladores cuando el widget se destruye.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Método que se encarga de orquestar el proceso de registro.
  Future<void> _registerUser() async {
    // Si ya estamos cargando, no hacemos nada para evitar múltiples clics.
    if (_isLoading) return;

    // Valida el formulario usando la _formKey.
    if (_formKey.currentState?.validate() ?? false) {
      // Si el formulario es válido, activamos el estado de carga.
      setState(() {
        _isLoading = true;
      });

      // Llamamos a nuestro servicio para crear el usuario.
      final String? errorMessage = await _authService.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Una vez que tenemos respuesta, desactivamos el estado de carga.
      // Es crucial poner esta línea aquí para que el spinner desaparezca
      // tanto si hay éxito como si hay error.
      setState(() {
        _isLoading = false;
      });

      // Verificamos el resultado.
      if (errorMessage == null) {
        // Éxito: Navegamos a la pantalla del menú.
        if (mounted) { // Verificamos que el widget siga en pantalla.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MenuScreen()),
          );
        }
      } else {
        // Error: Mostramos el mensaje de error en un SnackBar.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa un correo.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor, ingresa un correo válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa una contraseña.';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50), // Botón ancho
                  ),
                  // Mostramos el spinner si está cargando, o el texto si no.
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}