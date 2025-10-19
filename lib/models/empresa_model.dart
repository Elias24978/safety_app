class Empresa {
  final String recordId;
  final String userIdCreador;
  final String nombreEmpresa;
  final String? emailEmpresa;
  final String? telefono;

  Empresa({
    required this.recordId,
    required this.userIdCreador,
    required this.nombreEmpresa,
    this.emailEmpresa,
    this.telefono,
  });

  factory Empresa.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] as Map<String, dynamic>;
    return Empresa(
      recordId: record['id'] ?? '',
      userIdCreador: fields['UserID_Creador'] ?? '',
      nombreEmpresa: fields['Nombre_Empresa'] ?? 'Sin Nombre',
      emailEmpresa: fields['Email_Empresa'],
      telefono: fields['telefono'],
    );
  }
}