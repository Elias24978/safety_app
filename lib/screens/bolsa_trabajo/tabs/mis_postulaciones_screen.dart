import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/models/aplicacion_model.dart';
import 'package:safety_app/services/airtable_service.dart';

class MisPostulacionesScreen extends StatefulWidget {
  const MisPostulacionesScreen({super.key});

  @override
  State<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends State<MisPostulacionesScreen> {
  final AirtableService _airtableService = AirtableService();
  late Future<List<Aplicacion>> _postulacionesFuture;

  @override
  void initState() {
    super.initState();
    _loadPostulaciones();
  }

  // ✅ NUEVO: Lógica de carga separada para poder reutilizarla.
  void _loadPostulaciones() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _postulacionesFuture = _airtableService.getMisPostulaciones(userId);
      });
    } else {
      // Si no hay usuario, preparamos un futuro que devuelve una lista vacía.
      setState(() {
        _postulacionesFuture = Future.value([]);
      });
    }
  }

  // ✅ NUEVO: Un helper para dar color a los chips de estado.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'contactado':
        return Colors.green.shade100;
      case 'en revisión':
        return Colors.orange.shade100;
      case 'rechazada':
        return Colors.red.shade100;
      case 'recibida':
      default:
        return Colors.blue.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CAMBIO: Se elimina el Scaffold.
    return FutureBuilder<List<Aplicacion>>(
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
                'Aún no te has postulado a ninguna vacante.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        final postulaciones = snapshot.data!;
        // ✅ MEJORA: Se añade un RefreshIndicator para actualizar la lista.
        return RefreshIndicator(
          onRefresh: () async => _loadPostulaciones(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0), // Añade un poco de padding
            itemCount: postulaciones.length,
            itemBuilder: (context, index) {
              final aplicacion = postulaciones[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(aplicacion.tituloVacante, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(aplicacion.nombreEmpresa),
                  trailing: Chip(
                    label: Text(
                      aplicacion.estado,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: _getStatusColor(aplicacion.estado),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}