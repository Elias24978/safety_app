class Candidato {
  final String recordId;
  final String userId;
  final String nombre;
  final String email;
  final String? telefono;
  final String? fechaNacimiento;
  final String? sexo;
  final String? estado;
  final String? ciudad;
  final String? nivelDeEstudios;
  final String? resumenCv;
  final String? cvUrl;
  final String? cvFileName;
  final String perfilActivo;
  final DateTime ultimoModificacion;

  Candidato({
    required this.recordId,
    required this.userId,
    required this.nombre,
    required this.email,
    this.telefono,
    this.fechaNacimiento,
    this.sexo,
    this.estado,
    this.ciudad,
    this.nivelDeEstudios,
    this.resumenCv,
    this.cvUrl,
    this.cvFileName,
    required this.perfilActivo,
    required this.ultimoModificacion,
  });

  factory Candidato.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] as Map<String, dynamic>;

    // ✅ CORRECCIÓN: Se elimina la lógica para 'attachments' ya que CV_URL es un campo de texto.
    // final cvAttachments = fields['CV_URL'] as List<dynamic>?;

    return Candidato(
      recordId: record['id'] ?? '',
      userId: fields['UserID'] ?? '',
      nombre: fields['Nombre_Completo'] ?? 'Nombre no disponible',
      email: fields['Email'] ?? 'Email no disponible',
      // ✅ CORRECCIÓN: Se usa el nombre de campo exacto de Airtable ('Telefono' con T mayúscula)
      telefono: fields['Telefono'],
      fechaNacimiento: fields['Fecha_de_Nacimiento'],
      sexo: fields['Sexo'],
      estado: fields['Estado'],
      ciudad: fields['Ciudad'],
      nivelDeEstudios: fields['Nivel_de_estudios'],
      resumenCv: fields['Resumen_cv'],
      // ✅ CORRECCIÓN: Se leen los campos CV_URL y CV_FileName como texto simple.
      cvUrl: fields['CV_URL'],
      cvFileName: fields['CV_FileName'],
      perfilActivo: fields['Perfil_Activo'] ?? 'Oculto',
      ultimoModificacion: DateTime.parse(fields['ultimo_modificacion'] ?? DateTime.now().toIso8601String()),
    );
  }
}