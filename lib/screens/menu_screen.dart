import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safety_app/screens/dc3/dc3_main_screen.dart'; // <--- 1. IMPORTACIÓN AGREGADA
import 'package:safety_app/screens/escritorio_screen.dart';
import 'package:safety_app/screens/normas_stps_screen.dart';
import 'package:safety_app/screens/notificaciones_list_screen.dart';
import 'package:safety_app/screens/placeholder_screen.dart';
import 'package:safety_app/screens/profile_screen.dart';
import 'package:safety_app/services/ad_manager.dart';
import 'package:safety_app/services/database_service.dart';
import 'package:safety_app/screens/formatos_screen.dart';

class MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
    isSelected ? const Color(0xFFFFD143) : const Color(0xFFF5F5F5);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
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
}


class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Al usar el AdManager con el patrón Singleton, esta llamada siempre
  // devuelve la única instancia existente, evitando errores.
  final AdManager _adManager = AdManager();
  final DatabaseService _databaseService = DatabaseService();

  int _bottomNavIndex = 0;
  User? _user;
  int _selectedGridIndex = -1;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': FontAwesomeIcons.clipboardCheck, 'label': "Revisar Normas STPS"},
    {'icon': FontAwesomeIcons.solidFileLines, 'label': "Formatos"},
    {'icon': FontAwesomeIcons.certificate, 'label': "Certificaciones DC3"},
    {'icon': FontAwesomeIcons.briefcase, 'label': "Bolsa de Trabajo"},
    {'icon': FontAwesomeIcons.blog, 'label': "Blog"},
    {'icon': FontAwesomeIcons.cartShopping, 'label': "Compras"},
  ];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  void _navigateToPlaceholder(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlaceholderScreen(title: title)),
    );
  }

  void _onGridItemTapped(String label) {
    if (label == "Revisar Normas STPS") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NormasStpsScreen()),
      );
      return;
    }

    void navigateAction() {
      // --- 2. INICIO DE LA MODIFICACIÓN ---
      if (label == "Formatos") {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const FormatosScreen()));
      } else if (label == "Certificaciones DC3") {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Dc3MainScreen()));
      }
      // --- FIN DE LA MODIFICACIÓN ---
      else {
        _navigateToPlaceholder(label);
      }
    }

    final itemsWithAds = [
      "Formatos",
      "Certificaciones DC3",
      "Bolsa de Trabajo"
    ];

    _databaseService.isUserPremiumStream.first.then((isPremium) {
      if (!mounted) return;

      if (!isPremium && itemsWithAds.contains(label)) {
        _adManager.showAdAndNavigate(navigateAction);
      } else {
        navigateAction();
      }
    });
  }

  void _onBottomNavItemTapped(int index) {
    if (index == _bottomNavIndex) return;

    if (index == 0) {
      setState(() {
        _bottomNavIndex = index;
      });
      return;
    }

    switch (index) {
      case 1:
        _databaseService.isUserPremiumStream.first.then((isPremium) {
          if (!mounted) return;

          if (isPremium) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const EscritorioScreen()));
          } else {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El Escritorio es una función Premium.'),
                backgroundColor: Colors.deepPurple,
              ),
            );
          }
        });
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const NotificationsListScreen()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        currentIndex: _bottomNavIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNavItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Hola $displayName",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "¿Qué haremos el día de hoy?",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];

                    return MenuButton(
                      icon: item['icon'],
                      label: item['label'],
                      isSelected: _selectedGridIndex == index,
                      onPressed: () {
                        setState(() {
                          _selectedGridIndex = index;
                        });
                        _onGridItemTapped(item['label']);
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
}