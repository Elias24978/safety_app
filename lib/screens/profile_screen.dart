import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safety_app/screens/notificaciones_list_screen.dart';
import 'package:safety_app/screens/placeholder_screen.dart';
import 'package:safety_app/services/database_service.dart';
import 'dart:developer'; // Importa el logger para reemplazar 'print'

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Simula el estado de la suscripción del usuario.
  bool isUserPremium = false;

  // Estado para el switch del tema
  bool _isDarkTheme = false;

  // Índice para la barra de navegación. 'Tu Cuenta' es el índice 3.
  final int _bottomNavIndex = 3;

  // Función para manejar la navegación desde la barra inferior
  void _onBottomNavItemTapped(int index) {
    // Si ya estamos en la pantalla, no hacemos nada
    if (index == _bottomNavIndex) return;

    switch (index) {
      case 0:
      // Regresa a la pantalla anterior (MenuScreen)
        Navigator.pop(context);
        break;
      case 1:
      // Reemplaza la pantalla actual por la de 'Escritorio'
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PlaceholderScreen(title: 'Escritorio')),
        );
        break;
      case 2:
      // Reemplaza la pantalla actual por la de 'Notificaciones'
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationsListScreen()));
        break;
    }
  }

  /// Inicia el proceso de compra de la suscripción premium usando RevenueCat.
  Future<void> _purchasePremium() async {
    final databaseService = DatabaseService();
    try {
      // 1. Obtener los "Offerings" (ofertas) que configuraste en RevenueCat.
      final Offerings offerings = await Purchases.getOfferings();

      if (!mounted) return;

      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        // 2. Presentar la pantalla de pago al usuario.
        final Package packageToPurchase =
            offerings.current!.availablePackages.first;

        // --- INICIO DE LA CORRECCIÓN ---
        // La versión 9.x del paquete devuelve un `PurchaseResult`.
        final PurchaseResult purchaseResult =
        await Purchases.purchasePackage(packageToPurchase);

        // 3. Verificar si el "entitlement" premium está activo.
        // Se accede a `customerInfo` a través de `purchaseResult`.
        if (purchaseResult.customerInfo.entitlements.all['premium'] != null &&
            purchaseResult.customerInfo.entitlements.all['premium']!.isActive) {
          // --- FIN DE LA CORRECCIÓN ---

          // ¡ÉXITO! El usuario es premium. Actualiza Firestore.
          await databaseService.updateUserPremiumStatus(true);

          // Actualiza el estado local para reflejar el cambio en la UI.
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
      // Manejar errores (ej. el usuario canceló la compra).
      log("Error en la compra: $e"); // Usar log en vez de print

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
        // Con esta línea se quita la flecha de retroceso.
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // El banner se oculta si el usuario ya es premium.
          if (!isUserPremium) _buildPremiumBanner(),
          const SizedBox(height: 10),
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
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title:
            const Text('Eliminar Cuenta', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Escritorio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notificaciones'),
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
          contentPadding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          leading: const Icon(Icons.shield, color: Colors.white, size: 40),
          title: const Text('Obtener Premium',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          subtitle: const Text('Elaboración de reportes y más',
              style: TextStyle(color: Colors.white70)),
          onTap: _purchasePremium, // Llama a la función de compra.
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