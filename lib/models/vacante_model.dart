import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class Vacante {
  final String id;
  final String titulo;
  final String nombreEmpresa;
  final String ubicacion;
  final String descripcion;
  final double? sueldo;
  final bool aceptaForaneos;
  final String visibilidadOferta; // ✅ AÑADIDO
  final DateTime ultimoModificacion;
  final DateTime fechaPublicacion;

  Vacante({
    required this.id,
    required this.titulo,
    required this.nombreEmpresa,
    required this.ubicacion,
    required this.descripcion,
    this.sueldo,
    required this.aceptaForaneos,
    required this.visibilidadOferta, // ✅ AÑADIDO
    required this.ultimoModificacion,
    required this.fechaPublicacion,
  });

  factory Vacante.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] as Map<String, dynamic>;
    final nombreEmpresaList = fields['Nombre_Empresa'] as List<dynamic>?;

    return Vacante(
      id: record['id'] ?? '',
      titulo: fields['Titulo_Vacante'] ?? 'Sin Título',
      nombreEmpresa: nombreEmpresaList?.isNotEmpty == true
          ? nombreEmpresaList![0] as String
          : 'Empresa Confidencial',
      ubicacion: fields['Ubicacion'] ?? 'Ubicación no especificada',
      descripcion: fields['Descripcion_Puesto'] ?? 'Sin descripción',
      sueldo: (fields['Sueldo_Ofertado'] as num?)?.toDouble(),
      aceptaForaneos: fields['Acepta_Foraneos'] ?? false,
      visibilidadOferta: fields['Visibilidad_Oferta'] ?? 'Oculta', // ✅ AÑADIDO
      ultimoModificacion: DateTime.parse(fields['Ultimo_modificacion'] ?? DateTime.now().toIso8601String()),
      fechaPublicacion: DateTime.parse(fields['Fecha_Publicacion'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get sueldoFormateado {
    if (sueldo == null || sueldo == 0) {
      return "Sueldo no mostrado por la empresa";
    }
    final formatCurrency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return "${formatCurrency.format(sueldo)} Mensual";
  }

  String get antiguedad {
    timeago.setLocaleMessages('es', timeago.EsMessages());
    return timeago.format(fechaPublicacion, locale: 'es');
  }
}