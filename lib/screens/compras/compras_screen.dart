import 'package:flutter/material.dart';
// SOLUCIÓN: Usamos imports absolutos 'package:safety_app/...' para evitar errores de ruta relativa
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/services/marketplace_service.dart';
import 'detalle_curso_screen.dart'; // Asumimos que este archivo también está en la carpeta 'compras'

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
          'Catálogo de Cursos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0D47A1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFFD143),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'Normatividad STPS'),
            Tab(text: 'Seguridad Patrimonial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña 1: Cursos desde el Servicio
          _ListaCursosSTPS(cursosFuture: _cursosFuture),

          // Pestaña 2: Placeholder
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text('Error al cargar cursos:\n${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text('No hay cursos disponibles por el momento.'),
              ],
            ),
          );
        }

        final cursos = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cursos.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  "Datos del Programa de capacitación, adiestramiento y productividad",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                ),
              );
            }
            final curso = cursos[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _SafetyCourseCard(curso: curso),
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
            // CORRECCIÓN: Se reemplazó .withOpacity(0.1) por .withValues(alpha: 0.1)
            // Esto cumple con las nuevas guías de estilo de Flutter para evitar pérdida de precisión de color.
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Breve descripción:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(
                        curso.descripcionCorta,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      const _DatoFila(icon: Icons.timer, texto: "Duración en temario"),
                      const SizedBox(height: 4),
                      _DatoFila(icon: Icons.badge, texto: "Instructor: ${curso.nombreInstructor}"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < curso.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(curso.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DetalleCursoScreen(cursoInicial: curso)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD143),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              elevation: 3,
                            ),
                            child: const Text("Inscríbete Ahora", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Positioned(
                            top: -10,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue, width: 1),
                              ),
                              child: Text(
                                "MX\$${curso.precioMXN.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      image: curso.imagenPortadaUrl.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(curso.imagenPortadaUrl),
                        fit: BoxFit.cover,
                        onError: (e, s) {}, // Sintaxis limpia para manejo de errores
                      )
                          : null,
                    ),
                    child: curso.imagenPortadaUrl.isEmpty
                        ? const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CotizacionEmpresarialScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFB8860B), width: 2),
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Cotización Empresarial", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoFila extends StatelessWidget {
  final IconData icon;
  final String texto;
  const _DatoFila({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(child: Text(texto, style: TextStyle(fontSize: 11, color: Colors.grey[800]), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class CotizacionEmpresarialScreen extends StatelessWidget {
  const CotizacionEmpresarialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cotización para Empresas")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 80, color: Color(0xFFD4AF37)),
            SizedBox(height: 20),
            Text(
              "Módulo de Cotización\n(En Construcción)",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}