import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/models/aplicacion_model.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/screens/bolsa_trabajo/detalle_candidato_reclutador_screen.dart';

class SeguimientoTab extends StatefulWidget {
  const SeguimientoTab({super.key});

  @override
  State<SeguimientoTab> createState() => _SeguimientoTabState();
}

class _SeguimientoTabState extends State<SeguimientoTab> {
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  late Future<List<Aplicacion>> _seguimientoFuture;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadSeguimiento();
  }

  void _loadSeguimiento() {
    if (_userId != null) {
      setState(() {
        // NOTA: Este método aún no existe en BolsaTrabajoService.
        // Lo crearemos en el siguiente paso.
        _seguimientoFuture = _bolsaTrabajoService.getAplicacionesEnSeguimiento(_userId!);
      });
    } else {
      _seguimientoFuture = Future.value([]);
    }
  }

  // Pequeño helper para construir el objeto Candidato desde la Aplicacion
  Candidato _candidatoFromAplicacion(Aplicacion aplicacion) {
    // NOTA: Esto fallará hasta que actualicemos el modelo Aplicacion
    // para que incluya los datos del candidato.
    return Candidato(
      recordId: aplicacion.recordId, // Esto deberá cambiarse por el recordId del candidato
      userId: aplicacion.recordId, // Esto deberá cambiarse por el userId del candidato
      nombre: aplicacion.recordId, // Esto deberá cambiarse por el nombre del candidato
      email: '', // etc.
      perfilActivo: 'Mostrar',
      ultimoModificacion: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Aplicacion>>(
        future: _seguimientoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el seguimiento: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Aún no tienes candidatos en seguimiento.\nVe a "Mis Vacantes" para revisar nuevos CVs.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final aplicaciones = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadSeguimiento(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: aplicaciones.length,
              itemBuilder: (context, index) {
                final aplicacion = aplicaciones[index];
                // TODO: Reemplazar 'NombreCandidato' y 'TituloVacante' con los
                // campos correctos una vez que actualicemos el modelo Aplicacion.

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.person_search, size: 40),
                    title: Text("Nombre Candidato" /* aplicacion.nombreCandidato */, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Aplicó a: ${"Titulo Vacante" /* aplicacion.tituloVacante */}\nEstado: ${aplicacion.estadoAplicacion}"),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // final candidato = _candidatoFromAplicacion(aplicacion);
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => DetalleCandidatoReclutadorScreen(candidato: candidato),
                      //   ),
                      // );
                    },
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