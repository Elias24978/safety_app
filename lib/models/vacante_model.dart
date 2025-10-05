// lib/models/vacante_model.dart

class Vacante {
  final String id;
  final String titulo;
  final String nombreEmpresa;
  final String ubicacion;
  final String tipoContrato;
  final String descripcion;

  Vacante({
    required this.id,
    required this.titulo,
    required this.nombreEmpresa,
    required this.ubicacion,
    required this.tipoContrato,
    required this.descripcion,
  });

  factory Vacante.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] as Map<String, dynamic>;

    // Pro-Tip: En Airtable, en tu tabla 'Vacantes', crea un campo de tipo "Lookup"
    // que apunte al campo 'Empresa' y traiga el valor de 'Nombre_Empresa'.
    // Nombra a este campo "NombreEmpresaLookup" para que coincida aquí.
    final nombreEmpresaList = fields['NombreEmpresaLookup'] as List<dynamic>?;

    return Vacante(
      id: record['id'] ?? '',
      titulo: fields['Titulo_Vacante'] ?? 'Sin título',
      nombreEmpresa: nombreEmpresaList?.isNotEmpty == true ? nombreEmpresaList![0] as String : 'Empresa Confidencial',
      ubicacion: fields['Ubicacion'] ?? 'No especificado',
      tipoContrato: fields['Tipo_Contrato'] ?? 'No especificado',
      descripcion: fields['Descripcion_Puesto'] ?? 'Sin descripción',
    );
  }
}