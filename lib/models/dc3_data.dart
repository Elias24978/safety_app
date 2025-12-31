import 'package:intl/intl.dart';

class DC3Data {
  // --- Datos del Trabajador ---
  final String nombreTrabajador;
  final String curp;
  final String puesto;
  final String ocupacionEspecificaKey; // Clave del catálogo (ej: '01.2')

  // --- Datos de la Empresa ---
  final String razonSocial;
  final String rfc;

  // --- Datos del Programa / Curso ---
  final String nombreCurso;
  final int duracionHoras;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String areaTematicaKey; // Clave del catálogo (ej: '6000')

  // --- Datos del Instructor / Agente ---
  final String nombreAgenteCapacitador;
  final String nombreInstructor;
  final String? registroAgente; // Opcional, viene de Airtable

  // --- Firmas ---
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
    this.registroAgente,
    required this.nombrePatron,
    required this.nombreRepresentanteTrabajadores,
  });

  // --- HELPERS PARA EL PDF ---
  String get anioInicio => DateFormat('yyyy').format(fechaInicio);
  String get mesInicio => DateFormat('MM').format(fechaInicio);
  String get diaInicio => DateFormat('dd').format(fechaInicio);

  String get anioFin => DateFormat('yyyy').format(fechaFin);
  String get mesFin => DateFormat('MM').format(fechaFin);
  String get diaFin => DateFormat('dd').format(fechaFin);
}