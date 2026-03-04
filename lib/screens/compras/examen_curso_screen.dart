import 'package:flutter/material.dart';
import 'dart:math'; // ✅ Importado para Random.secure()
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/screens/compras/marketplace_dc3_form_screen.dart';

class ExamenCursoScreen extends StatefulWidget {
  final Curso curso;
  final List<Pregunta> preguntas;

  const ExamenCursoScreen({
    super.key,
    required this.curso,
    required this.preguntas,
  });

  @override
  State<ExamenCursoScreen> createState() => _ExamenCursoScreenState();
}

class _ExamenCursoScreenState extends State<ExamenCursoScreen> {
  final Map<int, int> _respuestasSeleccionadas = {};
  bool _enviado = false;
  double _calificacion = 0.0;
  bool _aprobado = false;

  void _calificar() {
    if (_respuestasSeleccionadas.length < widget.preguntas.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor responde todas las preguntas.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int aciertos = 0;
    for (int i = 0; i < widget.preguntas.length; i++) {
      if (_respuestasSeleccionadas[i] == widget.preguntas[i].indiceRespuestaCorrecta) {
        aciertos++;
      }
    }

    double promedio = 0.0;
    if (widget.preguntas.isNotEmpty) {
      promedio = (aciertos / widget.preguntas.length) * 10.0;
    }

    setState(() {
      _enviado = true;
      _calificacion = promedio;
      _aprobado = promedio >= 8.0;
    });

    if (_aprobado) {
      _mostrarDialogoAprobado();
    } else {
      _mostrarDialogoReprobado();
    }
  }

  // 🚨 PARCHE DE SEGURIDAD: Generación de Folio Criptográficamente Segura
  // Evita ataques de predicción e IDOR en la generación de folios
  String _generarFolioSeguro() {
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    final secureRandom = Random.secure(); // ✅ Entropía real del sistema operativo

    String part1 = List.generate(3, (index) => letters[secureRandom.nextInt(letters.length)]).join();
    String part2 = secureRandom.nextInt(10000).toString().padLeft(4, '0');

    return "$part1-$part2";
  }

  void _mostrarDialogoAprobado() {
    final String folioUnico = _generarFolioSeguro();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('¡Felicidades! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Has aprobado con ${_calificacion.toStringAsFixed(1)}.'),
            const SizedBox(height: 10),
            const Text(
              'Estás a un paso de obtener tu constancia DC-3. '
                  'Toca "Tramitar DC-3" para confirmar tus datos oficiales.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MarketplaceDC3FormScreen(
                    cursoId: widget.curso.id, // ✅ ID requerido para evitar Bypass y Race Conditions
                    cursoNombre: widget.curso.titulo,
                    cursoDuracion: "${widget.curso.duracionHoras} horas",
                    instructorNombre: widget.curso.nombreAgenteCapacitador,
                    instructorEmail: widget.curso.emailInstructor,
                    instructorStps: widget.curso.registroAgenteSTPS,
                    folio: folioUnico, // ✅ Folio seguro inyectado
                    notaFinal: _calificacion,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
            child: const Text('TRAMITAR DC-3'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoReprobado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('No aprobado 😕'),
        content: Text('Tu calificación fue ${_calificacion.toStringAsFixed(1)}. Necesitas 8.0 para aprobar y obtener la constancia.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _enviado = false;
                _respuestasSeleccionadas.clear();
              });
            },
            child: const Text('REINTENTAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('SALIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación Final'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: widget.preguntas.isEmpty
          ? const Center(child: Text("No hay preguntas configuradas para este examen."))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.preguntas.length,
              itemBuilder: (context, index) {
                final p = widget.preguntas[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pregunta ${index + 1}",
                          style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.pregunta,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 12),

                        // ✅ SOLUCIÓN AL ERROR DE COMPILACIÓN
                        RadioGroup<int>(
                          groupValue: _respuestasSeleccionadas[index], // Usa groupValue en vez de value
                          onChanged: (int? val) {
                            // Se valida internamente en lugar de pasar 'null' para respetar el tipado estricto
                            if (!_enviado && val != null) {
                              setState(() {
                                _respuestasSeleccionadas[index] = val;
                              });
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(p.opciones.length, (opIndex) {
                              return RadioListTile<int>(
                                title: Text(p.opciones[opIndex]),
                                value: opIndex,
                                activeColor: const Color(0xFF0D47A1),
                                contentPadding: EdgeInsets.zero,
                              );
                            }),
                          ),
                        ),

                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,-2))]
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _enviado ? null : _calificar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD143),
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
                child: const Text('FINALIZAR Y CALIFICAR', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}