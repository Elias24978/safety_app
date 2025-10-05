// lib/screens/bolsa_trabajo/candidato_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safety_app/screens/bolsa_trabajo/bolsa_trabajo_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/role_selection_screen.dart'; // ✅ IMPORTACIÓN AÑADIDA
import 'tabs/mi_cv_screen.dart';
import 'tabs/mis_postulaciones_screen.dart';

class CandidatoDashboardScreen extends StatefulWidget {
  const CandidatoDashboardScreen({super.key});

  @override
  State<CandidatoDashboardScreen> createState() => _CandidatoDashboardScreenState();
}

class _CandidatoDashboardScreenState extends State<CandidatoDashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    MiCvScreen(),
    BolsaTrabajoScreen(),
    MisPostulacionesScreen(),
  ];

  final List<String> _titles = const [
    'Mi Perfil de Candidato',
    'Buscar Vacantes',
    'Mis Postulaciones',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        // ✅ CAMBIO: Se añade un botón de regreso personalizado.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Esta navegación limpia el historial y te regresa a la pantalla de selección de rol.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.solidAddressCard),
            label: 'Mi CV',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.magnifyingGlass),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.solidFolderOpen),
            label: 'Postulaciones',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}