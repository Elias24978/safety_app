import 'package:flutter/material.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/screens/compras/marketplace_dc3_form_screen.dart';

class ExamenCursoScreen extends StatefulWidget {
  final Curso curso;
  // Recibimos las preguntas directamente de la lección seleccionada
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
  // Mapa para guardar las respuestas seleccionadas: índicePregunta -> índiceOpción
  final Map<int, int> _respuestasSeleccionadas = {};
  bool _enviado = false;
  double _calificacion = 0.0;
  bool _aprobado = false;

  void _calificar() {
    if (_respuestasSeleccionadas.length < widget.preguntas.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor responde todas las preguntas antes de finalizar.')),
      );
      return;
    }

    int aciertos = 0;
    for (int i = 0; i < widget.preguntas.length; i++) {
      // ✅ CORRECCIÓN: Usamos 'indiceRespuestaCorrecta' en lugar de 'indiceCorrecto'
      if (_respuestasSeleccionadas[i] == widget.preguntas[i].indiceRespuestaCorrecta) {
        aciertos++;
      }
    }

    double promedio = (aciertos / widget.preguntas.length) * 10.0;

    setState(() {
      _enviado = true;
      _calificacion = promedio;
      _aprobado = promedio >= 8.0; // Mínimo 8.0 para aprobar
    });

    if (_aprobado) {
      _mostrarDialogoAprobado();
    } else {
      _mostrarDialogoReprobado();
    }
  }

  void _mostrarDialogoAprobado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Felicidades! 🎉'),
        content: Text('Has aprobado con $_calificacion. Ya puedes generar tu constancia DC-3.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Cierra dialogo
              // Navegar al formulario DC-3
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MarketplaceDC3FormScreen(curso: widget.curso),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('GENERAR DC-3'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoReprobado() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inténtalo de nuevo 😕'),
        content: Text('Tu calificación fue $_calificacion. Necesitas 8.0 para aprobar.'),
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
            onPressed: () => Navigator.pop(context), // Salir del examen
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
                final preguntaItem = widget.preguntas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // ✅ CORRECCIÓN: Usamos 'preguntaItem.pregunta' en lugar de 'enunciado'
                          "${index + 1}. ${preguntaItem.pregunta}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(preguntaItem.opciones.length, (opIndex) {
                          return RadioListTile<int>(
                            title: Text(preguntaItem.opciones[opIndex]),
                            value: opIndex,
                            groupValue: _respuestasSeleccionadas[index],
                            activeColor: const Color(0xFF0D47A1),
                            onChanged: _enviado ? null : (val) {
                              setState(() {
                                _respuestasSeleccionadas[index] = val!;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0,-2))]
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _enviado ? null : _calificar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD143),
                  foregroundColor: Colors.black,
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