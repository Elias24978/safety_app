import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/curso_model.dart';

class MarketplaceService {
  // --- CONFIGURACIÓN CORREGIDA ---
  // Extraído de tu log de error:
  final String _airtableBaseId = 'appWO4nUwEv4OBWGP';
  final String _airtableTableName = 'tblcdqjYQhvJWkICr'; // Usamos el ID de la tabla, es más robusto
  final String _airtableApiKey = 'pat3YqMlmuiIQOhgi.1b3145f5af57d8d4926e94226e26d1dcf5859eab7765e733d5a2f8777eca503b';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. OBTENER VITRINA (AIRTABLE)
  Future<List<Curso>> fetchCursosPublicos() async {
    // Construcción correcta de la URL para la API
    // Quitamos el filtro de 'view' por ahora para reducir errores, mantenemos el filtro de Estado
    // Asegúrate de que en Airtable tengas una columna llamada "Estado" con valor "Publicado"
    final url = Uri.parse(
        'https://api.airtable.com/v0/$_airtableBaseId/$_airtableTableName?filterByFormula={Estado}="Publicado"'
    );

    print("📡 Conectando a Airtable: $url");

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
        print("✅ Éxito: ${records.length} cursos encontrados.");
        return records.map((json) => Curso.fromAirtable(json)).toList();
      } else {
        // Log detallado del error si no es 200
        print("❌ Error Airtable (${response.statusCode}): ${response.body}");
        throw Exception('Error Airtable: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Excepción crítica en fetchCursosPublicos: $e');
      return []; // Retorna lista vacía para no crashear la app
    }
  }

  // 2. VERIFICAR COMPRA Y OBTENER DETALLE (FUSIÓN)
  Future<Curso> enriquecerCursoConEstado(Curso cursoPublico) async {
    User? user = _auth.currentUser;

    if (user == null) {
      return cursoPublico;
    }

    try {
      // A. Verificar en colección 'compras'
      final querySnapshot = await _firestore
          .collection('compras')
          .where('usuario_uid', isEqualTo: user.uid)
          .where('curso_id', isEqualTo: cursoPublico.id)
          .where('status', isEqualTo: 'pagado')
          .limit(1)
          .get();

      bool haComprado = querySnapshot.docs.isNotEmpty;

      if (!haComprado) {
        return cursoPublico;
      }

      // B. Descargar TEMARIO PRIVADO de Firestore
      final cursoDoc = await _firestore.collection('cursos').doc(cursoPublico.id).get();

      if (cursoDoc.exists && cursoDoc.data() != null) {
        final data = cursoDoc.data()!;
        List<dynamic> temarioJson = data['temario'] ?? [];

        List<Modulo> temarioReal = temarioJson
            .map((m) => Modulo.fromJson(m))
            .toList();

        return cursoPublico.copyWithPrivateData(
            temario: temarioReal,
            comprado: true
        );
      } else {
        return cursoPublico.copyWithPrivateData(comprado: true);
      }

    } catch (e) {
      print('Error verificando compra: $e');
      return cursoPublico;
    }
  }

  // 3. REGISTRAR COMPRA (Simulación)
  Future<void> simularCompra(String cursoId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('compras').add({
      'usuario_uid': user.uid,
      'curso_id': cursoId,
      'fecha_compra': FieldValue.serverTimestamp(),
      'status': 'pagado',
      'metodo': 'simulacion_dev'
    });
  }
}