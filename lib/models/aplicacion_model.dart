class Aplicacion {
  final String recordId;
  final String vacanteRecordId;
  final String tituloVacante;
  final String nombreEmpresa;
  final String ubicacion;
  final double? sueldoOfertado;
  final String estadoAplicacion;
  final DateTime fechaAplicacion;
  final String descripcion;
  final bool aceptaForaneos;
  final DateTime ultimoModificacion;
  final DateTime fechaPublicacion;
  final String visibilidadOferta;

  // ✅ CAMBIO: Datos del candidato que aplica
  final String nombreCandidato;
  final String? emailCandidato;
  final String? telefonoCandidato;
  final String? cvUrlCandidato;
  final String? candidatoRecordId;

  Aplicacion({
    required this.recordId,
    required this.vacanteRecordId,
    required this.tituloVacante,
    required this.nombreEmpresa,
    required this.ubicacion,
    this.sueldoOfertado,
    required this.estadoAplicacion,
    required this.fechaAplicacion,
    required this.descripcion,
    required this.aceptaForaneos,
    required this.ultimoModificacion,
    required this.fechaPublicacion,
    required this.visibilidadOferta,

    // ✅ CAMBIO: Datos del candidato añadidos al constructor
    required this.nombreCandidato,
    this.emailCandidato,
    this.telefonoCandidato,
    this.cvUrlCandidato,
    this.candidatoRecordId,
  });

  factory Aplicacion.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] as Map<String, dynamic>;

    // Lookups de la Vacante
    final vacanteIdList = fields['VacanteRecordID'] as List<dynamic>?;
    final tituloList = fields['Titulo_Vacante_Lookup'] as List<dynamic>?;
    final empresaList = fields['Empresa_Nombre_Lookup'] as List<dynamic>?;
    final ubicacionList = fields['Ubicacion_Lookup'] as List<dynamic>?;
    final sueldoList = fields['Sueldo_Ofertado_Lookup'] as List<dynamic>?;
    final descripcionList = fields['Descripcion_Lookup'] as List<dynamic>?;
    final aceptaForaneosList = fields['Acepta_Foraneos_Lookup'] as List<dynamic>?;
    final ultimoModificacionList = fields['Ultimo_Modificacion_Lookup'] as List<dynamic>?;
    final fechaPublicacionList = fields['Fecha_Publicacion_Lookup'] as List<dynamic>?;
    final visibilidadOfertaList = fields['Visibilidad_Oferta_Lookup'] as List<dynamic>?;

    // ✅ CAMBIO: Lookups del Candidato
    final candidatoRecordIdList = fields['Candidato'] as List<dynamic>?; // El campo de enlace
    final nombreCandidatoList = fields['Nombre_Candidato_Lookup'] as List<dynamic>?;
    final emailCandidatoList = fields['Email_Candidato_Lookup'] as List<dynamic>?;
    final telefonoCandidatoList = fields['Telefono_Candidato_Lookup'] as List<dynamic>?;
    final cvUrlCandidatoList = fields['CV_URL_Lookup'] as List<dynamic>?;

    return Aplicacion(
      recordId: record['id'] ?? '',
      vacanteRecordId: vacanteIdList?.isNotEmpty == true ? vacanteIdList![0] : '',
      tituloVacante: tituloList?.isNotEmpty == true ? tituloList![0] : 'Título no disponible',
      nombreEmpresa: empresaList?.isNotEmpty == true ? empresaList![0] : 'Empresa no disponible',
      ubicacion: ubicacionList?.isNotEmpty == true ? ubicacionList![0] : 'Ubicación no disponible',
      sueldoOfertado: sueldoList?.isNotEmpty == true ? (sueldoList![0] as num).toDouble() : null,
      estadoAplicacion: fields['Estado_Aplicacion'] ?? 'Estado desconocido',
      fechaAplicacion: DateTime.parse(fields['Fecha_Aplicacion'] ?? DateTime.now().toIso8601String()),
      descripcion: descripcionList?.isNotEmpty == true ? descripcionList![0] : 'Sin descripción',
      aceptaForaneos: aceptaForaneosList?.isNotEmpty == true && aceptaForaneosList![0] == true,
      ultimoModificacion: DateTime.parse(ultimoModificacionList?.isNotEmpty == true ? ultimoModificacionList![0] : DateTime.now().toIso8601String()),
      fechaPublicacion: DateTime.parse(fechaPublicacionList?.isNotEmpty == true ? fechaPublicacionList![0] : DateTime.now().toIso8601String()),
      visibilidadOferta: visibilidadOfertaList?.isNotEmpty == true ? visibilidadOfertaList![0] : 'Oculta',

      // ✅ CAMBIO: Asignación de datos del candidato
      candidatoRecordId: candidatoRecordIdList?.isNotEmpty == true ? candidatoRecordIdList![0] : null,
      nombreCandidato: nombreCandidatoList?.isNotEmpty == true ? nombreCandidatoList![0] : 'Candidato anónimo',
      emailCandidato: emailCandidatoList?.isNotEmpty == true ? emailCandidatoList![0] : null,
      telefonoCandidato: telefonoCandidatoList?.isNotEmpty == true ? telefonoCandidatoList![0] : null,
      cvUrlCandidato: cvUrlCandidatoList?.isNotEmpty == true ? cvUrlCandidatoList![0] : null,
    );
  }
}