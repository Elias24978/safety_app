// (El código para esta pantalla es el mismo que en la respuesta anterior,
// ya que su lógica de mostrar el estado en la lista es correcta)
// ...
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/aplicacion_model.dart';
import '../../models/vacante_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'detalle_vacante_screen.dart';

class BolsaTrabajoScreen extends StatefulWidget {
  const BolsaTrabajoScreen({super.key});

  @override
  State<BolsaTrabajoScreen> createState() => _BolsaTrabajoScreenState();
}

class _BolsaTrabajoScreenState extends State<BolsaTrabajoScreen> {
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("Usuario no autenticado.");
    }

    final results = await Future.wait([
      _bolsaTrabajoService.getVisibleVacantes(),
      _bolsaTrabajoService.getMisPostulaciones(userId),
    ]);

    return {
      'vacantes': results[0] as List<Vacante>,
      'aplicaciones': results[1] as List<Aplicacion>,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los datos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || (snapshot.data!['vacantes'] as List).isEmpty) {
            return const Center(child: Text('No hay vacantes disponibles por el momento.'));
          }

          final List<Vacante> vacantes = snapshot.data!['vacantes'];
          final List<Aplicacion> aplicaciones = snapshot.data!['aplicaciones'];

          final appliedVacanteIds = aplicaciones.map((app) => app.vacanteRecordId).toSet();

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: vacantes.length,
              itemBuilder: (context, index) {
                final vacante = vacantes[index];
                final bool hasApplied = appliedVacanteIds.contains(vacante.id);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleVacanteScreen(
                            vacante: vacante,
                            haAplicado: hasApplied,
                          ),
                        ),
                      ).then((_) => _loadData());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  vacante.titulo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(vacante.antiguedad, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(vacante.nombreEmpresa, style: TextStyle(fontSize: 15, color: Colors.grey[800])),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(vacante.ubicacion, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            vacante.sueldoFormateado,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: vacante.sueldo != null ? Colors.green[800] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (vacante.aceptaForaneos)
                                Chip(
                                  avatar: Icon(Icons.public, size: 16, color: Colors.blue[800]),
                                  label: Text('Acepta foráneos', style: TextStyle(color: Colors.blue[800])),
                                  backgroundColor: Colors.blue[50],
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              const Spacer(),
                              if (hasApplied)
                                Chip(
                                  avatar: Icon(Icons.check_circle, size: 16, color: Colors.white),
                                  label: const Text('CV Enviado', style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}