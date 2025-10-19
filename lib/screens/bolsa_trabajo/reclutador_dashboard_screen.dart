import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/models/empresa_model.dart';
import 'package:safety_app/models/vacante_model.dart';
import 'package:safety_app/screens/bolsa_trabajo/crear_editar_vacante_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/empresa_profile_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/role_selection_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/tabs/reclutador_vacantes_tab.dart';
import 'package:safety_app/screens/bolsa_trabajo/tabs/buscar_candidatos_tab.dart';
import 'package:safety_app/screens/bolsa_trabajo/tabs/seguimiento_tab.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/utils/dialogs.dart';

class ReclutadorDashboardScreen extends StatefulWidget {
  const ReclutadorDashboardScreen({super.key});

  @override
  State<ReclutadorDashboardScreen> createState() => _ReclutadorDashboardScreenState();
}

class _ReclutadorDashboardScreenState extends State<ReclutadorDashboardScreen> {
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  Empresa? _empresaProfile;
  bool _isLoadingProfile = true;

  // ✅ CAMBIO: Se añade una GlobalKey para poder llamar al método de refresco de la pestaña
  final GlobalKey<ReclutadorVacantesTabState> _vacantesTabKey = GlobalKey<ReclutadorVacantesTabState>();

  @override
  void initState() {
    super.initState();
    _fetchEmpresaProfile();
  }

  Future<void> _fetchEmpresaProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) showSnackBar(context, 'Necesitas iniciar sesión.', Colors.red);
      setState(() => _isLoadingProfile = false);
      return;
    }
    try {
      final Empresa? empresa = await _bolsaTrabajoService.getEmpresaProfile(user.uid);
      if (mounted) {
        setState(() {
          _empresaProfile = empresa;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error al cargar perfil de empresa: $e', Colors.red);
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  // ✅ CAMBIO: La función ahora es 'async' y espera el resultado de la pantalla de edición
  Future<void> _navigateToEditVacante(Vacante vacante) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEditarVacanteScreen(vacante: vacante),
      ),
    );

    // Si la pantalla de edición devolvió 'true' (porque se guardó o eliminó algo),
    // usamos la GlobalKey para llamar al método público de la pestaña y refrescar la lista.
    if (result == true && mounted) {
      _vacantesTabKey.currentState?.loadVacantes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
          title: const Text('Panel de Reclutador'),
          backgroundColor: Colors.deepPurple[800],
          foregroundColor: Colors.white,
          elevation: 4,
          bottom: TabBar(
            indicatorColor: Colors.amberAccent,
            labelColor: Colors.amberAccent,
            unselectedLabelColor: Colors.purple[200],
            tabs: const [
              Tab(icon: Icon(Icons.work), text: 'Mis Vacantes'),
              Tab(icon: Icon(Icons.search), text: 'Buscar CVs'),
              Tab(icon: Icon(Icons.track_changes), text: 'Seguimiento'),
            ],
          ),
        ),
        body: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : _empresaProfile == null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_center, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                const Text(
                  'Parece que aún no tienes un perfil de empresa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmpresaProfileScreen()),
                    ).then((_) => _fetchEmpresaProfile()); // Refresca al volver
                  },
                  icon: const Icon(Icons.add_business),
                  label: const Text('Crear Perfil de Empresa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        )
            : TabBarView(
          children: [
            ReclutadorVacantesTab(
              key: _vacantesTabKey, // ✅ CAMBIO: Asignamos la key a la pestaña
              userIdReclutador: FirebaseAuth.instance.currentUser!.uid,
              onEditVacante: _navigateToEditVacante,
            ),
            const BuscarCandidatosTab(),
            const SeguimientoTab(),
          ],
        ),
      ),
    );
  }
}