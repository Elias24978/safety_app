import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:safety_app/models/category_model.dart';
import 'package:safety_app/models/norma_model.dart';
import 'package:safety_app/models/formato_category_model.dart';
import 'package:safety_app/models/formato_model.dart';

class AirtableService {
  final String _apiKey = dotenv.env['AIRTABLE_API_KEY']!;
  final String _baseIdNormas = dotenv.env['AIRTABLE_BASE_ID_NORMAS']!;
  final String _baseIdFormatos = dotenv.env['AIRTABLE_BASE_ID_FORMATOS']!;

  // ✅ ELIMINADOS: Los métodos _buildUri y _headers ya no son necesarios en esta clase.

  // --- MÉTODOS DE NORMAS Y FORMATOS ---
  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdNormas/category');
    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Category.fromJson(record)).toList();
      }
    } catch (e) {
      debugPrint('Error al obtener categorías: $e');
    }
    return [];
  }

  Future<List<Norma>> fetchNormasForCategory(String categoryTableName) async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdNormas/$categoryTableName');
    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Norma.fromJson(record)).toList();
      }
    } catch (e) {
      debugPrint('Error al obtener normas para $categoryTableName: $e');
    }
    return [];
  }

  Future<List<FormatoCategory>> fetchFormatoCategories() async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdFormatos/Indice');
    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => FormatoCategory.fromJson(record)).toList();
      }
    } catch (e) {
      debugPrint('Error al obtener categorías de formatos: $e');
    }
    return [];
  }

  Future<List<Formato>> fetchFormatosForTable(String formatoTableName) async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdFormatos/$formatoTableName');
    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Formato.fromJson(record)).toList();
      }
    } catch (e) {
      debugPrint('Error al obtener formatos para $formatoTableName: $e');
    }
    return [];
  }
}