import 'package:flutter/material.dart';
import 'package:safety_app/models/curso_model.dart';

class ReproductorCursoScreen extends StatefulWidget {
  final Curso curso;

  const ReproductorCursoScreen({Key? key, required this.curso}) : super(key: key);

  @override
  _ReproductorCursoScreenState createState() => _ReproductorCursoScreenState();
}

class _ReproductorCursoScreenState extends State<ReproductorCursoScreen> {
  // Estado para saber qué lección se está reproduciendo
  late Leccion _leccionActual;
  String _moduloActualTitulo = "";

  @override
  void initState() {
    super.initState();
    // Inicializamos con la primera lección del primer módulo
    if (widget.curso.temario != null && widget.curso.temario!.isNotEmpty) {
      final primerModulo = widget.curso.temario![0];
      if (primerModulo.lecciones.isNotEmpty) {
        _leccionActual = primerModulo.lecciones[0];
        _moduloActualTitulo = primerModulo.titulo;
      }
    }
  }

  void _cambiarLeccion(Leccion nuevaLeccion, String tituloModulo) {
    setState(() {
      _leccionActual = nuevaLeccion;
      _moduloActualTitulo = tituloModulo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro para experiencia de cine
      body: SafeArea(
        child: Column(
          children: [
            // 1. ÁREA DE VIDEO (El "Stage")
            Expanded(
              flex: 4, // Ocupa el 40% de la pantalla aprox
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
                              _leccionActual.tipo == 'video'
                                  ? Icons.play_circle_fill
                                  : Icons.picture_as_pdf,
                              size: 64,
                              color: Colors.white
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Reproduciendo: ${_leccionActual.titulo}",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "(Aquí se integrará el video de URL: ${_leccionActual.url})",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. TÍTULO DE LA CLASE ACTUAL
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _moduloActualTitulo,
                    style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _leccionActual.titulo,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // 3. LISTA DE CONTENIDO (Playlist)
            Expanded(
              flex: 6,
              child: Container(
                color: Color(0xFFF5F7FA),
                child: ListView.builder(
                  itemCount: widget.curso.temario?.length ?? 0,
                  itemBuilder: (context, index) {
                    final modulo = widget.curso.temario![index];
                    return _buildModuloItem(modulo);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuloItem(Modulo modulo) {
    return ExpansionTile(
      initiallyExpanded: true, // Mantener abiertos para ver el contenido fácil
      title: Text(
        modulo.titulo,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      children: modulo.lecciones.map((leccion) {
        bool isSelected = leccion == _leccionActual;

        return Container(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          child: ListTile(
            leading: Icon(
              leccion.tipo == 'video' ? Icons.play_circle_outline : Icons.description_outlined,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            title: Text(
              leccion.titulo,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.blue : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text("${leccion.duracionMinutos} min"),
            trailing: isSelected ? Icon(Icons.bar_chart, color: Colors.blue) : null,
            onTap: () => _cambiarLeccion(leccion, modulo.titulo),
          ),
        );
      }).toList(),
    );
  }
}