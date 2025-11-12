import 'package:flutter/material.dart';
import 'package:safety_app/models/norma_model.dart';
import 'package:safety_app/services/airtable_service.dart';
import 'package:safety_app/screens/pdf_viewer_screen.dart'; // <-- 1. IMPORTA LA NUEVA PANTALLA

class NormaListScreen extends StatefulWidget {
  final String categoryName;

  const NormaListScreen({super.key, required this.categoryName});

  @override
  State<NormaListScreen> createState() => _NormaListScreenState();
}

class _NormaListScreenState extends State<NormaListScreen> {
  final AirtableService _airtableService = AirtableService();
  late Future<List<Norma>> _normasFuture;

  @override
  void initState() {
    super.initState();
    _normasFuture = _airtableService.fetchNormasForCategory(widget.categoryName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Norma>>(
        future: _normasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron normas para esta categoría.'));
          }

          final normas = snapshot.data!;
          return ListView.builder(
            itemCount: normas.length,
            itemBuilder: (context, index) {
              final norma = normas[index];
              return ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.deepPurple),
                title: Text(norma.name),
                trailing: norma.fileUrl != null ? const Icon(Icons.picture_as_pdf_outlined) : null,
                onTap: () {
                  if (norma.fileUrl != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(
                          fileUrl: norma.fileUrl!,
                          // ✅ CAMBIO: Se corrigió 'normaName' a 'fileName'
                          fileName: norma.name,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}