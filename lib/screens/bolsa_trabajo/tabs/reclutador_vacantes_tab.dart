import 'package:flutter/material.dart';
import 'package:safety_app/models/vacante_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/screens/bolsa_trabajo/crear_editar_vacante_screen.dart';

class ReclutadorVacantesTab extends StatefulWidget {
  final String userIdReclutador;
  final Function(Vacante) onEditVacante;

  const ReclutadorVacantesTab({
    super.key,
    required this.userIdReclutador,
    required this.onEditVacante,
  });

  @override
  // ✅ CAMBIO: Apunta a la nueva clase de estado pública
  State<ReclutadorVacantesTab> createState() => ReclutadorVacantesTabState();
}

// ✅ CAMBIO: La clase de estado ahora es pública (sin guion bajo)
class ReclutadorVacantesTabState extends State<ReclutadorVacantesTab> {
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  late Future<List<Vacante>> _misVacantesFuture;

  @override
  void initState() {
    super.initState();
    loadVacantes(); // ✅ CAMBIO: Llama al nuevo método público
  }

  // ✅ CAMBIO: El método ahora es público para ser llamado desde el dashboard
  void loadVacantes() {
    setState(() {
      _misVacantesFuture = _bolsaTrabajoService.getMisVacantes(widget.userIdReclutador);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Vacante>>(
        future: _misVacantesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar vacantes: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Aún no has publicado ninguna vacante.\nUsa el botón (+) para crear la primera.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final vacantes = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => loadVacantes(), // ✅ CAMBIO: Llama al nuevo método público
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: vacantes.length,
              itemBuilder: (context, index) {
                final vacante = vacantes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(vacante.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Estado: ${vacante.visibilidadOferta}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onEditVacante(vacante),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearEditarVacanteScreen()),
          );
          if (result == true) {
            loadVacantes(); // ✅ CAMBIO: Llama al nuevo método público
          }
        },
        label: const Text('Nueva Vacante'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}