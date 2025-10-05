// lib/models/aplicacion_model.dart

class Aplicacion {
  final String recordId;
  final String tituloVacante;
  final String nombreEmpresa;
  final String estado;

  Aplicacion({
    required this.recordId,
    required this.tituloVacante,
    required this.nombreEmpresa,
    required this.estado,
  });

  factory Aplicacion.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] as Map<String, dynamic>;

    // NOTA: Estos campos deben ser de tipo "Lookup" en tu tabla 'Aplicaciones'
    // para traer los datos desde la tabla 'Vacantes'.
    final tituloList = fields['TituloVacanteLookup'] as List<dynamic>?;
    final empresaList = fields['NombreEmpresaLookup'] as List<dynamic>?;

    return Aplicacion(
      recordId: record['id'] ?? '',
      tituloVacante: tituloList?.isNotEmpty == true ? tituloList![0] : 'Vacante no disponible',
      nombreEmpresa: empresaList?.isNotEmpty == true ? empresaList![0] : 'Empresa no disponible',
      estado: fields['Estado_Aplicacion'] ?? 'Desconocido',
    );
  }
}