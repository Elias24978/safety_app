class Curso {
  // --- DATOS PÚBLICOS ---
  final String id;
  final String titulo;
  final String descripcionCorta;
  final String descripcionLarga;
  final double precioMXN;
  final String imagenPortadaUrl;
  final String videoTrailerUrl;
  final String nombreInstructor;
  final String categoria;
  final double rating;
  final String estado;

  // --- DATOS STORE ---
  final String? storeId;

  // --- DATOS DC-3 (Airtable) ---
  final int duracionHoras;
  final String areaTematicaClave;
  final String nombreAgenteCapacitador;
  final String registroAgenteSTPS;
  final String emailInstructor; // ✅ ESTE ES EL CAMPO QUE FALTABA

  // --- DATOS PRIVADOS ---
  final List<Modulo>? temario;
  final bool comprado;
  final bool completado;

  Curso({
    required this.id,
    required this.titulo,
    required this.descripcionCorta,
    required this.descripcionLarga,
    required this.precioMXN,
    required this.imagenPortadaUrl,
    required this.videoTrailerUrl,
    required this.nombreInstructor,
    required this.categoria,
    required this.rating,
    required this.estado,
    this.storeId,
    this.duracionHoras = 4,
    this.areaTematicaClave = "6000",
    this.nombreAgenteCapacitador = "Safety App Capacitación",
    this.registroAgenteSTPS = "",
    this.emailInstructor = "masterindustrialsafety@gmail.com", // Default
    this.temario,
    this.comprado = false,
    this.completado = false,
  });

  factory Curso.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] ?? {};

    String portadaUrl = 'https://via.placeholder.com/300';
    if (fields['Imagen_Portada'] is List && fields['Imagen_Portada'].isNotEmpty) {
      portadaUrl = fields['Imagen_Portada'][0]['url'];
    }

    var rawCodigo = fields['Codigo_Instructor'];
    String codigoFinal = 'SAF-GEN';
    if (rawCodigo is String && rawCodigo.isNotEmpty) {
      codigoFinal = rawCodigo;
    } else if (rawCodigo is List && rawCodigo.isNotEmpty) {
      codigoFinal = rawCodigo[0].toString();
    }

    var rawAgente = fields['Nombre_Agente_Capacitador'];
    String agenteFinal = 'Safety App Capacitación';
    if (rawAgente is List && rawAgente.isNotEmpty) {
      agenteFinal = rawAgente[0].toString();
    } else if (rawAgente is String && rawAgente.isNotEmpty) {
      agenteFinal = rawAgente;
    }

    return Curso(
      id: record['id'] ?? '',
      titulo: fields['Titulo'] ?? 'Curso sin título',
      descripcionCorta: fields['Descripcion_Corta'] ?? '',
      descripcionLarga: fields['Descripcion_Larga'] ?? '',
      precioMXN: (fields['Precio'] as num?)?.toDouble() ?? 0.0,
      imagenPortadaUrl: portadaUrl,
      videoTrailerUrl: fields['Video_Trailer'] ?? '',
      nombreInstructor: codigoFinal,
      categoria: fields['Categoria'] ?? 'General',
      rating: (fields['Rating'] as num?)?.toDouble() ?? 5.0,
      estado: fields['Estado'] ?? 'Borrador',
      storeId: fields['ID Producto Store'] as String?,

      duracionHoras: (fields['Duracion_Horas'] as num?)?.toInt() ?? 4,
      areaTematicaClave: fields['Area_Tematica_Clave'] ?? '6000',
      nombreAgenteCapacitador: agenteFinal,
      registroAgenteSTPS: fields['Registro_Agente_STPS'] ?? '',

      // ✅ MAPEAMOS EL EMAIL DESDE AIRTABLE (Asegúrate de que la columna se llame así en Airtable)
      emailInstructor: fields['Email_Instructor'] as String? ?? 'masterindustrialsafety@gmail.com',

      comprado: false,
      completado: false,
      temario: null,
    );
  }

  Curso copyWithPrivateData({
    List<Modulo>? temario,
    bool? comprado,
    bool? completado,
  }) {
    return Curso(
      id: id,
      titulo: titulo,
      descripcionCorta: descripcionCorta,
      descripcionLarga: descripcionLarga,
      precioMXN: precioMXN,
      imagenPortadaUrl: imagenPortadaUrl,
      videoTrailerUrl: videoTrailerUrl,
      nombreInstructor: nombreInstructor,
      categoria: categoria,
      rating: rating,
      estado: estado,
      storeId: storeId,
      duracionHoras: duracionHoras,
      areaTematicaClave: areaTematicaClave,
      nombreAgenteCapacitador: nombreAgenteCapacitador,
      registroAgenteSTPS: registroAgenteSTPS,
      emailInstructor: emailInstructor,
      temario: temario ?? this.temario,
      comprado: comprado ?? this.comprado,
      completado: completado ?? this.completado,
    );
  }
}

class Modulo {
  final String titulo;
  final List<Leccion> lecciones;
  Modulo({required this.titulo, required this.lecciones});
  factory Modulo.fromJson(Map<String, dynamic> json) {
    return Modulo(
      titulo: json['modulo_titulo'] ?? 'Módulo',
      lecciones: (json['lecciones'] as List?)?.map((x) => Leccion.fromJson(x)).toList() ?? [],
    );
  }
}

class Leccion {
  final String titulo;
  final String tipo;
  final String url;
  final int duracionMinutos;
  final List<Pregunta>? preguntas;
  Leccion({required this.titulo, required this.tipo, required this.url, this.duracionMinutos = 0, this.preguntas});
  factory Leccion.fromJson(Map<String, dynamic> json) {
    return Leccion(
      titulo: json['titulo'] ?? 'Lección',
      tipo: json['tipo'] ?? 'video',
      url: json['url'] ?? '',
      duracionMinutos: (json['duracion'] as num?)?.toInt() ?? 0,
      preguntas: (json['preguntas'] as List?)?.map((x) => Pregunta.fromJson(x)).toList(),
    );
  }
}

class Pregunta {
  final String pregunta;
  final List<String> opciones;
  final int indiceRespuestaCorrecta;
  Pregunta({required this.pregunta, required this.opciones, required this.indiceRespuestaCorrecta});
  factory Pregunta.fromJson(Map<String, dynamic> json) {
    return Pregunta(
      pregunta: json['pregunta'] ?? '¿Pregunta vacía?',
      opciones: List<String>.from(json['opciones'] ?? []),
      indiceRespuestaCorrecta: (json['correcta'] as num?)?.toInt() ?? 0,
    );
  }
}