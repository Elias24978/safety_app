// lib/screens/bolsa_trabajo/bolsa_trabajo_screen.dart
import 'package:flutter/material.dart';
import '../../models/vacante_model.dart';
import '../../services/airtable_service.dart';

class BolsaTrabajoScreen extends StatefulWidget {
  const BolsaTrabajoScreen({super.key});

  @override
  State<BolsaTrabajoScreen> createState() => _BolsaTrabajoScreenState();
}

class _BolsaTrabajoScreenState extends State<BolsaTrabajoScreen> {
  final AirtableService _airtableService = AirtableService();
  late Future<List<Vacante>> _vacantesFuture;

  @override
  void initState() {
    super.initState();
    _vacantesFuture = _airtableService.getVisibleVacantes();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CAMBIO: Se elimina el Scaffold y el AppBar. Se devuelve directamente el FutureBuilder.
    return FutureBuilder<List<Vacante>>(
      future: _vacantesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar las vacantes: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay vacantes disponibles por el momento.'));
        }

        final vacantes = snapshot.data!;
        return ListView.builder(
          itemCount: vacantes.length,
          itemBuilder: (context, index) {
            final vacante = vacantes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                title: Text(vacante.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vacante.nombreEmpresa, style: TextStyle(color: Colors.grey[800])),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(vacante.ubicacion),
                        ],
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  print('Tocado: ${vacante.titulo}');
                },
              ),
            );
          },
        );
      },
    );
  }
}