import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:safety_app/models/vacante_model.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/models/aplicacion_model.dart';

// Modelos existentes
import 'package:safety_app/models/category_model.dart';
import 'package:safety_app/models/norma_model.dart';
import 'package:safety_app/models/formato_category_model.dart';
import 'package:safety_app/models/formato_model.dart';

class AirtableService {
  final String _apiKey = dotenv.env['AIRTABLE_API_KEY']!;
  final String _baseIdNormas = dotenv.env['AIRTABLE_BASE_ID_NORMAS']!;
  final String _baseIdFormatos = dotenv.env['AIRTABLE_BASE_ID_FORMATOS']!;
  final String _baseIdBolsa = dotenv.env['AIRTABLE_BASE_ID_BOLSA']!;

  Uri _buildUri(String baseId, String tableName, {String? filterByFormula, String? sortField, String? sortDirection}) {
    var queryParameters = <String, String>{};
    if (filterByFormula != null) {
      queryParameters['filterByFormula'] = filterByFormula;
    }
    if (sortField != null) {
      queryParameters['sort[0][field]'] = sortField;
      queryParameters['sort[0][direction]'] = sortDirection ?? 'asc';
    }
    return Uri.parse('https://api.airtable.com/v0/$baseId/$tableName').replace(queryParameters: queryParameters);
  }

  Map<String, String> get _headers => {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'};

  // --- MÉTODOS PARA NORMAS ---
  // (Tu código existente para Normas y Formatos permanece igual)
  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdNormas/category');
    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Category.fromJson(record)).toList();
      }
      debugPrint('Error de Airtable (Categories): ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error al obtener categorías: $e');
      return [];
    }
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
      debugPrint('Error de Airtable (Normas - $categoryTableName): ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error al obtener normas para $categoryTableName: $e');
      return [];
    }
  }

  // --- MÉTODOS PARA FORMATOS ---
  Future<List<FormatoCategory>> fetchFormatoCategories() async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdFormatos/Indice');
    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_apiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => FormatoCategory.fromJson(record)).toList();
      }
      debugPrint('Error de Airtable (FormatoCategories): ${response.statusCode} - Body: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error al obtener categorías de formatos: $e');
      return [];
    }
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
      debugPrint('Error de Airtable (Formatos - $formatoTableName): ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error al obtener formatos para $formatoTableName: $e');
      return [];
    }
  }

  // =============================================================
  // MÉTODOS PARA BOLSA DE TRABAJO
  // =============================================================

  /// Obtiene todas las vacantes que están marcadas como "Visibles".
  Future<List<Vacante>> getVisibleVacantes() async {
    final uri = _buildUri(_baseIdBolsa, 'Vacantes', filterByFormula: "{Visibilidad_Oferta} = 'Visible'", sortField: 'Fecha_Publicacion', sortDirection: 'desc');
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Vacante.fromAirtable(record)).toList();
      }
      debugPrint('Error de Airtable (getVisibleVacantes): ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error en getVisibleVacantes: $e');
      return [];
    }
  }

  /// Crea una nueva vacante.
  Future<bool> createVacante(Map<String, dynamic> fields) async {
    final uri = _buildUri(_baseIdBolsa, 'Vacantes');
    final body = json.encode({'records': [{'fields': fields}]});
    try {
      final response = await http.post(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en createVacante: $e');
      return false;
    }
  }

  /// Archiva una vacante (borrado suave).
  Future<bool> archiveVacante(String recordId) async {
    final uri = _buildUri(_baseIdBolsa, 'Vacantes');
    final body = json.encode({'records': [{'id': recordId, 'fields': {'Visibilidad_Oferta': 'Eliminada'}}]});
    try {
      final response = await http.patch(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en archiveVacante: $e');
      return false;
    }
  }

  /// Busca el perfil de un candidato usando su UserID de Firebase.
  Future<Candidato?> getCandidatoProfile(String userId) async {
    final uri = _buildUri(_baseIdBolsa, 'Candidatos', filterByFormula: "{UserID} = '$userId'");
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        if (records.isNotEmpty) {
          return Candidato.fromAirtable(records.first);
        }
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('Error en getCandidatoProfile: $e');
      return null;
    }
  }

  /// Crea un nuevo perfil de candidato.
  Future<bool> createCandidatoProfile(Map<String, dynamic> fields) async {
    final uri = _buildUri(_baseIdBolsa, 'Candidatos');
    final body = json.encode({'records': [{'fields': fields}]});
    try {
      final response = await http.post(uri, headers: _headers, body: body);
      if (response.statusCode == 200) {
        debugPrint('Perfil de candidato creado exitosamente.');
        return true;
      }
      debugPrint('Error al crear perfil de candidato: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error en createCandidatoProfile: $e');
      return false;
    }
  }

  /// Obtiene todas las postulaciones de un usuario específico.
  Future<List<Aplicacion>> getMisPostulaciones(String userId) async {
    final uri = _buildUri(_baseIdBolsa, 'Aplicaciones', filterByFormula: "{UserID_Candidato} = '$userId'");
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Aplicacion.fromAirtable(record)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error en getMisPostulaciones: $e');
      return [];
    }
  }

  /// ✅ NUEVO: Actualiza un perfil de candidato existente usando su Record ID.
  Future<bool> updateCandidatoProfile(String recordId, Map<String, dynamic> fields) async {
    final uri = _buildUri(_baseIdBolsa, 'Candidatos');
    final body = json.encode({
      'records': [{'id': recordId, 'fields': fields}]
    });
    try {
      final response = await http.patch(uri, headers: _headers, body: body);
      if (response.statusCode == 200) {
        debugPrint('Perfil de candidato actualizado exitosamente.');
        return true;
      }
      debugPrint('Error al actualizar perfil: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error en updateCandidatoProfile: $e');
      return false;
    }
  }

  /// ✅ NUEVO: Elimina un perfil de candidato de Airtable.
  Future<bool> deleteCandidatoProfile(String recordId) async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdBolsa/Candidatos?records[]=$recordId');
    try {
      final response = await http.delete(uri, headers: _headers);
      if (response.statusCode == 200) {
        debugPrint('Perfil de candidato eliminado exitosamente.');
        return true;
      }
      debugPrint('Error al eliminar perfil: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error en deleteCandidatoProfile: $e');
      return false;
    }
  }
}