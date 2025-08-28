// lib/screens/normas_stps_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safety_app/models/category_model.dart';
import 'package:safety_app/services/airtable_service.dart';
import 'package:safety_app/screens/norma_list_screen.dart'; // Importa la pantalla de la lista

class NormasStpsScreen extends StatefulWidget {
  const NormasStpsScreen({super.key});

  @override
  State<NormasStpsScreen> createState() => _NormasStpsScreenState();
}

class _NormasStpsScreenState extends State<NormasStpsScreen> {
  final AirtableService _airtableService = AirtableService();
  late Future<List<Category>> _categoriesFuture;

  // Mapa de íconos para cada categoría (puedes personalizarlos)
  final Map<String, IconData> _categoryIcons = {
    'Seguridad': FontAwesomeIcons.shieldHalved,
    'Salud': FontAwesomeIcons.heartPulse,
    'Organización': FontAwesomeIcons.sitemap,
    'Especificas': FontAwesomeIcons.star,
    'Producto': FontAwesomeIcons.box,
  };

  @override
  void initState() {
    super.initState();
    // Llama al servicio para obtener las categorías cuando la pantalla se inicia
    _categoriesFuture = _airtableService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de Normas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          // Mientras carga, muestra un círculo de progreso
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si hubo un error o no hay datos
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se pudieron cargar las categorías.'));
          }

          // Si todo salió bien, construye el menú
          final categories = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final icon = _categoryIcons[category.title] ?? FontAwesomeIcons.circleQuestion;

              return InkWell(
                onTap: () {
                  // Navega a la pantalla de la lista, pasando el nombre de la categoría
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NormaListScreen(categoryName: category.title),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(icon, size: 40, color: Colors.deepPurple),
                      const SizedBox(height: 12),
                      Text(
                        category.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}