// lib/services/airtable_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Modelos
import 'package:safety_app/models/category_model.dart';
import 'package:safety_app/models/norma_model.dart';
import 'package:safety_app/models/formato_category_model.dart';
import 'package:safety_app/models/formato_model.dart';

class AirtableService {
  // La API Key es la misma para ambas bases
  final String _apiKey = dotenv.env['AIRTABLE_API_KEY']!;

  // --- 👇 1. CARGAMOS AMBOS IDs DE LAS BASES DE DATOS ---
  final String _baseIdNormas = dotenv.env['AIRTABLE_BASE_ID_NORMAS']!;
  final String _baseIdFormatos = dotenv.env['AIRTABLE_BASE_ID_FORMATOS']!;

  // --- MÉTODOS PARA NORMAS (USAN EL ID DE NORMAS) ---

  /// Obtiene la lista de categorías desde la tabla 'category'.
  Future<List<Category>> fetchCategories() async {
    // --- 👇 2. USA EL ID ESPECÍFICO DE NORMAS ---
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdNormas/category');

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
    // --- 👇 2. USA EL ID ESPECÍFICO DE NORMAS ---
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdNormas/$categoryTableName');
    try {
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

  // --- MÉTODOS PARA FORMATOS (USAN EL ID DE FORMATOS) ---

  /// Obtiene la lista de categorías de formatos desde la tabla 'FormatoCategorias'.
  Future<List<FormatoCategory>> fetchFormatoCategories() async {
    // --- 👇 3. USA EL ID ESPECÍFICO DE FORMATOS ---
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdFormatos/FormatoCategorias');

    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => FormatoCategory.fromJson(record)).toList();
      }
      print('Error de Airtable (FormatoCategories): ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error al obtener categorías de formatos: $e');
      return [];
    }
  }

  /// Obtiene la lista de formatos de una tabla específica.
  Future<List<Formato>> fetchFormatosForTable(String formatoTableName) async {
    // --- 👇 3. USA EL ID ESPECÍFICO DE FORMATOS ---
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdFormatos/$formatoTableName');

    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Formato.fromJson(record)).toList();
      }
      print('Error de Airtable (Formatos - $formatoTableName): ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error al obtener formatos para $formatoTableName: $e');
      return [];
    }
  }
}