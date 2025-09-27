// lib/services/pdf_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_app/models/dc3_data.dart';
import 'package:safety_app/utils/dc3_catalogs.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<void> generateAndSaveDC3(DC3Data data) async {
    try {
      final byteData = await rootBundle.load('assets/dc3_template.pdf');
      final bytes = byteData.buffer.asUint8List();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfForm form = document.form;

      final String ocupacionDesc = catalogoOcupaciones[data.ocupacionEspecificaKey] ?? '';
      final String ocupacionText = '${data.ocupacionEspecificaKey} $ocupacionDesc'.toUpperCase();

      final String areaDesc = catalogoAreasTematicas[data.areaTematicaKey] ?? '';
      final String areaText = '${data.areaTematicaKey} $areaDesc'.toUpperCase();

      _fillTextField(form, 'nombre_trabajador', data.nombreTrabajador);
      _fillTextField(form, 'ocupacion', ocupacionText);
      _fillTextField(form, 'puesto', data.puesto);
      _fillTextField(form, 'razon_social', data.razonSocial);
      _fillTextField(form, 'nombre_curso', data.nombreCurso);
      _fillTextField(form, 'duracion', data.duracionHoras.toString());
      _fillTextField(form, 'area_tematica', areaText);
      _fillTextField(form, 'agente_capacitador', data.nombreAgenteCapacitador);
      _fillTextField(form, 'firma_instructor', data.nombreInstructor);

      final patronText = data.nombrePatron.trim().isEmpty ? '' : 'C. ${data.nombrePatron}';
      _fillTextField(form, 'firma_patron', patronText);

      final representanteText = data.nombreRepresentanteTrabajadores.trim().isEmpty ? '' : 'C. ${data.nombreRepresentanteTrabajadores}';
      _fillTextField(form, 'firma_representante', representanteText);

      _fillSplitText(form, List.generate(18, (i) => '${i + 1}'), data.curp);
      _fillSplitText(form, List.generate(13, (i) => 'a$i'), data.rfc);

      final formattedInicio = DateFormat('ddMMyyyy').format(data.fechaInicio);
      _fillSplitText(form, ['d0','d1','m0','m1','ao0','ao1','ao2','ao3'], formattedInicio);

      final formattedFin = DateFormat('ddMMyyyy').format(data.fechaFin);
      _fillSplitText(form, ['d2','d3','m2','m3','ao4','ao5','ao6','ao7'], formattedFin);

      final List<int> newBytes = await document.save();
      document.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'DC3_${data.nombreTrabajador.replaceAll(' ', '_')}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(newBytes, flush: true);

      await OpenFilex.open(file.path);

    } catch (e) {
      print('Ocurrió un error al generar el PDF: $e');
      rethrow;
    }
  }

  dynamic _findField(PdfForm form, String name) {
    for (int i = 0; i < form.fields.count; i++) {
      if (form.fields[i].name?.toLowerCase() == name.toLowerCase()) {
        return form.fields[i];
      }
    }
    return null;
  }

  void _fillTextField(PdfForm form, String name, String value) {
    final dynamic field = _findField(form, name);
    if (field is PdfTextBoxField) {
      field.text = value;
    } else {
      print('Advertencia: Campo de texto "$name" no encontrado en el PDF.');
    }
  }

  void _fillSplitText(PdfForm form, List<String> fieldNames, String text) {
    for (int i = 0; i < text.length && i < fieldNames.length; i++) {
      _fillTextField(form, fieldNames[i], text[i]);
    }
  }
}