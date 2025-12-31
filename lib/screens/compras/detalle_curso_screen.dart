import 'package:flutter/material.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/services/marketplace_service.dart';
import 'package:safety_app/screens/compras/reproductor_curso_screen.dart';

class DetalleCursoScreen extends StatefulWidget {
  final Curso cursoInicial;
  const DetalleCursoScreen({super.key, required this.cursoInicial});

  @override
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
    try {
      bool exito = await _marketplaceService.simularCompra(widget.cursoInicial.id);
      if (!mounted) return;
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Pago exitoso! Acceso habilitado.')));
        setState(() {
          _cursoFullFuture = _marketplaceService.enriquecerCursoConEstado(widget.cursoInicial);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al procesar el pago.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _irAlAula(Curso cursoCompleto) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReproductorCursoScreen(curso: cursoCompleto)),
    ).then((_) {
      setState(() {
        _cursoFullFuture = _marketplaceService.enriquecerCursoConEstado(widget.cursoInicial);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Curso>(
        future: _cursoFullFuture,
        initialData: widget.cursoInicial,
        builder: (context, snapshot) {
          final curso = snapshot.data ?? widget.cursoInicial;
          final bool isPurchased = curso.comprado;
          final bool isCompleted = curso.completado;
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

          String textoBoton;
          Color colorBoton;
          VoidCallback? accionBoton;
          Widget? mensajeEstado;

          if (isPurchased) {
            textoBoton = "IR AL AULA VIRTUAL 🎓";
            colorBoton = Colors.green;
            accionBoton = () => _irAlAula(curso);
          } else if (isCompleted) {
            String precioStr = curso.precioMXN % 1 == 0
                ? curso.precioMXN.toInt().toString()
                : curso.precioMXN.toStringAsFixed(2);
            textoBoton = "RE-CERTIFICARSE (MX\$ $precioStr)";
            colorBoton = Colors.orange;
            accionBoton = _comprarCurso;
            mensajeEstado = Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [Icon(Icons.check_circle, color: Colors.blue), SizedBox(width: 10), Expanded(child: Text("Ya cuentas con un certificado. Compra de nuevo para renovar."))]),
            );
          } else {
            String precioStr = curso.precioMXN % 1 == 0
                ? curso.precioMXN.toInt().toString()
                : curso.precioMXN.toStringAsFixed(2);

            textoBoton = "COMPRAR POR MX\$ $precioStr";
            colorBoton = const Color(0xFFFFD143);
            accionBoton = _comprarCurso;
          }

          if (isLoading) accionBoton = null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(curso.titulo, style: const TextStyle(fontSize: 16, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                  background: Image.network(curso.imagenPortadaUrl, fit: BoxFit.cover, errorBuilder: (c, o, s) => Container(color: Colors.grey)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mensajeEstado != null) mensajeEstado,
                      Text(curso.descripcionLarga, style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: colorBoton, foregroundColor: Colors.black),
                          onPressed: accionBoton,
                          child: isLoading ? const CircularProgressIndicator(color: Colors.black) : Text(textoBoton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      // Si no hay temario descargado aún, no mostramos nada o un loader
                      // ✅ CORRECCIÓN: Se eliminó el '!' innecesario en 'curso.temario.isEmpty'
                      if (curso.temario == null || curso.temario!.isEmpty) {
                        if (isLoading) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                        return const SizedBox();
                      }

                      final modulo = curso.temario![index];

                      if (!isPurchased) {
                        // ✅ MODIFICADO: Muestra el título REAL pero bloqueado
                        return _buildModuloBloqueado(modulo);
                      }
                      return _buildModuloDesbloqueado(modulo);
                    },
                    childCount: curso.temario?.length ?? 0,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ Ahora recibe el objeto Modulo real para mostrar el título
  Widget _buildModuloBloqueado(Modulo modulo) {
    return Card(
      elevation: 0, color: Colors.grey[100], margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(modulo.titulo, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.lock, color: Colors.grey),
          children: modulo.lecciones.map((l) => ListTile(
            dense: true,
            leading: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
            title: Text(l.titulo, style: const TextStyle(color: Colors.grey)),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildModuloDesbloqueado(Modulo modulo) {
    return Card(
      elevation: 2, margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(modulo.titulo, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
        children: modulo.lecciones.map((l) => ListTile(
            dense: true,
            leading: Icon(l.tipo == 'examen' ? Icons.assignment : Icons.play_circle_fill, color: l.tipo == 'examen' ? Colors.orange : Colors.blue),
            title: Text(l.titulo)
        )).toList(),
      ),
    );
  }
}