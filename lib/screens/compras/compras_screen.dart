import 'package:flutter/material.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/services/marketplace_service.dart';
import 'package:safety_app/screens/compras/detalle_curso_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Curso>> _cursosFuture;
  final MarketplaceService _marketplaceService = MarketplaceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarCursos();
  }

  void _cargarCursos() {
    setState(() {
      _cursosFuture = _marketplaceService.fetchCursosPublicos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE BÚSQUEDA ---
  void _abrirBusqueda() async {
    try {
      final cursos = await _cursosFuture;
      if (!mounted) return;

      showSearch(
        context: context,
        delegate: CourseSearchDelegate(cursos),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Espere a que carguen los cursos para buscar.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Marketplace',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black87),
              tooltip: "Buscar Curso",
              onPressed: _abrirBusqueda,
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0D47A1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFFD143),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'Cursos'),
            Tab(text: 'Info y Ayuda'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ListaCursosSTPS(cursosFuture: _cursosFuture),
          const _GuiaDC3Tab(), // Pestaña rediseñada e interactiva
        ],
      ),
    );
  }
}

// =====================================================================
// SECCIÓN: GUÍA Y AYUDA CON FAQs Y FORMULARIOS
// =====================================================================
class _GuiaDC3Tab extends StatelessWidget {
  const _GuiaDC3Tab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tu camino hacia la Constancia DC-3",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 8),
          Text(
            "Obtener tu documento oficial nunca fue tan fácil y seguro. Te guiamos paso a paso para que te capacites con total tranquilidad.",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
          ),
          const SizedBox(height: 24),

          // --- PASOS PERSUASIVOS ---
          _buildPaso(
              Icons.security_outlined,
              "1. Compra 100% Segura",
              "Elige el curso que necesitas. Tu pago está totalmente protegido y te garantizamos acceso inmediato al material de estudio."
          ),
          _buildPaso(
              Icons.access_time_outlined,
              "2. Aprende a tu ritmo",
              "Accede al contenido 24/7 desde la sección 'Mis Cursos'. Estudia con tranquilidad, sin presiones ni horarios fijos."
          ),
          _buildPaso(
              Icons.sentiment_very_satisfied_outlined,
              "3. Evaluación sin estrés",
              "Responde el examen cuando te sientas listo. ¿No aprobaste a la primera? ¡No te preocupes! Puedes reintentarlo las veces que necesites sin costo extra."
          ),
          _buildPaso(
              Icons.workspace_premium_outlined,
              "4. Tu DC-3 Garantizada",
              "Al aprobar (mínimo 8.0), solo ingresa tus datos oficiales y el sistema enviará tu constancia legal avalada por la STPS a tu correo."
          ),

          const SizedBox(height: 32),
          const Divider(thickness: 1),
          const SizedBox(height: 24),

          // --- FAQs ---
          const Text(
            "Preguntas Frecuentes",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 16),
          _buildFaqItem("1. ¿Cuánto tiempo tarda en llegar mi constancia DC-3?", "El proceso es automatizado. Una vez que apruebas y confirmas tus datos, la recibes en tu correo electrónico en un lapso máximo de 24 horas."),
          _buildFaqItem("2. ¿Qué validez tiene el formato generado?", "Es 100% válida. Cumple con los requisitos legales de la Secretaría del Trabajo y Previsión Social (STPS) y es avalada por Agentes Capacitadores registrados."),
          _buildFaqItem("3. ¿Es seguro hacer el pago en la aplicación?", "Absolutamente. Usamos las pasarelas de pago más seguras del mercado. Tus datos financieros están encriptados y protegidos en todo momento."),
          _buildFaqItem("4. ¿Tengo límite de tiempo para terminar un curso?", "¡Ninguno! Una vez adquirido, el curso es tuyo. Puedes estudiar y presentar tu examen hoy, mañana o en un mes. Tú decides tus tiempos."),
          _buildFaqItem("5. ¿Qué pasa si repruebo la evaluación final?", "No pasa nada. El sistema te permite volver a repasar tus lecciones y presentar el examen nuevamente sin ningún costo adicional hasta que apruebes."),
          _buildFaqItem("6. ¿Los cursos están avalados por capacitadores reales?", "Sí, todos nuestros cursos están respaldados por instructores con registro activo y vigente ante la STPS, cuyos datos aparecerán en tu formato final."),
          _buildFaqItem("7. ¿Puedo descargar el material de estudio?", "Actualmente el material está diseñado para consumirse dentro de la App, garantizando siempre que tengas acceso a la versión más actualizada de las normativas."),
          _buildFaqItem("8. ¿Puedo corregir mis datos si me equivoqué en algún dato?", "Sí te equivocas en algún dato puedes enviar la corrección en la sección de centro de contacto '¿Tienes alguna duda o problema?' agregando tu número de folio, o bien, respondiendo al correo donde recibiste tu DC-3."),
          _buildFaqItem("9. ¿Qué material requiero para realizar el curso?", "Solo necesitas dedicarle un poco de tiempo y usar tu celular o una tablet."),
          _buildFaqItem("10. ¿Qué hago si no recibo el correo con mi certificado?", "Revisa tu carpeta de SPAM o Correo no deseado. Si pasadas 24 horas no lo tienes, usa el formulario de contacto aquí abajo y te lo reenviaremos inmediatamente."),

          const SizedBox(height: 32),
          const Divider(thickness: 1),
          const SizedBox(height: 24),

          // --- FORMULARIOS NATIVOS ---
          const Text(
            "Centro de Contacto",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 16),

          // 1. SOPORTE Y DUDAS
          const _ContactFormCard(
            type: 'Soporte / Duda',
            title: '¿Tienes alguna duda o problema?',
            description: 'Escríbenos y nuestro equipo te responderá directo a tu correo lo antes posible.',
            hintMessage: 'Escribe tu duda aquí (Máx. 330 caracteres)',
            maxLength: 330,
            iconData: Icons.support_agent,
            buttonText: 'ENVIAR DUDA',
            colorTheme: Color(0xFF0D47A1),
          ),

          // 2. SUGERIR CURSO
          const _ContactFormCard(
            type: 'Sugerencia de Curso',
            title: '¿No encuentras el curso que buscas?',
            description: 'Dinos qué curso de seguridad necesitas. Lo buscaremos o contactaremos a un capacitador para subirlo a la plataforma.',
            hintMessage: 'Ej. Necesito el curso de NOM-020 Recipientes Sujetos a Presión...',
            maxLength: 150,
            iconData: Icons.manage_search,
            buttonText: 'SUGERIR CURSO',
            colorTheme: Colors.orange,
          ),

          // 3. INSTRUCTORES
          const _ContactFormCard(
            type: 'Solicitud de Instructor',
            title: '¿Eres Agente Capacitador?',
            description: 'Únete a nuestra red. Publica tus cursos y llega a más empresas y trabajadores.',
            hintMessage: 'Déjanos tu Nombre, Especialidad y Registro STPS para contactarte.',
            maxLength: 300,
            iconData: Icons.school,
            buttonText: 'SOLICITAR INFORMACIÓN',
            colorTheme: Colors.green,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPaso(IconData icon, String titulo, String descripcion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0D47A1), size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(descripcion, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
        ),
        iconColor: const Color(0xFF0D47A1),
        collapsedIconColor: Colors.grey.shade600,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        expandedAlignment: Alignment.centerLeft,
        children: [
          Text(
            answer,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// WIDGET REUTILIZABLE: FORMULARIOS DE CONTACTO ENLAZADOS A GOOGLE APPS SCRIPT
// =====================================================================
class _ContactFormCard extends StatefulWidget {
  final String type;
  final String title;
  final String description;
  final String hintMessage;
  final int maxLength;
  final IconData iconData;
  final String buttonText;
  final Color colorTheme;

  const _ContactFormCard({
    required this.type,
    required this.title,
    required this.description,
    required this.hintMessage,
    required this.maxLength,
    required this.iconData,
    required this.buttonText,
    required this.colorTheme,
  });

  @override
  State<_ContactFormCard> createState() => _ContactFormCardState();
}

class _ContactFormCardState extends State<_ContactFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _enviarDatos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 🚨 URL DEL NUEVO SCRIPT DE SOPORTE 🚨
    const String scriptUrl = "https://script.google.com/macros/s/AKfycbw7nnbaRwnqw4O4XTQcySrh__XPe2zs-4nAjQLomePfmJyWX29rKfb1tCw6nyF97idTiQ/exec";

    try {
      // IMPORTANTE: Usamos http.Request para evitar que Flutter siga automáticamente
      // la redirección 302 de Google y cambie el método POST a GET.
      final request = http.Request('POST', Uri.parse(scriptUrl))
        ..headers.addAll({'Content-Type': 'application/json'})
        ..body = jsonEncode({
          'tipo': widget.type,
          'email': _emailCtrl.text.trim(),
          'mensaje': _msgCtrl.text.trim(),
        })
        ..followRedirects = false; // 🔥 ESTO PREVIENE EL ERROR SILENCIOSO

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      http.Response finalResponse = response;

      // Manejamos manualmente la redirección para obtener el JSON real del doPost
      if (response.statusCode == 302 || response.statusCode == 303) {
        final String? redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          finalResponse = await http.get(Uri.parse(redirectUrl));
        }
      }

      if (finalResponse.statusCode == 200 || finalResponse.statusCode == 201) {
        if (finalResponse.body.trim().startsWith('<')) {
          throw Exception('Error del servidor: El script no está desplegado para "Cualquier Persona" o faltan permisos.');
        }

        final Map<String, dynamic> responseData = jsonDecode(finalResponse.body);

        if (responseData['status'] == 'success') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Mensaje enviado exitosamente! Te contactaremos pronto.'), backgroundColor: Colors.green),
          );
          _emailCtrl.clear();
          _msgCtrl.clear();
        } else {
          throw Exception(responseData['message'] ?? 'Error desconocido en el script.');
        }
      } else {
        throw Exception("Error de servidor HTTP: ${finalResponse.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: widget.colorTheme.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.iconData, color: widget.colorTheme, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.colorTheme),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Correo del usuario
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Tu Correo Electrónico',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) => v!.isEmpty || !v.contains('@') ? 'Ingresa un correo válido' : null,
            ),
            const SizedBox(height: 12),

            // Mensaje
            TextFormField(
              controller: _msgCtrl,
              maxLines: 3,
              maxLength: widget.maxLength,
              decoration: InputDecoration(
                hintText: widget.hintMessage,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v!.isEmpty ? 'No puedes enviar un mensaje vacío' : null,
            ),
            const SizedBox(height: 12),

            // Botón de Enviar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _enviarDatos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colorTheme,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// LISTA DE CURSOS Y BÚSQUEDA (Sin Cambios funcionales)
// =====================================================================

class _ListaCursosSTPS extends StatelessWidget {
  final Future<List<Curso>> cursosFuture;
  const _ListaCursosSTPS({required this.cursosFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Curso>>(
      future: cursosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD143)));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay cursos disponibles.'));
        }

        final cursos = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cursos.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _SafetyCourseCard(curso: cursos[index]),
            );
          },
        );
      },
    );
  }
}

class _SafetyCourseCard extends StatelessWidget {
  final Curso curso;
  const _SafetyCourseCard({required this.curso});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              curso.titulo,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(curso.descripcionCorta, maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Instructor: ${curso.nombreInstructor}",
                              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DetalleCursoScreen(cursoInicial: curso)),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD143)),
                        child: const Text("Ver Detalles", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
                if (curso.imagenPortadaUrl.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          curso.imagenPortadaUrl,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CourseSearchDelegate extends SearchDelegate {
  final List<Curso> cursos;

  CourseSearchDelegate(this.cursos);

  @override
  String get searchFieldLabel => 'Buscar cursos...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text("Escribe para buscar..."));
    }

    final results = cursos.where((curso) {
      final tituloLower = curso.titulo.toLowerCase();
      final instructorLower = curso.nombreInstructor.toLowerCase();
      final queryLower = query.toLowerCase();

      return tituloLower.contains(queryLower) || instructorLower.contains(queryLower);
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text("No se encontraron cursos."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _SafetyCourseCard(curso: results[index]),
        );
      },
    );
  }
}