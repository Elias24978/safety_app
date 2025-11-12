import 'package:flutter/material.dart';
import 'package:safety_app/models/vacante_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/screens/bolsa_trabajo/crear_editar_vacante_screen.dart';

// ✅ CAMBIO: Importamos la nueva pantalla que mostrará la lista de candidatos
import 'package:safety_app/screens/bolsa_trabajo/reclutador/detalle_vacante_reclutador_screen.dart';

class ReclutadorVacantesTab extends StatefulWidget {
  final String userIdReclutador;
  final Function(Vacante) onEditVacante;

  const ReclutadorVacantesTab({
    super.key,
    required this.userIdReclutador,
    required this.onEditVacante,
  });

  @override
  State<ReclutadorVacantesTab> createState() => ReclutadorVacantesTabState();
}

class ReclutadorVacantesTabState extends State<ReclutadorVacantesTab> {
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  late Future<List<Vacante>> _misVacantesFuture;

  @override
  void initState() {
    super.initState();
    loadVacantes();
  }

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
            onRefresh: () async => loadVacantes(),
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

                    // ✅ CAMBIO: El 'trailing' ahora es un botón específico para editar
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar Vacante',
                      onPressed: () => widget.onEditVacante(vacante),
                    ),

                    // ✅ CAMBIO: El 'onTap' principal ahora navega al detalle de la vacante (para ver candidatos)
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleVacanteReclutadorScreen(vacante: vacante),
                        ),
                      );

                      // Si regresamos 'true' (ej. se actualizó algo), refrescamos la lista
                      if (result == true) {
                        loadVacantes();
                      }
                    },
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
            loadVacantes();
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