import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CertificationService {
  // TODO: Reemplazar con la URL final de tu Webhook de Google Apps Script (lo haremos en el Paso 4)
  static const String _webhookUrl = 'https://script.google.com/macros/s/TU_SCRIPT_ID_AQUI/exec';

  // TODO: Definir el token de seguridad. En producción usar variables de entorno.
  static const String _apiToken = 'SAFETY_APP_SECURE_TOKEN_2024';

  /// Envía una solicitud para generar el certificado DC-3.
  ///
  /// Retorna [true] si la solicitud fue aceptada por el backend (200 OK).
  /// Lanza excepciones si algo falla para que la UI pueda mostrar un SnackBar o alerta.
  Future<bool> requestCertificate({
    required String studentName,
    required String curp,
    required String courseName,
    required String folio, // ID único del examen aprobado
    required String instructorEmail,
    required String adminEmail,
  }) async {

    // 1. Preparar el Payload (Datos a enviar)
    final Map<String, dynamic> data = {
      'nombre': studentName,
      'curp': curp,
      'curso': courseName,
      'folio': folio,
      'email_instructor': instructorEmail,
      'email_admin': adminEmail,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      debugPrint('🚀 [CertificationService] Iniciando solicitud DC-3 para Folio: $folio');

      // 2. Realizar la petición POST
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiToken', // Header de seguridad crítico
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30)); // Damos 30s de margen por si el Script está "dormido"

      // 3. Analizar la respuesta
      debugPrint('📨 [CertificationService] Código de respuesta: ${response.statusCode}');
      debugPrint('📄 [CertificationService] Cuerpo: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Éxito: El webhook recibió los datos
        // Opcional: Verificar si el body trae un "status": "success"
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('⛔ Acceso denegado: Token de seguridad inválido.');
      } else if (response.statusCode >= 500) {
        throw Exception('🔥 Error del servidor (Google): Intenta más tarde.');
      } else {
        throw Exception('⚠️ Error desconocido: ${response.statusCode}');
      }

    } on SocketException {
      debugPrint('❌ [CertificationService] Sin conexión a internet.');
      throw Exception('No hay conexión a internet. Verifica tu red.');
    } on http.ClientException catch (e) {
      debugPrint('❌ [CertificationService] Error de cliente HTTP: $e');
      throw Exception('Error de comunicación con el servidor.');
    } catch (e) {
      debugPrint('❌ [CertificationService] Excepción no controlada: $e');
      rethrow;
    }
  }
}