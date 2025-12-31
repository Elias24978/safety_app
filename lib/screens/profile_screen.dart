import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safety_app/screens/notificaciones_list_screen.dart';
import 'package:safety_app/screens/placeholder_screen.dart';
import 'package:safety_app/services/database_service.dart';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/screens/welcome_screen.dart';
// Importamos la pantalla de carga (asegúrate de que el archivo exista en esta ruta)
import 'package:safety_app/screens/admin/admin_upload_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isUserPremium = false;
  bool _isDarkTheme = false;
  final int _bottomNavIndex = 3;

  // 🔒 SEGURIDAD: Definimos el correo del administrador
  final String _adminEmail = "eliasrmz24@gmail.com";
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  // Verificamos si el usuario actual es el admin
  void _checkAdminStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email == _adminEmail) {
      setState(() {
        _isAdmin = true;
      });
    }
  }

  void _onBottomNavItemTapped(int index) {
    if (index == _bottomNavIndex) return;

    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PlaceholderScreen(title: 'Escritorio')),
        );
        break;
      case 2:
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationsListScreen()));
        break;
    }
  }

  Future<void> _purchasePremium() async {
    final databaseService = DatabaseService();
    try {
      final Offerings offerings = await Purchases.getOfferings();

      if (!mounted) return;

      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        final Package packageToPurchase =
            offerings.current!.availablePackages.first;

        final PurchaseResult purchaseResult =
        await Purchases.purchasePackage(packageToPurchase);

        if (purchaseResult.customerInfo.entitlements.all['premium'] != null &&
            purchaseResult.customerInfo.entitlements.all['premium']!.isActive) {

          await databaseService.updateUserPremiumStatus(true);

          setState(() {
            isUserPremium = true;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Gracias! Ahora eres Premium.')),
          );
        }
      }
    } catch (e) {
      log("Error en la compra: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La compra fue cancelada o falló.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tú'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          if (!isUserPremium) _buildPremiumBanner(),
          const SizedBox(height: 10),

          // --- SECCIÓN ADMIN (SOLO VISIBLE PARA TI) ---
          if (_isAdmin) ...[
            _buildSectionTitle('Administración'),
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.orange),
              title: const Text('Subir/Actualizar Cursos'),
              subtitle: const Text('Panel de control de contenido'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminUploadScreen()),
                );
              },
            ),
            const Divider(height: 20),
          ],
          // ---------------------------------------------

          _buildSectionTitle('Información de la Cuenta'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Nombre y Apellido'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Correo Electrónico'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Número de Teléfono'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          if (isUserPremium)
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Gestionar Suscripción'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                log("Navegar a pantalla de gestión de suscripción");
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Gestionar Contraseña'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                log("Navegar a gestionar contraseña");
              },
            ),
          const Divider(height: 20),
          _buildSectionTitle('Configuración y Soporte'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacidad y Datos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Tema'),
            trailing: Switch(
              value: _isDarkTheme,
              onChanged: (value) {
                setState(() {
                  _isDarkTheme = value;
                });
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Soporte y Comentarios'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 20),
          _buildSectionTitle('Acciones de la Cuenta'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (Route<dynamic> route) => false,
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
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
    );
  }

  Widget _buildPremiumBanner() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          leading: const Icon(Icons.shield, color: Colors.white, size: 40),
          title: const Text('Obtener Premium',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          subtitle: const Text('Elaboración de reportes y más',
              style: TextStyle(color: Colors.white70)),
          onTap: _purchasePremium,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}