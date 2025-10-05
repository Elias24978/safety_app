// lib/models/candidato_model.dart

class Candidato {
  final String recordId;
  final String userId;
  final String nombre;
  final String email;
  final String? telefono;
  final DateTime? fechaDeNacimiento;
  final String? sexo;
  final String? estado;
  final String? ciudad;
  final String? resumenCv;
  final String? cvUrl;
  final String? cvFileName;
  final String? nivelDeEstudios;
  final String? perfilActivo;
  final String? status;

  Candidato({
    required this.recordId,
    required this.userId,
    required this.nombre,
    required this.email,
    this.telefono,
    this.fechaDeNacimiento,
    this.sexo,
    this.estado,
    this.ciudad,
    this.resumenCv,
    this.cvUrl,
    this.cvFileName,
    this.nivelDeEstudios,
    this.perfilActivo,
    this.status,
  });

  factory Candidato.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] as Map<String, dynamic>;
    return Candidato(
      recordId: record['id'] ?? '',
      userId: fields['UserID'] ?? '',
      nombre: fields['Nombre_Completo'] ?? 'Sin Nombre',
      email: fields['Email'] ?? 'Sin Email',
      telefono: fields['Telefono'],
      fechaDeNacimiento: fields['Fecha_de_Nacimiento'] != null
          ? DateTime.tryParse(fields['Fecha_de_Nacimiento'])
          : null,
      sexo: fields['Sexo'],
      estado: fields['Estado'],
      ciudad: fields['Ciudad'],
      resumenCv: fields['Resumen_cv'],
      cvUrl: fields['CV_URL'],
      cvFileName: fields['CV_FileName'],
      nivelDeEstudios: fields['Nivel_de_estudios'],
      perfilActivo: fields['Perfil_Activo'],
      status: fields['Status'],
    );
  }
}