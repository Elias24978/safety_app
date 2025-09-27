// lib/models/dc3_data.dart

class DC3Data {
  final String nombreTrabajador;
  final String curp;
  final String puesto;
  final String ocupacionEspecificaKey; // CAMBIO: Guardará la clave (ej: '01.2')
  final String razonSocial;
  final String rfc;
  final String nombreCurso;
  final int duracionHoras;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String areaTematicaKey; // CAMBIO: Guardará la clave (ej: '6000')
  final String nombreAgenteCapacitador;
  final String nombreInstructor;
  final String nombrePatron;
  final String nombreRepresentanteTrabajadores;

  DC3Data({
    required this.nombreTrabajador,
    required this.curp,
    required this.puesto,
    required this.ocupacionEspecificaKey,
    required this.razonSocial,
    required this.rfc,
    required this.nombreCurso,
    required this.duracionHoras,
    required this.fechaInicio,
    required this.fechaFin,
    required this.areaTematicaKey,
    required this.nombreAgenteCapacitador,
    required this.nombreInstructor,
    required this.nombrePatron,
    required this.nombreRepresentanteTrabajadores,
  });
}