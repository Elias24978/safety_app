// lib/screens/bolsa_trabajo/role_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/services/airtable_service.dart';
import 'package:safety_app/screens/bolsa_trabajo/crear_cv_screen.dart';
import 'package:safety_app/screens/placeholder_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/candidato_dashboard_screen.dart'; // ✅ NUEVA IMPORTACIÓN

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;
  final _airtableService = AirtableService();

  Future<void> _handleBuscarEmpleo() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Debes iniciar sesión para continuar.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final profile = await _airtableService.getCandidatoProfile(user.uid);

    if (!mounted) return;

    if (profile != null) {
      // ✅ CAMBIO: Si el perfil SÍ existe, va al nuevo Dashboard del Candidato.
      // Usamos pushReplacement para una mejor experiencia de usuario.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CandidatoDashboardScreen()),
      );
    } else {
      // Si el perfil NO existe, va al formulario para crearlo.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CrearCvScreen()),
      );
    }

    // No es necesario llamar a setState aquí, ya que la pantalla será reemplazada.
    // setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolsa de Trabajo'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Qué quieres hacer hoy?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _RoleButton(
                icon: FontAwesomeIcons.magnifyingGlass,
                label: 'Buscar Empleo',
                onPressed: _handleBuscarEmpleo,
              ),
              const SizedBox(height: 20),
              _RoleButton(
                icon: FontAwesomeIcons.fileSignature,
                label: 'Publicar una Vacante',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlaceholderScreen(title: 'Publicar Vacante')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para los botones, no necesita cambios.
class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _RoleButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: FaIcon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}