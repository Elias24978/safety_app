import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:safety_app/models/vacante_model.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/models/aplicacion_model.dart';
import 'package:safety_app/models/empresa_model.dart';

class BolsaTrabajoService {
  final String _apiKey = dotenv.env['AIRTABLE_API_KEY']!;
  final String _baseIdBolsa = dotenv.env['AIRTABLE_BASE_ID_BOLSA']!;

  Uri _buildUri(String tableName, {String? filterByFormula, String? sortField, String? sortDirection}) {
    var queryParameters = <String, String>{};
    if (filterByFormula != null) {
      queryParameters['filterByFormula'] = filterByFormula;
    }
    if (sortField != null) {
      queryParameters['sort[0][field]'] = sortField;
      queryParameters['sort[0][direction]'] = sortDirection ?? 'asc';
    }
    return Uri.parse('https://api.airtable.com/v0/$_baseIdBolsa/$tableName').replace(queryParameters: queryParameters);
  }

  Map<String, String> get _headers => {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'};

  // --- Métodos de Perfiles (Candidato y Empresa) ---
  Future<Candidato?> getCandidatoProfile(String userId) async {
    final uri = _buildUri('Candidatos', filterByFormula: "{UserID} = '$userId'");
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        if (records.isNotEmpty) {
          return Candidato.fromAirtable(records.first);
        }
      }
    } catch (e) {
      debugPrint('Error en getCandidatoProfile: $e');
    }
    return null;
  }

  Future<Empresa?> getEmpresaProfile(String userId) async {
    final uri = _buildUri('Empresas', filterByFormula: "{UserID_Creador} = '$userId'");
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        if (records.isNotEmpty) {
          return Empresa.fromAirtable(records.first);
        }
      }
    } catch (e) {
      debugPrint('Error en getEmpresaProfile: $e');
    }
    return null;
  }

  Future<List<Candidato>> getVisibleCandidatos() async {
    const formula = "FIND('Mostrar', {Perfil_Activo}) > 0";
    final uri = _buildUri('Candidatos', filterByFormula: formula, sortField: 'ultimo_modificacion', sortDirection: 'desc');
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Candidato.fromAirtable(record)).toList();
      } else {
        debugPrint('Error al obtener candidatos: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en getVisibleCandidatos: $e');
    }
    return [];
  }

  Future<bool> createCandidatoProfile(Map<String, dynamic> fields) async {
    final uri = _buildUri('Candidatos');
    final body = json.encode({'records': [{'fields': fields}]});
    try {
      final response = await http.post(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en createCandidatoProfile: $e');
    }
    return false;
  }

  Future<bool> createEmpresaProfile(Map<String, dynamic> fields) async {
    final uri = _buildUri('Empresas');
    final body = json.encode({'records': [{'fields': fields}]});
    try {
      final response = await http.post(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en createEmpresaProfile: $e');
    }
    return false;
  }

  Future<bool> updateCandidatoProfile(String recordId, Map<String, dynamic> fields) async {
    final uri = _buildUri('Candidatos');
    final body = json.encode({'records': [{'id': recordId, 'fields': fields}]});
    try {
      final response = await http.patch(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en updateCandidatoProfile: $e');
    }
    return false;
  }

  Future<bool> updateEmpresaProfile(String recordId, Map<String, dynamic> fields) async {
    final uri = _buildUri('Empresas');
    final body = json.encode({'records': [{'id': recordId, 'fields': fields}]});
    try {
      final response = await http.patch(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en updateEmpresaProfile: $e');
    }
    return false;
  }

  Future<bool> deleteCandidatoProfile(String recordId) async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdBolsa/Candidatos?records[]=$recordId');
    try {
      final response = await http.delete(uri, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en deleteCandidatoProfile: $e');
    }
    return false;
  }

  // --- Métodos de Vacantes y Aplicaciones ---
  Future<List<Vacante>> getVisibleVacantes() async {
    final uri = _buildUri('Vacantes', filterByFormula: "{Visibilidad_Oferta} = 'Visible'", sortField: 'Ultimo_modificacion', sortDirection: 'desc');
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Vacante.fromAirtable(record)).toList();
      }
    } catch (e) {
      debugPrint('Error en getVisibleVacantes: $e');
    }
    return [];
  }

  Future<List<Vacante>> getMisVacantes(String userId) async {
    final uri = _buildUri('Vacantes', filterByFormula: "{UserID_Reclutador} = '$userId'", sortField: 'Ultimo_modificacion', sortDirection: 'desc');
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Vacante.fromAirtable(record)).toList();
      }
    } catch (e) {
      debugPrint('Error en getMisVacantes: $e');
    }
    return [];
  }

  Future<bool> createVacante(Map<String, dynamic> fields) async {
    final uri = _buildUri('Vacantes');
    final body = json.encode({'records': [{'fields': fields}]});
    try {
      final response = await http.post(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en createVacante: $e');
    }
    return false;
  }

  Future<bool> updateVacante(String recordId, Map<String, dynamic> fields) async {
    final uri = _buildUri('Vacantes');
    final body = json.encode({
      'records': [{'id': recordId, 'fields': fields}]
    });
    try {
      final response = await http.patch(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en updateVacante: $e');
    }
    return false;
  }

  Future<bool> archivarVacante(String recordId) async {
    return updateVacante(recordId, {
      'Visibilidad_Oferta': 'Oculta',
    });
  }

  Future<bool> deleteVacante(String recordId) async {
    final uri = Uri.parse('https://api.airtable.com/v0/$_baseIdBolsa/Vacantes?records[]=$recordId');
    try {
      final response = await http.delete(uri, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en deleteVacante: $e');
    }
    return false;
  }

  Future<List<Aplicacion>> getMisPostulaciones(String userId) async {
    final uri = _buildUri('Aplicaciones', filterByFormula: "{UserID_Candidato} = '$userId'", sortField: 'Fecha_Aplicacion', sortDirection: 'desc');
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Aplicacion.fromAirtable(record)).toList();
      }
    } catch (e) {
      debugPrint('Error en getMisPostulaciones: $e');
    }
    return [];
  }

  Future<List<Aplicacion>> getAplicacionesPorVacante(String vacanteRecordId) async {
    final uri = _buildUri('Aplicaciones', filterByFormula: "{VacanteRecordID} = '$vacanteRecordId'", sortField: 'Fecha_Aplicacion', sortDirection: 'asc');
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Aplicacion.fromAirtable(record)).toList();
      }
    } catch (e) {
      debugPrint('Error en getAplicacionesPorVacante: $e');
    }
    return [];
  }

  // ✅ NUEVO: Obtiene aplicaciones en seguimiento para un reclutador.
  Future<List<Aplicacion>> getAplicacionesEnSeguimiento(String userIdReclutador) async {
    // Esta fórmula filtra por el ID del reclutador y excluye las aplicaciones que aún no se han revisado.
    final formula = "AND({UserID_Reclutador_Lookup} = '$userIdReclutador', {Estado_Aplicacion} != '✓ CV Recibido')";
    final uri = _buildUri('Aplicaciones', filterByFormula: formula, sortField: 'Estado_Aplicacion', sortDirection: 'asc');

    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((record) => Aplicacion.fromAirtable(record)).toList();
      }
    } catch (e) {
      debugPrint('Error en getAplicacionesEnSeguimiento: $e');
    }
    return [];
  }

  Future<bool> checkIfAlreadyApplied(String userId, String vacanteRecordId) async {
    final formula = "AND({UserID_Candidato} = '$userId', {VacanteRecordID} = '$vacanteRecordId')";
    final uri = _buildUri('Aplicaciones', filterByFormula: formula);
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.isNotEmpty;
      }
    } catch (e) {
      debugPrint('Error en checkIfAlreadyApplied: $e');
    }
    return false;
  }

  Future<bool> createAplicacion({required String candidatoRecordId, required String vacanteRecordId}) async {
    final uri = _buildUri('Aplicaciones');
    final body = json.encode({'records': [
      {'fields': {
        'Candidato': [candidatoRecordId],
        'Vacante': [vacanteRecordId],
        'Estado_Aplicacion': '✓ CV Recibido',
      }}
    ]});
    try {
      final response = await http.post(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en createAplicacion: $e');
    }
    return false;
  }
}