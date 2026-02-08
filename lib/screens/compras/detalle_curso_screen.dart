import 'package:flutter/material.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/screens/compras/reproductor_curso_screen.dart';
import 'package:safety_app/services/marketplace_service.dart';
import 'package:safety_app/services/purchase_service.dart';
import 'package:safety_app/widgets/boton_compra_curso.dart';

class DetalleCursoScreen extends StatefulWidget {
  final Curso cursoInicial;
  const DetalleCursoScreen({super.key, required this.cursoInicial});

  @override
  State<DetalleCursoScreen> createState() => _DetalleCursoScreenState();
}

class _DetalleCursoScreenState extends State<DetalleCursoScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  late Future<Curso> _cursoFullFuture;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _recargarEstadoDelCurso();
  }

  void _recargarEstadoDelCurso() {
    setState(() {
      _cursoFullFuture =
          _marketplaceService.enriquecerCursoConEstado(widget.cursoInicial);
    });
  }

  Future<void> _onCompraExitosa() async {
    await _marketplaceService.registrarCompraNueva(widget.cursoInicial.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("¡Compra confirmada! Acceso habilitado."),
        backgroundColor: Colors.green,
      ),
    );

    _recargarEstadoDelCurso();
  }

  Future<void> _restaurarCompras() async {
    setState(() => _isRestoring = true);
    await PurchaseService().restorePurchases();
    _recargarEstadoDelCurso();
    setState(() => _isRestoring = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verificación completada.")),
      );
    }
  }

  void _irAlCurso(Curso cursoCompleto) {
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
          final curso = snapshot.data ?? widget.cursoInicial;
          final temario = curso.temario ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    curso.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  background: Image.network(
                    curso.imagenPortadaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(color: Colors.grey),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curso.descripcionLarga,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // --- ZONA DE ACCIÓN (Ahora primero) ---
                      if (!curso.comprado) ...[
                        BotonCompraCurso(
                          curso: curso,
                          onCompraExitosa: _onCompraExitosa,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: _isRestoring
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : TextButton.icon(
                            onPressed: _restaurarCompras,
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text("Restaurar compras"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ),
                      ] else ...[
                        _buildStatusAdquirido(curso),
                      ],

                      const SizedBox(height: 40),

                      // --- VITRINA DE CONTENIDO (Ahora al final) ---
                      if (temario.isNotEmpty) ...[
                        const Text(
                          "Contenido del Curso",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Lista de módulos
                        ...temario.map((modulo) => _buildModuloItem(modulo, curso.comprado)),
                        const SizedBox(height: 24),
                      ] else if (snapshot.connectionState == ConnectionState.waiting) ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget modificado: Si está bloqueado, NO muestra lecciones (títulos/duración)
  Widget _buildModuloItem(Modulo modulo, bool desbloqueado) {
    if (!desbloqueado) {
      // CASO BLOQUEADO (Vitrina): Solo título del módulo + Candado
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        color: Colors.grey[50],
        child: ListTile(
          title: Text(
            modulo.titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          trailing: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
        ),
      );
    } else {
      // CASO DESBLOQUEADO: ExpansionTile con lecciones visibles
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.blue.shade100,
          ),
        ),
        color: Colors.white,
        child: ExpansionTile(
          title: Text(
            modulo.titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          initiallyExpanded: false,
          children: modulo.lecciones.map((leccion) {
            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.play_circle_outline,
                color: Colors.blue,
                size: 20,
              ),
              title: Text(
                leccion.titulo,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              trailing: leccion.duracionMinutos > 0
                  ? Text(
                "${leccion.duracionMinutos} min",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
                  : null,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Usa el botón 'Comenzar Curso' para iniciar.")),
                );
              },
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildStatusAdquirido(Curso curso) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "ACCESO ADQUIRIDO",
                style:
                TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _irAlCurso(curso),
            icon: const Icon(Icons.play_circle_fill),
            label: const Text("COMENZAR CURSO AHORA"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }
}