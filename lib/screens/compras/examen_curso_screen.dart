import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart'; // Paquete necesario

class ExamenCursoScreen extends StatefulWidget {
  final String nombreCurso;

  const ExamenCursoScreen({super.key, required this.nombreCurso});

  @override
  State<ExamenCursoScreen> createState() => _ExamenCursoScreenState();
}

class _ExamenCursoScreenState extends State<ExamenCursoScreen> {
  // Controlador para la animación de celebración
  late ConfettiController _confettiController;

  // --- DATOS DEL EXAMEN (Simulados) ---
  final List<Map<String, dynamic>> _preguntas = [
    {
      "pregunta": "¿Cuál es la altura mínima para considerar un trabajo como 'Trabajo en Alturas' según la NOM-009?",
      "opciones": ["1.50 metros", "1.80 metros", "2.00 metros", "3.00 metros"],
      "respuesta_correcta": 1
    },
    {
      "pregunta": "¿Qué significa EPP?",
      "opciones": ["Equipo Para Personas", "Elementos de Protección Personal", "Equipo de Protección Personal", "Escudo Para Peligros"],
      "respuesta_correcta": 2
    },
    {
      "pregunta": "¿Cuál es el documento que acredita las competencias laborales ante la STPS?",
      "opciones": ["Formato DC-1", "Formato DC-3", "Formato DC-5", "Diploma escolar"],
      "respuesta_correcta": 1
    },
    {
      "pregunta": "En caso de incendio, ¿qué tipo de extintor se usa para fuego eléctrico (Clase C)?",
      "opciones": ["Agua", "Polvo Químico Seco o CO2", "Espuma", "Arena"],
      "respuesta_correcta": 1
    },
    {
      "pregunta": "¿Quién es responsable de proporcionar el EPP a los trabajadores?",
      "opciones": ["El trabajador", "El sindicato", "El patrón", "El gobierno"],
      "respuesta_correcta": 2
    },
  ];

  late List<int> _respuestasUsuario;
  bool _examenFinalizado = false;
  // Se eliminaron _calificacionFinal y _aprobado porque no se usaban y causaban warnings

  @override
  void initState() {
    super.initState();
    _respuestasUsuario = List.filled(_preguntas.length, -1);
    // Inicializamos el controlador con una duración de 3 segundos
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    // Importante liberar el controlador para evitar fugas de memoria
    _confettiController.dispose();
    super.dispose();
  }

  void _calificarExamen() {
    if (_respuestasUsuario.contains(-1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor responde todas las preguntas antes de finalizar."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int aciertos = 0;
    for (int i = 0; i < _preguntas.length; i++) {
      if (_respuestasUsuario[i] == _preguntas[i]['respuesta_correcta']) {
        aciertos++;
      }
    }

    double calificacion = (aciertos / _preguntas.length) * 10;
    bool pasoElExamen = calificacion >= 8.0;

    setState(() {
      _examenFinalizado = true;
    });

    if (pasoElExamen) {
      // ¡DISPARAR CONFETI! 🎉
      _confettiController.play();
      _mostrarDialogoResultado(true, calificacion);
    } else {
      _mostrarDialogoResultado(false, calificacion);
    }
  }

  void _mostrarDialogoResultado(bool aprobado, double calificacion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              aprobado ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 60,
              color: aprobado ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              aprobado ? "¡Felicidades!" : "Inténtalo de nuevo",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Tu calificación final es:",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 5),
            Text(
              calificacion.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: aprobado ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              aprobado
                  ? "Has aprobado el curso satisfactoriamente. Tu constancia DC3 está lista para generarse."
                  : "Necesitas una calificación mínima de 8.0 para obtener tu constancia. Repasa los módulos y vuelve a intentarlo.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          if (!aprobado)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _respuestasUsuario = List.filled(_preguntas.length, -1);
                  _examenFinalizado = false;
                });
              },
              child: const Text("Reintentar"),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (aprobado) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Generando Constancia DC3... (Próximamente)"), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: aprobado ? const Color(0xFF2A2A2A) : Colors.grey,
            ),
            child: Text(aprobado ? "Obtener Certificado" : "Salir", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Evaluación Final"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Responde correctamente para acreditar el curso: ${widget.nombreCurso}",
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ...List.generate(_preguntas.length, (index) {
                  return _PreguntaCard(
                    numero: index + 1,
                    pregunta: _preguntas[index]['pregunta'],
                    opciones: _preguntas[index]['opciones'],
                    seleccionada: _respuestasUsuario[index],
                    onRespuestaSeleccionada: (val) {
                      if (!_examenFinalizado) {
                        setState(() {
                          _respuestasUsuario[index] = val;
                        });
                      }
                    },
                    esCorrecta: _examenFinalizado
                        ? _respuestasUsuario[index] == _preguntas[index]['respuesta_correcta']
                        : null,
                  );
                }),

                const SizedBox(height: 20),

                if (!_examenFinalizado)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _calificarExamen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD143),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Finalizar y Calificar",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // --- WIDGET DE CONFETI (Ahora activo) ---
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, // Explosión hacia todas direcciones
              shouldLoop: false, // Solo una vez
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple], // Colores festivos
              numberOfParticles: 20, // Cantidad de papelitos
              gravity: 0.1, // Velocidad de caída
            ),
          ),
        ],
      ),
    );
  }
}

class _PreguntaCard extends StatelessWidget {
  final int numero;
  final String pregunta;
  final List<dynamic> opciones;
  final int seleccionada;
  final Function(int) onRespuestaSeleccionada;
  final bool? esCorrecta;

  const _PreguntaCard({
    required this.numero,
    required this.pregunta,
    required this.opciones,
    required this.seleccionada,
    required this.onRespuestaSeleccionada,
    this.esCorrecta,
  });

  @override
  Widget build(BuildContext context) {
    Color bordeColor = Colors.transparent;
    if (esCorrecta != null) {
      bordeColor = esCorrecta! ? Colors.green : Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: esCorrecta != null ? bordeColor : Colors.white,
            width: 2
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1), // Usamos withValues
              blurRadius: 5,
              offset: const Offset(0, 2)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: Text(
                    numero.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pregunta,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (esCorrecta != null)
                  Icon(
                    esCorrecta! ? Icons.check_circle : Icons.cancel,
                    color: esCorrecta! ? Colors.green : Colors.red,
                  )
              ],
            ),
          ),
          const Divider(height: 1),
          ...List.generate(opciones.length, (index) {
            return RadioListTile<int>(
              title: Text(
                opciones[index],
                style: TextStyle(
                  color: seleccionada == index ? Colors.black : Colors.grey[700],
                  fontWeight: seleccionada == index ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              value: index,
              groupValue: seleccionada,
              activeColor: const Color(0xFFFFD143),
              onChanged: esCorrecta != null ? null : (val) => onRespuestaSeleccionada(val!),
            );
          }),
        ],
      ),
    );
  }
}