import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safety_app/models/aplicacion_model.dart';
import 'package:safety_app/models/vacante_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart'; // ✅ CAMBIO: Importamos el nuevo servicio
import 'package:safety_app/screens/bolsa_trabajo/detalle_vacante_screen.dart';

class MisPostulacionesScreen extends StatefulWidget {
  const MisPostulacionesScreen({super.key});

  @override
  State<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class StatusInfo {
  final Color color;
  final IconData icon;
  final Color contentColor;

  StatusInfo({required this.color, required this.icon, required this.contentColor});
}

class _MisPostulacionesScreenState extends State<MisPostulacionesScreen> {
  // ✅ CAMBIO: Usamos la nueva clase de servicio
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  late Future<List<Aplicacion>> _postulacionesFuture;

  @override
  void initState() {
    super.initState();
    _loadPostulaciones();
  }

  void _loadPostulaciones() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        // ✅ CAMBIO: Llamamos al método desde la nueva variable
        _postulacionesFuture = _bolsaTrabajoService.getMisPostulaciones(userId);
      });
    } else {
      setState(() {
        _postulacionesFuture = Future.value([]);
      });
    }
  }

  StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case '✓ CV Visto':
        return StatusInfo(color: Colors.purple.shade50, icon: Icons.visibility, contentColor: Colors.purple.shade800);
      case '– En proceso':
        return StatusInfo(color: Colors.orange.shade50, icon: Icons.sync, contentColor: Colors.orange.shade800);
      case '✗ Proceso finalizado':
        return StatusInfo(color: Colors.red.shade50, icon: Icons.do_not_disturb_alt, contentColor: Colors.red.shade800);
      case '✓ CV Recibido':
      default:
        return StatusInfo(color: Colors.blue.shade50, icon: Icons.check_circle, contentColor: Colors.blue.shade800);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Postulaciones'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Aplicacion>>(
        future: _postulacionesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar tus postulaciones: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Aún no te has postulado a ninguna vacante.\n¡Anímate a encontrar tu próximo reto!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final postulaciones = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadPostulaciones(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: postulaciones.length,
              itemBuilder: (context, index) {
                final aplicacion = postulaciones[index];
                final statusInfo = _getStatusInfo(aplicacion.estadoAplicacion);
                final sueldo = aplicacion.sueldoOfertado;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      final vacante = Vacante(
                        id: aplicacion.vacanteRecordId,
                        titulo: aplicacion.tituloVacante,
                        nombreEmpresa: aplicacion.nombreEmpresa,
                        ubicacion: aplicacion.ubicacion,
                        descripcion: aplicacion.descripcion,
                        sueldo: aplicacion.sueldoOfertado,
                        aceptaForaneos: aplicacion.aceptaForaneos,
                        ultimoModificacion: aplicacion.ultimoModificacion,
                        fechaPublicacion: aplicacion.fechaPublicacion,
                        visibilidadOferta: aplicacion.visibilidadOferta,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleVacanteScreen(
                            vacante: vacante,
                            haAplicado: true,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  aplicacion.tituloVacante,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                avatar: Icon(statusInfo.icon, size: 16, color: statusInfo.contentColor),
                                label: Text(
                                  aplicacion.estadoAplicacion,
                                  style: TextStyle(fontWeight: FontWeight.w500, color: statusInfo.contentColor),
                                ),
                                backgroundColor: statusInfo.color,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(aplicacion.nombreEmpresa, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(aplicacion.ubicacion, style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
                            ],
                          ),
                          if (sueldo != null && sueldo > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.monetization_on, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(sueldo),
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
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