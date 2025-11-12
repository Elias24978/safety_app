import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Import correcto
import 'package:safety_app/models/aplicacion_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';

// ✅ CAMBIO: Importamos la nueva pantalla de detalle que crearemos en el siguiente paso.
import 'package:safety_app/screens/bolsa_trabajo/reclutador/detalle_aplicacion_screen.dart';

class SeguimientoTab extends StatefulWidget {
  const SeguimientoTab({super.key});

  @override
  State<SeguimientoTab> createState() => _SeguimientoTabState();
}

class _SeguimientoTabState extends State<SeguimientoTab> {
  late Future<List<Aplicacion>> _aplicacionesFuture;
  late String _userIdReclutador;
  bool _isLoading = true; // Para manejar la carga inicial del UserID

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ✅ Método correcto para obtener el UserID de Firebase
  Future<void> _loadData() async {
    // Obtenemos el UserID directamente de FirebaseAuth
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _userIdReclutador = user.uid;

      // Obtenemos el servicio de bolsa de trabajo
      final bolsaTrabajoService =
      Provider.of<BolsaTrabajoService>(context, listen: false);

      // Iniciamos la carga de datos
      setState(() {
        _aplicacionesFuture =
            bolsaTrabajoService.getAplicacionesEnSeguimiento(_userIdReclutador);
        _isLoading = false;
      });
    } else {
      // Manejar el caso donde el usuario no está logueado
      setState(() {
        _aplicacionesFuture = Future.value([]); // Futuro vacío
        _isLoading = false;
      });
    }
  }

  // Función para refrescar los datos
  Future<void> _refreshAplicaciones() async {
    final bolsaTrabajoService =
    Provider.of<BolsaTrabajoService>(context, listen: false);
    setState(() {
      // Re-lanzamos la petición (asumimos que _userIdReclutador ya está seteado)
      _aplicacionesFuture =
          bolsaTrabajoService.getAplicacionesEnSeguimiento(_userIdReclutador);
    });
  }

  // Helper para obtener color basado en el estado
  Color _getStatusColor(String estado) {
    switch (estado) {
      case '– En proceso':
        return Colors.blue.shade100;
      case '✓ Visto':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  // Helper para obtener el icono basado en el estado
  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case '– En proceso':
        return Icons.work_history_outlined;
      case '✓ Visto':
        return Icons.check_circle_outline;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si aún estamos cargando el UserID inicial
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAplicaciones,
        child: FutureBuilder<List<Aplicacion>>(
          future: _aplicacionesFuture,
          builder: (context, snapshot) {
            // Estado de Carga (del Future)
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Estado de Error
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error al cargar aplicaciones: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // Estado sin Datos o Lista Vacía
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No tienes candidatos en seguimiento activo.\nLos candidatos aparecerán aquí cuando marques su CV como "Visto" o "En proceso".',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            }

            // Estado con Datos (Lista de aplicaciones)
            final aplicaciones = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: aplicaciones.length,
              itemBuilder: (context, index) {
                final aplicacion = aplicaciones[index];

                return Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      backgroundColor:
                      _getStatusColor(aplicacion.estadoAplicacion),
                      child: Icon(
                        _getStatusIcon(aplicacion.estadoAplicacion),
                        color: Colors.black54,
                      ),
                    ),
                    title: Text(
                      aplicacion.nombreCandidato,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // ✅ CAMBIO: Añadido el teléfono y mejorado el overflow
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Vacante: ${aplicacion.tituloVacante}',
                          style: TextStyle(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Email: ${aplicacion.emailCandidato ?? 'No disponible'}',
                          style: TextStyle(color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tel: ${aplicacion.telefonoCandidato ?? 'No disponible'}',
                          style: TextStyle(color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        aplicacion.estadoAplicacion,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor:
                      _getStatusColor(aplicacion.estadoAplicacion),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    ),
                    isThreeLine: true,
                    // ✅ CAMBIO: Implementada la navegación a la pantalla de detalle
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleAplicacionScreen(
                            aplicacion: aplicacion,
                          ),
                        ),
                      );

                      // Si se actualizó algo, refrescamos la lista al volver
                      if (result == true && mounted) {
                        _refreshAplicaciones();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}