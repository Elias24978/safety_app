class Curso {
  // --- DATOS PÚBLICOS (Origen: Airtable) ---
  final String id; // ID único: RECORD_ID() de Airtable == ID del Documento en Firestore
  final String titulo;
  final String descripcionCorta;
  final String descripcionLarga;
  final double precioMXN;
  final String imagenPortadaUrl;
  final String videoTrailerUrl;
  final String nombreInstructor;
  final String categoria;
  final double rating;
  final String estado; // 'Publicado', 'Borrador'

  // --- DATOS PRIVADOS (Origen: Firebase Firestore) ---
  // Estos campos son null hasta que se verifica la compra
  final List<Modulo>? temario;
  final bool comprado; // Flag local para controlar la UI (candado vs. play)

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
    this.temario,
    this.comprado = false,
  });

  // Constructor Factory: Crea una instancia "ligera" desde Airtable
  factory Curso.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] ?? {};

    // Manejo robusto de imagen: Airtable devuelve un array de attachments
    String portadaUrl = 'https://via.placeholder.com/300'; // Fallback
    if (fields['Imagen_Portada'] is List && fields['Imagen_Portada'].isNotEmpty) {
      portadaUrl = fields['Imagen_Portada'][0]['url'];
    }

    return Curso(
      id: record['id'] ?? '',
      titulo: fields['Titulo'] ?? 'Curso sin título',
      descripcionCorta: fields['Descripcion_Corta'] ?? '',
      descripcionLarga: fields['Descripcion_Larga'] ?? '',
      // Uso de 'num?' para aceptar tanto int como double sin error
      precioMXN: (fields['Precio_MXN'] as num?)?.toDouble() ?? 0.0,
      imagenPortadaUrl: portadaUrl,
      videoTrailerUrl: fields['Video_Trailer'] ?? '',
      nombreInstructor: fields['Nombre_Instructor'] ?? 'Instructor Safety',
      categoria: fields['Categoria'] ?? 'General',
      rating: (fields['Rating'] as num?)?.toDouble() ?? 5.0,
      estado: fields['Estado'] ?? 'Borrador',
      comprado: false, // Por defecto, al venir de Airtable, no está "validado" aún
      temario: null,
    );
  }

  // Método de Fusión: Crea una copia del curso inyectando los datos de Firestore
  Curso copyWithPrivateData({
    List<Modulo>? temario,
    bool? comprado,
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
      temario: temario ?? this.temario,
      comprado: comprado ?? this.comprado,
    );
  }
}

// --- SUB-MODELOS (Estructura interna del JSON de Firestore) ---

class Modulo {
  final String titulo;
  final List<Leccion> lecciones;

  Modulo({required this.titulo, required this.lecciones});

  factory Modulo.fromJson(Map<String, dynamic> json) {
    return Modulo(
      titulo: json['modulo_titulo'] ?? 'Módulo',
      lecciones: (json['lecciones'] as List?)
          ?.map((x) => Leccion.fromJson(x))
          .toList() ?? [],
    );
  }
}

class Leccion {
  final String titulo;
  final String tipo; // 'video', 'pdf', 'examen'
  final String url; // URL del recurso (Storage o Link externo)
  final int duracionMinutos;
  // Puedes agregar 'completada' aquí si quieres trackear progreso localmente en el futuro

  Leccion({
    required this.titulo,
    required this.tipo,
    required this.url,
    this.duracionMinutos = 0,
  });

  factory Leccion.fromJson(Map<String, dynamic> json) {
    return Leccion(
      titulo: json['titulo'] ?? 'Lección',
      tipo: json['tipo'] ?? 'video',
      url: json['url'] ?? '',
      // Robustez: Convierte cualquier número (int/double) a int de forma segura
      duracionMinutos: (json['duracion'] as num?)?.toInt() ?? 0,
    );
  }
}