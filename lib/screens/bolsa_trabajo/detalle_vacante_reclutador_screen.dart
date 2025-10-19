import 'package:flutter/material.dart';
import 'package:safety_app/models/aplicacion_model.dart';
import 'package:safety_app/models/vacante_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart'; // ✅ CAMBIO: Se usa el nuevo servicio

class DetalleVacanteReclutadorScreen extends StatefulWidget {
  final Vacante vacante;

  const DetalleVacanteReclutadorScreen({super.key, required this.vacante});

  @override
  State<DetalleVacanteReclutadorScreen> createState() =>
      _DetalleVacanteReclutadorScreenState();
}

class _DetalleVacanteReclutadorScreenState extends State<DetalleVacanteReclutadorScreen> {
  // ✅ CAMBIO: Se usa la nueva clase de servicio
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  late Future<List<Aplicacion>> _aplicacionesFuture;

  @override
  void initState() {
    super.initState();
    _loadAplicaciones();
  }

  void _loadAplicaciones() {
    setState(() {
      // ✅ CAMBIO: Se llama al método desde el nuevo servicio
      _aplicacionesFuture = _bolsaTrabajoService.getAplicacionesPorVacante(widget.vacante.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vacante.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Conectar la lógica de edición que ya tenemos
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de detalles de la vacante
            const Text(
              'Detalles de la Publicación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Ubicación: ${widget.vacante.ubicacion}'),
            const SizedBox(height: 5),
            Text('Sueldo: ${widget.vacante.sueldoFormateado}'),
            const SizedBox(height: 5),
            Text('Publicada: ${widget.vacante.antiguedad}'),

            const Divider(height: 40),

            // Sección de la lista de candidatos
            const Text(
              'Candidatos Postulados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            FutureBuilder<List<Aplicacion>>(
              future: _aplicacionesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar los candidatos.'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text('Aún no hay candidatos para esta vacante.'),
                    ),
                  );
                }

                final aplicaciones = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: aplicaciones.length,
                  itemBuilder: (context, index) {
                    final aplicacion = aplicaciones[index];
                    return Card(
                      child: ListTile(
                        // TODO: Necesitamos el nombre del candidato en el modelo Aplicacion
                        title: const Text('Nombre del Candidato'),
                        subtitle: Text('Estado: ${aplicacion.estadoAplicacion}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navegar al perfil del candidato
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}