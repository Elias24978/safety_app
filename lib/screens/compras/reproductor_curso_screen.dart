import 'package:flutter/material.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/screens/compras/examen_curso_screen.dart';
import 'package:safety_app/services/marketplace_service.dart';
// Asegúrate de tener url_launcher para abrir PDFs si es necesario
import 'package:url_launcher/url_launcher.dart';

class ReproductorCursoScreen extends StatefulWidget {
  final Curso curso;

  const ReproductorCursoScreen({super.key, required this.curso});

  @override
  State<ReproductorCursoScreen> createState() => _ReproductorCursoScreenState();
}

class _ReproductorCursoScreenState extends State<ReproductorCursoScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();

  Leccion? _leccionActual;
  String _moduloActualTitulo = "";
  bool _cargando = true;

  // Lista local de lecciones completadas (Ids o Títulos)
  List<String> _leccionesCompletadas = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEstadoInicial();
    });
  }

  Future<void> _cargarEstadoInicial() async {
    // 1. Cargar progreso desde Firebase
    final progreso = await _marketplaceService.obtenerProgreso(widget.curso.id);

    if (mounted) {
      setState(() {
        _leccionesCompletadas = progreso;
      });
    }

    // 2. Cargar primera lección
    _inicializarLeccion();
  }

  void _inicializarLeccion() {
    if (widget.curso.temario != null && widget.curso.temario!.isNotEmpty) {
      for (var modulo in widget.curso.temario!) {
        if (modulo.lecciones.isNotEmpty) {
          if (mounted) {
            setState(() {
              _leccionActual = modulo.lecciones[0];
              _moduloActualTitulo = modulo.titulo;
              _cargando = false;
            });
            // Marcar la primera lección como vista automáticamente al entrar (opcional, o al final)
            _marcarLeccionComoCompletada(modulo.lecciones[0].titulo);
          }
          return;
        }
      }
    }
    if (mounted) setState(() => _cargando = false);
  }

  // Lógica para marcar lección completada
  Future<void> _marcarLeccionComoCompletada(String leccionId) async {
    if (!_leccionesCompletadas.contains(leccionId)) {
      await _marketplaceService.guardarProgresoLeccion(widget.curso.id, leccionId);
      if (mounted) {
        setState(() {
          _leccionesCompletadas.add(leccionId);
        });
      }
    }
  }

  void _cambiarLeccion(Leccion nuevaLeccion, String tituloModulo) {
    if (nuevaLeccion.tipo == 'examen') {
      // ✅ SEGURIDAD ACADÉMICA:
      // Validar si todas las lecciones NO-Examen están completadas
      if (!_verificarRequisitosExamen()) {
        _mostrarAlertaBloqueo();
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamenCursoScreen(
            curso: widget.curso,
            preguntas: nuevaLeccion.preguntas ?? [],
          ),
        ),
      );
      return;
    }

    setState(() {
      _leccionActual = nuevaLeccion;
      _moduloActualTitulo = tituloModulo;
    });

    // Simulación: Si es Video o PDF, lo marcamos como visto al abrirlo
    // (En una app real de video, esto iría en el evento 'onEnded' del video player)
    _marcarLeccionComoCompletada(nuevaLeccion.titulo);

    // Si es PDF externo, abrirlo
    if (nuevaLeccion.tipo == 'pdf' && nuevaLeccion.url.isNotEmpty) {
      _abrirUrlExterna(nuevaLeccion.url);
    }
  }

  Future<void> _abrirUrlExterna(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _verificarRequisitosExamen() {
    // Contar total de lecciones que NO son examen
    int totalLecciones = 0;
    int leccionesVistas = 0;

    for (var modulo in widget.curso.temario!) {
      for (var leccion in modulo.lecciones) {
        if (leccion.tipo != 'examen') {
          totalLecciones++;
          if (_leccionesCompletadas.contains(leccion.titulo)) {
            leccionesVistas++;
          }
        }
      }
    }
    // Permitir si vio todo (o casi todo, ajustable)
    return leccionesVistas >= totalLecciones;
  }

  void _mostrarAlertaBloqueo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ Curso Incompleto"),
        content: const Text("Debes visualizar todas las lecciones y videos antes de poder realizar el Examen Final."),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendido"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(backgroundColor: Colors.black, body: const Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    if (_leccionActual == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.curso.titulo)),
        body: const Center(child: Text("Sin contenido disponible.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // --- PLAYER ---
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.grey[900],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              _leccionActual!.tipo == 'video' ? Icons.play_circle_fill : Icons.picture_as_pdf,
                              size: 64,
                              color: Colors.white
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _leccionActual!.titulo,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _leccionActual!.tipo == 'video' ? "(Reproductor de Video)" : "(Visor PDF)",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- INFO ---
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _moduloActualTitulo.toUpperCase(),
                    style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _leccionActual!.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // --- LISTA DE LECCIONES ---
            Expanded(
              flex: 6,
              child: Container(
                color: const Color(0xFFF5F7FA),
                child: ListView.builder(
                  itemCount: widget.curso.temario?.length ?? 0,
                  itemBuilder: (context, index) {
                    final modulo = widget.curso.temario![index];
                    return ExpansionTile(
                      initiallyExpanded: true,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(modulo.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      children: modulo.lecciones.map((leccion) {
                        bool isSelected = leccion == _leccionActual;
                        bool isExam = leccion.tipo == 'examen';
                        bool isCompleted = _leccionesCompletadas.contains(leccion.titulo);

                        // Determinar si bloqueamos el examen
                        bool isExamLocked = isExam && !_verificarRequisitosExamen();

                        return Container(
                          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(left: 24, right: 16),
                            enabled: !isExamLocked, // Deshabilita click si está bloqueado
                            leading: Icon(
                              isExam
                                  ? (isExamLocked ? Icons.lock : Icons.assignment_turned_in)
                                  : (leccion.tipo == 'video' ? Icons.play_circle_outline : Icons.description_outlined),
                              color: isExam
                                  ? (isExamLocked ? Colors.grey : Colors.deepOrange)
                                  : (isCompleted ? Colors.green : (isSelected ? Colors.blue : Colors.grey[600])),
                              size: 22,
                            ),
                            title: Text(
                              leccion.titulo,
                              style: TextStyle(
                                fontSize: 13,
                                color: isExamLocked ? Colors.grey : (isSelected ? Colors.blue : Colors.black87),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            subtitle: isExam
                                ? Text(
                                isExamLocked ? "Completa el curso para desbloquear" : "Evaluación Final - Obligatoria",
                                style: TextStyle(color: isExamLocked ? Colors.grey : Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.bold)
                            )
                                : Text("${leccion.duracionMinutos} min", style: const TextStyle(fontSize: 11)),
                            trailing: isCompleted
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                                : (isSelected ? const Icon(Icons.bar_chart, color: Colors.blue, size: 18) : null),
                            onTap: isExamLocked ? () => _mostrarAlertaBloqueo() : () => _cambiarLeccion(leccion, modulo.titulo),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}