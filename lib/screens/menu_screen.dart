import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safety_app/screens/placeholder_screen.dart';
import 'package:safety_app/screens/notificaciones_list_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _bottomNavIndex = 0;
  User? _user;

  int _selectedGridIndex = 3;

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': FontAwesomeIcons.clipboardCheck,
      'label': "Revisar Normas STPS",
    },
    {
      'icon': FontAwesomeIcons.solidFileLines,
      'label': "Formatos",
    },
    {
      'icon': FontAwesomeIcons.certificate,
      'label': "Certificaciones DC3",
    },
    {
      'icon': FontAwesomeIcons.briefcase,
      'label': "Bolsa de Trabajo",
    },
    {
      'icon': FontAwesomeIcons.blog,
      'label': "Blog",
    },
    {
      'icon': FontAwesomeIcons.cartShopping,
      'label': "Compras",
    },
  ];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color backgroundColor = const Color(0xFFF5F5F5),
    Color iconColor = Colors.black87,
  }) {
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
            FaIcon(icon, size: 40, color: iconColor),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlaceholderScreen(title: title)),
    );
  }

  void _onBottomNavItemTapped(int index) {
    if (index == 0) {
      setState(() {
        _bottomNavIndex = index;
      });
      return;
    }

    switch (index) {
      case 1:
        _navigateToPlaceholder('Escritorio');
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsListScreen()));
        break;
      case 3:
        _navigateToPlaceholder('Tu Cuenta');
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
                    final isSelected = _selectedGridIndex == index;
                    final backgroundColor = isSelected ? const Color(0xFFFFD143) : const Color(0xFFF5F5F5);

                    return _buildMenuButton(
                      icon: item['icon'],
                      label: item['label'],
                      backgroundColor: backgroundColor,
                      onPressed: () {
                        setState(() {
                          _selectedGridIndex = index;
                        });
                        _navigateToPlaceholder(item['label']);
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