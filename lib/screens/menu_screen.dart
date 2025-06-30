import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safety_app/screens/placeholder_screen.dart';

// --- WIDGET PRINCIPAL QUE CONTROLA LA NAVEGACIÓN ---
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0; // El índice para el BottomNavigationBar

  // --- ¡NUEVO! LISTA DE PANTALLAS ---
  // Cada elemento en esta lista corresponde a un botón de la barra de navegación.
  static final List<Widget> _widgetOptions = <Widget>[
    const _MenuGrid(), // La cuadrícula del menú es ahora la primera pantalla (índice 0)
    const PlaceholderScreen(title: 'Escritorio'), // Pantalla temporal para el índice 1
    const PlaceholderScreen(title: 'Notificaciones'), // Pantalla temporal para el índice 2
    const PlaceholderScreen(title: 'Tu Cuenta'), // Pantalla temporal para el índice 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- ¡NUEVO! EL BODY AHORA ES DINÁMICO ---
      // Muestra el widget de la lista que corresponde al índice seleccionado.
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Escritorio'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notificaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tu Cuenta'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Llama a la función para cambiar de pantalla
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}


// --- ¡NUEVO! WIDGET SEPARADO PARA LA CUADRÍCULA DEL MENÚ ---
// Hemos extraído la lógica de la cuadrícula a su propio widget para mantener el código limpio.
class _MenuGrid extends StatefulWidget {
  const _MenuGrid();

  @override
  State<_MenuGrid> createState() => _MenuGridState();
}

class _MenuGridState extends State<_MenuGrid> {
  int _selectedGridIndex = -1;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  void _navigateToPlaceholder(String title) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PlaceholderScreen(title: title)));
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _user?.displayName ?? 'Usuario';

    final menuItems = [
      {'icon': FontAwesomeIcons.clipboardCheck, 'label': "Revisar Normas STPS"},
      {'icon': FontAwesomeIcons.solidFileLines, 'label': "Formatos"},
      {'icon': FontAwesomeIcons.certificate, 'label': "Certificaciones DC3"},
      {'icon': FontAwesomeIcons.briefcase, 'label': "Bolsa de Trabajo"},
      {'icon': FontAwesomeIcons.blog, 'label': "Blog"},
      {'icon': FontAwesomeIcons.cartShopping, 'label': "Compras"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Hola $displayName",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                "¿Qué haremos el día de hoy?",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final isSelected = _selectedGridIndex == index;
                    final Color backgroundColor = isSelected ? const Color(0xFFFFD143) : const Color(0xFFF5F5F5);

                    return _buildMenuButton(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                      backgroundColor: backgroundColor,
                      onPressed: () {
                        setState(() { _selectedGridIndex = index; });
                        _navigateToPlaceholder(item['label'] as String);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // El widget para construir los botones sigue siendo el mismo.
  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 40, color: Colors.black87),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}