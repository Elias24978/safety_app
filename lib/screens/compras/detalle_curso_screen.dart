import 'package:flutter/material.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/services/marketplace_service.dart';
// Asegúrate de que la ruta sea correcta según dónde guardaste el reproductor.
// Si está en la carpeta screens raíz usa: package:safety_app/screens/reproductor_curso_screen.dart
import 'package:safety_app/screens/compras/reproductor_curso_screen.dart';
import 'package:flutter/material.dart';

class DetalleCursoScreen extends StatefulWidget {
  final Curso cursoInicial;

  // CORRECCIÓN 1: Sintaxis moderna de super constructor
  const DetalleCursoScreen({super.key, required this.cursoInicial});

  @override
  // CORRECCIÓN 2: Definir tipo de retorno público explícito
  State<DetalleCursoScreen> createState() => _DetalleCursoScreenState();
}

class _DetalleCursoScreenState extends State<DetalleCursoScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  late Future<Curso> _cursoFullFuture;

  @override
  void initState() {
    super.initState();
    _cursoFullFuture = _marketplaceService.enriquecerCursoConEstado(widget.cursoInicial);
  }

  void _comprarCurso() async {
    // 1. Simular compra
    // IMPORTANTE: Tu MarketplaceService.simularCompra debe retornar Future<bool>
    bool exito = await _marketplaceService.simularCompra(widget.cursoInicial.id);

    // CORRECCIÓN 3: Verificar si el widget sigue montado antes de usar 'context'
    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Compra exitosa! Desbloqueando contenido...'))
      );
      // 2. Recargar para obtener el temario desbloqueado
      setState(() {
        _cursoFullFuture = _marketplaceService.enriquecerCursoConEstado(widget.cursoInicial);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar la compra. Intenta de nuevo.'))
      );
    }
  }

  void _irAlAula(Curso cursoCompleto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReproductorCursoScreen(curso: cursoCompleto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Curso>(
        future: _cursoFullFuture,
        initialData: widget.cursoInicial,
        builder: (context, snapshot) {
          // Manejo robusto de datos: si snapshot.data es null, usamos cursoInicial
          final curso = snapshot.data ?? widget.cursoInicial;
          final bool isPurchased = curso.comprado;
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

          return CustomScrollView(
            slivers: [
              // 1. PORTADA
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                      curso.titulo,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                      )
                  ),
                  background: Image.network(
                    curso.imagenPortadaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(color: Colors.grey),
                  ),
                ),
              ),

              // 2. INFO DEL CURSO
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(label: Text(curso.categoria), backgroundColor: Colors.blue[50]),
                          const Spacer(),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(" ${curso.rating}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text("Instructor: ${curso.nombreInstructor}", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(curso.descripcionLarga, style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 24),

                      // BOTÓN DE ACCIÓN PRINCIPAL
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPurchased ? Colors.green : const Color(0xFFFFD143),
                            foregroundColor: isPurchased ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isLoading
                              ? null
                              : (isPurchased
                              ? () => _irAlAula(curso) // <--- NAVEGACIÓN REAL
                              : _comprarCurso),
                          child: isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text(
                            isPurchased ? "IR AL AULA VIRTUAL 🎓" : "COMPRAR POR \$${curso.precioMXN}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. TEMARIO (PREVIEW O REAL)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      // Si NO está comprado o NO ha cargado el temario completo, mostramos bloqueado
                      if (!isPurchased || curso.temario == null) {
                        return _buildModuloBloqueado(index);
                      }

                      // Si YA está comprado, mostramos la lista real
                      final modulo = curso.temario![index];
                      return _buildModuloDesbloqueado(modulo);
                    },
                    childCount: isPurchased && curso.temario != null
                        ? curso.temario!.length
                        : 4, // 4 items dummy si está bloqueado
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModuloBloqueado(int index) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: ListTile(
        leading: const Icon(Icons.lock_outline, color: Colors.grey),
        title: Text("Módulo ${index + 1}", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
        subtitle: const Text("Contenido reservado para alumnos."),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildModuloDesbloqueado(Modulo modulo) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(modulo.titulo, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
        children: modulo.lecciones.map((leccion) {
          return ListTile(
            dense: true,
            leading: Icon(
              leccion.tipo == 'video' ? Icons.play_circle_fill : Icons.description,
              color: Colors.blue,
              size: 20,
            ),
            title: Text(leccion.titulo),
            trailing: Text("${leccion.duracionMinutos} min", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          );
        }).toList(),
      ),
    );
  }
}