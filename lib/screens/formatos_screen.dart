// lib/screens/formatos_screen.dart

import 'package:flutter/material.dart';
import 'package:safety_app/models/formato_category_model.dart';
import 'package:safety_app/models/formato_model.dart';
import 'package:safety_app/services/airtable_service.dart';
import 'package:safety_app/screens/pdf_viewer_screen.dart'; // <-- Se importa el visor

// --- Widget de la Tarjeta de Formato (ACTUALIZADO) ---
class FormatoCard extends StatelessWidget {
  final Formato formato;

  const FormatoCard({super.key, required this.formato});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 👇 CAMBIO PARA REDUCIR TAMAÑO DE VISTA PREVIA ---
          if (formato.previewUrl != null)
            Image.network(
              formato.previewUrl!,
              height: 120, // <-- Se redujo la altura de 150 a 120
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(height: 120, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
              },
              errorBuilder: (context, error, stackTrace) => Container(height: 120, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, color: Colors.white))),
            )
          else
            Container(height: 120, color: Colors.grey[300], child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey))),
          // --- FIN DEL CAMBIO ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formato.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(formato.description, style: TextStyle(fontSize: 14, color: Colors.grey[700]), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widget que muestra la lista de formatos (ACTUALIZADO) ---
class FormatoList extends StatefulWidget {
  final String categoryTableName;

  const FormatoList({super.key, required this.categoryTableName});

  @override
  State<FormatoList> createState() => _FormatoListState();
}

class _FormatoListState extends State<FormatoList> {
  late Future<List<Formato>> _formatosFuture;
  final AirtableService _airtableService = AirtableService();

  @override
  void initState() {
    super.initState();
    _formatosFuture = _airtableService.fetchFormatosForTable(widget.categoryTableName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Formato>>(
      future: _formatosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar formatos: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay formatos disponibles en esta categoría.'));
        }

        final formatos = snapshot.data!;
        return ListView.builder(
          itemCount: formatos.length,
          itemBuilder: (context, index) {
            final formato = formatos[index];
            // --- 👇 CAMBIO PARA AÑADIR NAVEGACIÓN ---
            return InkWell(
              onTap: () {
                if (formato.fileUrl != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(
                        fileUrl: formato.fileUrl!,
                        normaName: formato.title,
                      ),
                    ),
                  );
                }
              },
              child: FormatoCard(formato: formato),
            );
            // --- FIN DEL CAMBIO ---
          },
        );
      },
    );
  }
}

// --- Pantalla principal con las pestañas (Sin cambios) ---
class FormatosScreen extends StatefulWidget {
  const FormatosScreen({super.key});

  @override
  State<FormatosScreen> createState() => _FormatosScreenState();
}

class _FormatosScreenState extends State<FormatosScreen> {
  late Future<List<FormatoCategory>> _categoriesFuture;
  final AirtableService _airtableService = AirtableService();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _airtableService.fetchFormatoCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formatos'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white,),
      body: FutureBuilder<List<FormatoCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudieron cargar las categorías.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay categorías de formatos.'));
          }

          final categories = snapshot.data!;
          return DefaultTabController(
            length: categories.length,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    isScrollable: true,
                    indicatorColor: Colors.deepPurple,
                    labelColor: Colors.deepPurple,
                    unselectedLabelColor: Colors.grey,
                    tabs: categories.map((cat) => Tab(text: cat.title)).toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: categories.map((cat) => FormatoList(categoryTableName: cat.tableName)).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}