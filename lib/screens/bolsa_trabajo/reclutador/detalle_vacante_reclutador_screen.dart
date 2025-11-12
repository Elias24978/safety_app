import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safety_app/models/aplicacion_model.dart';
import 'package:safety_app/models/vacante_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/screens/bolsa_trabajo/reclutador/detalle_aplicacion_screen.dart';

class DetalleVacanteReclutadorScreen extends StatefulWidget {
  final Vacante vacante;

  const DetalleVacanteReclutadorScreen({super.key, required this.vacante});

  @override
  State<DetalleVacanteReclutadorScreen> createState() =>
      _DetalleVacanteReclutadorScreenState();
}

class _DetalleVacanteReclutadorScreenState
    extends State<DetalleVacanteReclutadorScreen> {
  late BolsaTrabajoService _bolsaTrabajoService;
  late Future<List<Aplicacion>> _aplicacionesFuture;

  // Creamos una lista local para manejar los datos filtrados
  List<Aplicacion> _nuevasAplicaciones = [];

  @override
  void initState() {
    super.initState();
    // Obtenemos la instancia del servicio desde el Provider
    _bolsaTrabajoService =
        Provider.of<BolsaTrabajoService>(context, listen: false);
    // Iniciamos la carga de aplicaciones
    _loadAplicaciones();
  }

  // Método para cargar y filtrar las aplicaciones
  void _loadAplicaciones() {
    setState(() {
      _aplicacionesFuture = _bolsaTrabajoService
          .getAplicacionesPorVacante(widget.vacante.id)
          .then((listaCompleta) {
        // Filtramos aquí para obtener solo las que están en "CV Recibido"
        _nuevasAplicaciones = listaCompleta
            .where((app) => app.estadoAplicacion == '✓ CV Recibido')
            .toList();
        return _nuevasAplicaciones;
      });
    });
  }

  // Método para refrescar con pull-to-refresh
  Future<void> _refreshData() async {
    // Simplemente volvemos a llamar a loadAplicaciones
    _loadAplicaciones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vacante.titulo),
        backgroundColor: Colors.deepPurple[800],
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Aplicacion>>(
          future: _aplicacionesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error.toString()}'));
            }

            // Usamos la lista local _nuevasAplicaciones que ya está filtrada
            if (_nuevasAplicaciones.isEmpty) {
              return _buildEmptyState();
            }

            // Si llegamos aquí, tenemos nuevos candidatos
            return _buildCandidateList();
          },
        ),
      ),
    );
  }

  // Widget para la lista de candidatos
  Widget _buildCandidateList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _nuevasAplicaciones.length,
      itemBuilder: (context, index) {
        final aplicacion = _nuevasAplicaciones[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.person_outline, color: Colors.teal),
            ),
            title: Text(
              aplicacion.nombreCandidato,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(aplicacion.emailCandidato ?? 'Email no disponible'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // ✅ CAMBIO: Capturamos el Navigator ANTES del await.
              final navigator = Navigator.of(context);

              // Navegamos a la pantalla de detalle de la aplicación
              final bool? seActualizo = await navigator.push<bool>(
                MaterialPageRoute(
                  builder: (context) =>
                      DetalleAplicacionScreen(aplicacion: aplicacion),
                ),
              );

              // Verificamos si el widget sigue montado después del 'await'
              if (!mounted) return;

              // Si seActualizo es true (porque se finalizó el proceso)
              // O si la aplicación que tocamos ahora tiene estado "Visto"
              // (porque la pantalla de detalle lo actualiza automáticamente)
              // debemos refrescar esta lista.

              // ESTA LÓGICA ES INSEGURA Y PROVOCA EL LINTER ERROR
              // if (seActualizo == true ||
              //     _nuevasAplicaciones[index].estadoAplicacion == '✓ Visto') { ... }

              // ✅ CAMBIO: Lógica segura
              // La pantalla de detalle (DetalleAplicacionScreen) ahora
              // SIEMPRE devuelve 'true' si un estado cambió.
              // Así que solo necesitamos comprobar 'seActualizo'.
              // (Tendremos que ajustar 'DetalleAplicacionScreen' en el siguiente paso)
              if (seActualizo == true) {
                _refreshData();

                // Le decimos a la pantalla anterior (Mis Vacantes) que también
                // debe refrescarse cuando cerremos esta.
                // ✅ CAMBIO: Usamos la variable 'navigator' que guardamos.
                navigator.pop(true);
              }
            },
          ),
        );
      },
    );
  }

  // Widget para cuando no hay nuevos candidatos
  Widget _buildEmptyState() {
    // ... (este widget no cambia)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Bandeja de entrada vacía',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No tienes nuevos candidatos (con estado "CV Recibido") para esta vacante. Los candidatos que ya estás siguiendo están en la pestaña "Seguimiento".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}