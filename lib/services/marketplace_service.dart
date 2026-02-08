import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/services/purchase_service.dart';

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
      }
      return [];
    } catch (e) {
      print('❌ Excepción fetchCursos: $e');
      return [];
    }
  }

  // 2. VERIFICAR COMPRA Y ESTADO (Lectura)
  Future<Curso> enriquecerCursoConEstado(Curso cursoPublico) async {
    User? user = _auth.currentUser;

    List<Modulo>? temarioReal = await _obtenerTemarioFirestore(cursoPublico.id);
    List<Modulo> temarioBase = temarioReal ?? cursoPublico.temario ?? _getTemarioDemo();

    if (user == null) {
      return cursoPublico.copyWithPrivateData(
          temario: _limpiarUrlsParaPreview(temarioBase),
          comprado: false,
          completado: false
      );
    }

    try {
      // A. Buscamos compra ACTIVA en Firestore
      // Requiere índice compuesto en Firestore: usuario_uid ASC, curso_id ASC, status ASC, fecha_compra DESC
      final activeQuery = await _firestore.collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoPublico.id)
          .where('status', isEqualTo: 'pagado')
          .orderBy('fecha_compra', descending: true)
          .limit(1)
          .get();

      if (activeQuery.docs.isNotEmpty) {
        // ✅ TIENE EL CURSO ABIERTO
        return cursoPublico.copyWithPrivateData(
            temario: temarioReal, // Acceso total
            comprado: true,
            completado: false
        );
      }

      // B. Buscamos compra FINALIZADA en Firestore
      final completedQuery = await _firestore.collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoPublico.id)
          .where('status', isEqualTo: 'certificado_emitido')
          .orderBy('fecha_compra', descending: true)
          .limit(1)
          .get();

      if (completedQuery.docs.isNotEmpty) {
        // 🎓 CURSO TERMINADO -> SE MUESTRA COMO NO COMPRADO PARA RE-CERTIFICAR
        return cursoPublico.copyWithPrivateData(
            temario: _limpiarUrlsParaPreview(temarioBase), // Bloqueado
            comprado: false, // Botón de comprar activo
            completado: true // Badge de completado
        );
      }

      // C. Verificación de Entitlement (Respaldo para Suscripciones/Lifetime)
      // Solo si es un entitlement REAL activo en RevenueCat.
      // Para consumibles simples, esto suele ser false.
      bool tieneEntitlement = await PurchaseService().checkCourseAccess(cursoPublico.id);
      if (tieneEntitlement) {
        // Si tiene entitlement pero no documento local, intentamos registrarlo
        // (Esto es raro en consumibles, pero útil para suscripciones)
        await _registrarCompraNuevaInterna(user.uid, cursoPublico.id);
        return cursoPublico.copyWithPrivateData(
            temario: temarioReal,
            comprado: true,
            completado: false
        );
      }

      // D. Sin acceso
      return cursoPublico.copyWithPrivateData(
          temario: _limpiarUrlsParaPreview(temarioBase),
          comprado: false,
          completado: false
      );

    } catch (e) {
      print('⚠️ [Marketplace] Error verificando: $e');
      return cursoPublico.copyWithPrivateData(
          temario: _limpiarUrlsParaPreview(temarioBase),
          comprado: false,
          completado: false
      );
    }
  }

  // ✅ MÉTODO FALTANTE: Registro explícito de compra nueva
  // Se llama desde la UI (DetalleCursoScreen) al completar el pago exitosamente.
  Future<void> registrarCompraNueva(String cursoId) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    await _registrarCompraNuevaInterna(user.uid, cursoId);
  }

  Future<void> _registrarCompraNuevaInterna(String uid, String cursoId) async {
    try {
      // Verificamos si YA hay uno activo para no duplicar por error
      final activeQuery = await _firestore.collection('compras')
          .where('usuario_uid', isEqualTo: uid)
          .where('curso_id', isEqualTo: cursoId)
          .where('status', isEqualTo: 'pagado')
          .limit(1)
          .get();

      if (activeQuery.docs.isEmpty) {
        print("✨ [Marketplace] Creando nuevo registro de acceso para $cursoId");
        await _firestore.collection('compras').add({
          'usuario_uid': uid,
          'curso_id': cursoId,
          'fecha_compra': FieldValue.serverTimestamp(),
          'status': 'pagado',
          'metodo': 'store_purchase',
          'progreso_lecciones': []
        });
      } else {
        print("ℹ️ [Marketplace] Ya existe un registro activo para $cursoId, omitiendo creación.");
      }
    } catch (e) {
      print("❌ Error registrando compra en Firestore: $e");
    }
  }

  // --- Helpers y métodos legacy ---

  Future<List<Modulo>?> _obtenerTemarioFirestore(String cursoId) async {
    try {
      final doc = await _firestore.collection('cursos').doc(cursoId).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('temario')) {
        List<dynamic> jsonList = doc.data()!['temario'];
        return jsonList.map((m) => Modulo.fromJson(m)).toList();
      }
    } catch (_) {}
    return null;
  }

  List<Modulo> _limpiarUrlsParaPreview(List<Modulo> original) {
    return original.map((m) {
      return Modulo(
          titulo: m.titulo,
          lecciones: m.lecciones.map((l) => Leccion(
              titulo: l.titulo,
              tipo: l.tipo,
              url: "", // URL BORRADA
              duracionMinutos: l.duracionMinutos,
              preguntas: null
          )).toList()
      );
    }).toList();
  }

  Future<bool> simularCompra(String cursoId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    // Redirige al nuevo método unificado
    await _registrarCompraNuevaInterna(user.uid, cursoId);
    return true;
  }

  Future<void> guardarProgresoLeccion(String cursoId, String leccionId) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    try {
      final query = await _firestore.collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoId)
          .where('status', isEqualTo: 'pagado')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'progreso_lecciones': FieldValue.arrayUnion([leccionId])
        });
      }
    } catch (_) {}
  }

  Future<List<String>> obtenerProgreso(String cursoId) async {
    User? user = _auth.currentUser;
    if (user == null) return [];
    try {
      final query = await _firestore.collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoId)
          .where('status', isEqualTo: 'pagado')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return List<String>.from(query.docs.first.data()['progreso_lecciones'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  Future<bool> marcarCursoComoCompletado(String cursoId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    try {
      // Buscamos el documento ACTIVO para cerrarlo
      final querySnapshot = await _firestore
          .collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoId)
          .where('status', isEqualTo: 'pagado')
          .orderBy('fecha_compra', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _firestore.collection('compras').doc(docId).update({
          'status': 'certificado_emitido', // 🔒 Cierra el ciclo
          'fecha_certificacion': FieldValue.serverTimestamp(),
        });
        print("🎉 Curso $cursoId finalizado y cerrado correctamente.");
        return true;
      }
      return false;
    } catch (e) {
      print("⚠️ Error al finalizar curso: $e");
      return false;
    }
  }

  List<Modulo> _getTemarioDemo() {
    return [Modulo(titulo: "Contenido no disponible temporalmente", lecciones: [])];
  }
}