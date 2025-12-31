import 'package:flutter/material.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/services/marketplace_service.dart';
import 'package:safety_app/screens/compras/detalle_curso_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // --- LÓGICA DE CONTACTO PARA INSTRUCTORES ---
  Future<void> _contactarParaInstructor() async {
    const String emailSoporte = "masterindustrialsafety@gmail.com";

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailSoporte,
      query: _encodeQueryParameters({
        'subject': 'Solicitud para ser Instructor - SafetyApp',
        'body': 'Hola equipo de SafetyApp,\n\nMe gustaría obtener información sobre cómo publicar mis cursos en su plataforma.\n\nMis datos son:\n- Nombre:\n- Especialidad:\n',
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró una aplicación de correo disponible.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al intentar abrir correo: $e')),
      );
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
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
        // BOTÓN DE BÚSQUEDA
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
            Tab(text: 'Productos Físicos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ListaCursosSTPS(cursosFuture: _cursosFuture),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 20),
                Text("Tienda de Productos Físicos\n(Próximamente)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
      // BOTÓN FLOTANTE PARA INSTRUCTORES
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contactarParaInstructor,
        backgroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Colors.green, width: 1.5),
        ),
        icon: const Icon(Icons.school, color: Colors.green, size: 28),
        label: const Text(
          "¿Quieres ser\ninstructor?",
          textAlign: TextAlign.start,
          style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.1
          ),
        ),
      ),
    );
  }
}

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
            color: Colors.black.withOpacity(0.1),
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
                      // ✅ CAMBIO VISUAL: Muestra el CÓDIGO con icono de gafete
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

// CLASE DELEGADA PARA LA BÚSQUEDA
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