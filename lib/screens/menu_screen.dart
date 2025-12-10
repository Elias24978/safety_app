import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/models/empresa_model.dart';
import 'package:safety_app/screens/dc3/dc3_main_screen.dart';
import 'package:safety_app/screens/escritorio_screen.dart';
import 'package:safety_app/screens/normas_stps_screen.dart';
import 'package:safety_app/screens/notificaciones_list_screen.dart';
import 'package:safety_app/screens/placeholder_screen.dart';
import 'package:safety_app/screens/profile_screen.dart';
import 'package:safety_app/services/ad_manager.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/services/database_service.dart';
import 'package:safety_app/screens/formatos_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/role_selection_screen.dart';
import 'package:safety_app/screens/comunidad/comunidad_screen.dart';
// ✅ IMPORTACIÓN NUEVA: Pantalla de Compras
import 'package:safety_app/screens/compras/compras_screen.dart';

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
  final AdManager _adManager = AdManager();
  final DatabaseService _databaseService = DatabaseService();
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();

  int _bottomNavIndex = 0;
  User? _user;
  int _selectedGridIndex = -1;
  String _userName = 'Usuario';

  // Lista de botones del menú
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': FontAwesomeIcons.clipboardCheck, 'label': "Revisar Normas STPS"},
    {'icon': FontAwesomeIcons.solidFileLines, 'label': "Formatos"},
    {'icon': FontAwesomeIcons.certificate, 'label': "Certificaciones DC3"},
    {'icon': FontAwesomeIcons.briefcase, 'label': "Bolsa de Trabajo"},
    {'icon': FontAwesomeIcons.users, 'label': "Comunidad"},
    // ✅ CAMBIO: Nombre actualizado a "Marketplace"
    {'icon': FontAwesomeIcons.shop, 'label': "Marketplace"},
  ];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (_user == null) return;

    Candidato? candidato = await _bolsaTrabajoService.getCandidatoProfile(_user!.uid);
    if (candidato != null && candidato.nombre != 'Sin Nombre') {
      if (mounted) {
        setState(() => _userName = candidato.nombre.split(' ').first);
      }
      return;
    }

    Empresa? empresa = await _bolsaTrabajoService.getEmpresaProfile(_user!.uid);
    if (empresa != null && empresa.nombreEmpresa != 'Sin Nombre') {
      if (mounted) {
        setState(() => _userName = empresa.nombreEmpresa);
      }
      return;
    }

    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      if (mounted) {
        setState(() => _userName = _user!.displayName!);
      }
    }
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
      if (label == "Formatos") {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const FormatosScreen()));
      } else if (label == "Certificaciones DC3") {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Dc3MainScreen()));
      }
      else if (label == "Bolsa de Trabajo") {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const RoleSelectionScreen()));
      }
      else if (label == "Comunidad") {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const ComunidadScreen()));
      }
      // ✅ CAMBIO: Navegación conectada a ComprasScreen
      else if (label == "Marketplace") {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const ComprasScreen()));
      }
      else {
        _navigateToPlaceholder(label);
      }
    }

    final itemsWithAds = [
      "Formatos",
      "Certificaciones DC3",
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
      setState(() => _bottomNavIndex = index);
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
                "Hola $_userName",
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
                        setState(() => _selectedGridIndex = index);
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