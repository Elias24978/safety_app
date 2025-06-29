import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Importamos la librería de íconos
import 'package:safety_app/screens/placeholder_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;
  User? _user; // Variable para guardar los datos del usuario

  @override
  void initState() {
    super.initState();
    // Obtenemos el usuario actual cuando la pantalla se inicia
    _user = FirebaseAuth.instance.currentUser;
  }

  // --- WIDGET AUXILIAR MEJORADO ---
  // Añadimos un parámetro para el color de fondo
  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color backgroundColor = const Color(0xFFF5F5F5), // Gris claro por defecto
    Color iconColor = Colors.black87,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20), // Bordes más redondeados
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 40, color: iconColor), // Usamos FaIcon para los nuevos íconos
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPlaceholder(String title) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PlaceholderScreen(title: title)));
  }

  @override
  Widget build(BuildContext context) {
    // Extraemos la primera parte del email para mostrarla como nombre
    final String displayName = _user?.displayName ?? 'Usuario';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Escritorio'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notificaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tu Cuenta'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple, // Color morado como en la imagen
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          setState(() { _selectedIndex = index; });
        },
        type: BottomNavigationBarType.fixed, // Asegura que todos los ítems se vean
        showUnselectedLabels: true, // Muestra los labels de los ítems no seleccionados
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20), // Espacio superior
              // --- TEXTOS ACTUALIZADOS ---
              Text(
                "Hola $displayName",
                style: const TextStyle(
                  fontSize: 32, // Tamaño de letra más grande
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "¿Qué haremos el día de hoy?",
                style: TextStyle(
                  fontSize: 18, // Tamaño de letra más pequeño
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),

              // --- CUADRÍCULA CON ÍCONOS Y LABELS ACTUALIZADOS ---
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: <Widget>[
                    _buildMenuButton(
                      icon: FontAwesomeIcons.clipboardCheck,
                      label: "Revisar Normas STPS",
                      onPressed: () => _navigateToPlaceholder("Revisar Normas STPS"),
                    ),
                    _buildMenuButton(
                      icon: FontAwesomeIcons.solidFileLines,
                      label: "Formatos",
                      onPressed: () => _navigateToPlaceholder("Formatos"),
                    ),
                    _buildMenuButton(
                      icon: FontAwesomeIcons.certificate,
                      label: "Certificaciones DC3",
                      onPressed: () => _navigateToPlaceholder("Certificaciones DC3"),
                    ),
                    // Botón con color de fondo personalizado
                    _buildMenuButton(
                      icon: FontAwesomeIcons.briefcase,
                      label: "Bolsa de Trabajo",
                      onPressed: () => _navigateToPlaceholder("Bolsa de Trabajo"),
                      backgroundColor: const Color(0xFFFFD143), // Fondo amarillo
                    ),
                    _buildMenuButton(
                      icon: FontAwesomeIcons.blog,
                      label: "Blog",
                      onPressed: () => _navigateToPlaceholder("Blog"),
                    ),
                    _buildMenuButton(
                      icon: FontAwesomeIcons.cartShopping,
                      label: "Compras",
                      onPressed: () => _navigateToPlaceholder("Compras"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}