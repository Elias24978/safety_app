// lib/services/airtable_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:safety_app/models/category_model.dart';
import 'package:safety_app/models/norma_model.dart';

class AirtableService {
  final String _apiKey = dotenv.env['AIRTABLE_API_KEY']!;
  final String _baseId = dotenv.env['AIRTABLE_BASE_ID']!;

  /// Obtiene la lista de categorías desde la tabla 'category'.
  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseId/category');


    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Category.fromJson(record)).toList();
      }
      print('Error de Airtable (Categories): ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }

  /// Obtiene la lista de normas para una categoría específica.
  Future<List<Norma>> fetchNormasForCategory(String categoryTableName) async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseId/$categoryTableName');
    try {
      // También añadimos la depuración aquí por si acaso.
     final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Norma.fromJson(record)).toList();
      }
      print('Error de Airtable (Normas - $categoryTableName): ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error al obtener normas para $categoryTableName: $e');
      return [];
    }
  }
}