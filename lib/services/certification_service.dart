import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class CertificationService {
  Future<bool> requestCertificate({
    required String studentName,
    required String curp,
    required String courseName,
    required String courseDuration,
    required String instructorName,
    required String instructorStps,
    required String folio,
    required String instructorEmail,
    required String adminEmail,
    required String occupation,
    required String jobPosition,
    required String studentEmail,
  }) async {

    // Empaquetamos los datos exactos que espera nuestro nuevo servidor
    final Map<String, dynamic> payload = {
      'nombre': studentName,
      'curp': curp,
      'curso': courseName,
      'duracion': courseDuration,
      'instructor': instructorName,
      'registro_stps': instructorStps,
      'folio': folio,
      'email_instructor': instructorEmail,
      'email_admin': adminEmail,
      'email_alumno': studentEmail,
      'ocupacion': occupation,
      'puesto': jobPosition,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      debugPrint('🚀 Llamando a Firebase Cloud Functions (generarDC3) para folio: $folio');

      // 1. Llamamos a la función segura que acabamos de subir a la nube
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('generarDC3');

      // 2. Le enviamos los datos. Firebase inyectará automáticamente los secretos y hablará con Apps Script.
      final result = await callable.call(payload);

      // 3. Revisamos si Firebase nos contestó con un "success: true"
      if (result.data['success'] == true) {
        return true;
      }
      return false;

    } on FirebaseFunctionsException catch (e) {
      // Este error viene directo desde nuestro servidor Node.js
      debugPrint('❌ Error de Firebase: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Fallo de seguridad o error interno en el servidor.');
    } catch (e) {
      // Error local (ej. el celular no tiene internet)
      debugPrint('❌ Error local: $e');
      throw Exception('Comprueba tu conexión a internet e intenta de nuevo.');
    }
  }
}