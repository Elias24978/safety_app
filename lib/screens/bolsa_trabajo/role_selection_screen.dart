import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart'; // ✅ CAMBIO: Importamos el nuevo servicio
import 'package:safety_app/screens/bolsa_trabajo/crear_cv_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/candidato_dashboard_screen.dart';
import 'package:safety_app/screens/menu_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/empresa_profile_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/reclutador_dashboard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;
  // ✅ CAMBIO: Usamos la nueva clase de servicio
  final _bolsaTrabajoService = BolsaTrabajoService();

  Future<void> _handleBuscarEmpleo() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Debes iniciar sesión para continuar.')));
      setState(() => _isLoading = false);
      return;
    }

    // ✅ CAMBIO: Llamamos al método desde la nueva variable
    final profile = await _bolsaTrabajoService.getCandidatoProfile(user.uid);
    if (!mounted) return;

    if (profile != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CandidatoDashboardScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CrearCvScreen()));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handlePublicarVacante() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Debes iniciar sesión para continuar.')));
      setState(() => _isLoading = false);
      return;
    }

    // ✅ CAMBIO: Llamamos al método desde la nueva variable
    final profile = await _bolsaTrabajoService.getEmpresaProfile(user.uid);
    if (!mounted) return;

    if (profile != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReclutadorDashboardScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const EmpresaProfileScreen()));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MenuScreen()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
        title: const Text('Bolsa de Trabajo'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Qué quieres hacer hoy?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _RoleButton(
                icon: FontAwesomeIcons.magnifyingGlass,
                label: 'Buscar Empleo',
                onPressed: _handleBuscarEmpleo,
              ),
              const SizedBox(height: 20),
              _RoleButton(
                icon: FontAwesomeIcons.fileSignature,
                label: 'Publicar una Vacante',
                onPressed: _handlePublicarVacante,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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