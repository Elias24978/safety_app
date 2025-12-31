import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/models/curso_model.dart';

class MarketplaceService {
  // --- CREDENCIALES ---
  final String _airtableBaseId = 'appWO4nUwEv4OBWGP';
  final String _airtableTableName = 'tblcdqjYQhvJWkICr';
  final String _airtableApiKey = 'pat3YqMlmuiIQOhgi.1b3145f5af57d8d4926e94226e26d1dcf5859eab7765e733d5a2f8777eca503b';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. OBTENER VITRINA (AIRTABLE)
  Future<List<Curso>> fetchCursosPublicos() async {
    final url = Uri.parse(
        'https://api.airtable.com/v0/$_airtableBaseId/$_airtableTableName?filterByFormula={Estado}="Publicado"'
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_airtableApiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> records = data['records'];
        return records.map((json) => Curso.fromAirtable(json)).toList();
      } else {
        print("❌ Error Airtable (${response.statusCode}): ${response.body}");
        return [];
      }
    } catch (e) {
      print('❌ Excepción en fetchCursosPublicos: $e');
      return [];
    }
  }

  // 2. VERIFICAR COMPRA Y CARGAR ESTRUCTURA REAL
  Future<Curso> enriquecerCursoConEstado(Curso cursoPublico) async {
    User? user = _auth.currentUser;
    // Descargamos la estructura REAL de Firestore (para mostrar el temario correcto)
    List<Modulo>? temarioReal = await _obtenerTemarioFirestore(cursoPublico.id);

    if (user == null) {
      // Si no hay usuario, devolvemos el temario real pero bloqueado (sin URLs)
      return cursoPublico.copyWithPrivateData(
          temario: _limpiarUrlsParaPreview(temarioReal),
          comprado: false,
          completado: false
      );
    }

    try {
      // PASO 1: Buscar compra ACTIVA ('pagado')
      final activeQuery = await _firestore
          .collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoPublico.id)
          .where('status', isEqualTo: 'pagado')
          .limit(1)
          .get();

      if (activeQuery.docs.isNotEmpty) {
        // ✅ TIENE SALDO: Devolvemos el temario COMPLETO (con URLs)
        return cursoPublico.copyWithPrivateData(
            temario: temarioReal ?? _getTemarioDemo(), // Si falló Firestore, usa demo
            comprado: true,
            completado: false
        );
      }

      // PASO 2: Buscar si ya lo completó antes ('certificado_emitido')
      final completedQuery = await _firestore
          .collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoPublico.id)
          .where('status', isEqualTo: 'certificado_emitido')
          .limit(1)
          .get();

      if (completedQuery.docs.isNotEmpty) {
        // 🔒 YA SE CERTIFICÓ: Mostramos temario pero bloqueamos acceso (sin URLs)
        // Esto obliga a recomprar para volver a certificar.
        return cursoPublico.copyWithPrivateData(
            temario: _limpiarUrlsParaPreview(temarioReal),
            comprado: false,
            completado: true
        );
      }

      // NO COMPRADO: Mostramos temario real (para antojar) pero sin URLs
      return cursoPublico.copyWithPrivateData(
          temario: _limpiarUrlsParaPreview(temarioReal),
          comprado: false,
          completado: false
      );

    } catch (e) {
      print('⚠️ Error verificando compra: $e.');
      return cursoPublico;
    }
  }

  // Helper para obtener datos de Firestore
  Future<List<Modulo>?> _obtenerTemarioFirestore(String cursoId) async {
    try {
      final doc = await _firestore.collection('cursos').doc(cursoId).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('temario')) {
        List<dynamic> jsonList = doc.data()!['temario'];
        return jsonList.map((m) => Modulo.fromJson(m)).toList();
      }
    } catch (e) {
      print("Error leyendo Firestore: $e");
    }
    return null;
  }

  // Helper de Seguridad: Borra los URLs de video para la vista previa
  List<Modulo>? _limpiarUrlsParaPreview(List<Modulo>? original) {
    if (original == null) return null;
    return original.map((m) {
      return Modulo(
          titulo: m.titulo,
          lecciones: m.lecciones.map((l) => Leccion(
              titulo: l.titulo,
              tipo: l.tipo,
              url: "", // 🔒 URL BORRADA: Seguridad para no robar contenido
              duracionMinutos: l.duracionMinutos,
              preguntas: null // 🔒 PREGUNTAS BORRADAS
          )).toList()
      );
    }).toList();
  }

  // 4. REGISTRAR COMPRA
  Future<bool> simularCompra(String cursoId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('compras').add({
        'usuario_uid': user.uid,
        'curso_id': cursoId,
        'fecha_compra': FieldValue.serverTimestamp(),
        'status': 'pagado',
        'metodo': 'simulacion_dev',
        'progreso_lecciones': []
      });
      return true;
    } catch (e) {
      print("❌ Error al registrar compra: $e");
      return false;
    }
  }

  // 5. GUARDAR PROGRESO
  Future<void> guardarProgresoLeccion(String cursoId, String leccionId) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    try {
      final querySnapshot = await _firestore
          .collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoId)
          .where('status', isEqualTo: 'pagado')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        await docRef.update({
          'progreso_lecciones': FieldValue.arrayUnion([leccionId])
        });
      }
    } catch (e) {
      print("Error guardando progreso: $e");
    }
  }

  // 6. OBTENER PROGRESO
  Future<List<String>> obtenerProgreso(String cursoId) async {
    User? user = _auth.currentUser;
    if (user == null) return [];
    try {
      final querySnapshot = await _firestore
          .collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoId)
          .where('status', isEqualTo: 'pagado')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return List<String>.from(data['progreso_lecciones'] ?? []);
      }
    } catch (e) { print(e); }
    return [];
  }

  // 7. FINALIZAR CURSO (QUEMAR CARTUCHO)
  Future<bool> marcarCursoComoCompletado(String cursoId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Seguridad: Solo permite finalizar si hay una compra ACTIVA ('pagado')
      final querySnapshot = await _firestore
          .collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoId)
          .where('status', isEqualTo: 'pagado')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _firestore.collection('compras').doc(docId).update({
          'status': 'certificado_emitido', // 🔒 Cierra el ciclo
          'fecha_certificacion': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false; // Ya fue usado o no existe
    } catch (e) {
      print("⚠️ Error al finalizar curso: $e");
      return false;
    }
  }

  List<Modulo> _getTemarioDemo() {
    return [Modulo(titulo: "Cargando temario...", lecciones: [])];
  }
}