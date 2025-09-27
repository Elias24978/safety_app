// lib/screens/dc3/dc3_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:safety_app/models/dc3_data.dart';
import 'package:safety_app/services/pdf_service.dart';
import 'package:safety_app/utils/dc3_catalogs.dart';

class DC3FormScreen extends StatefulWidget {
  const DC3FormScreen({super.key});

  @override
  State<DC3FormScreen> createState() => _DC3FormScreenState();
}

class _DC3FormScreenState extends State<DC3FormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ... Controllers
  final _nombreTrabajadorController = TextEditingController();
  final _puestoController = TextEditingController();
  String? _selectedOcupacion;
  final _razonSocialController = TextEditingController();
  final _nombreCursoController = TextEditingController();
  final _duracionController = TextEditingController();
  String? _selectedArea;
  final _agenteCapacitadorController = TextEditingController();
  final _nombreInstructorController = TextEditingController();
  final _nombrePatronController = TextEditingController();
  final _nombreRepresentanteController = TextEditingController();
  late List<TextEditingController> _curpControllers;
  late List<TextEditingController> _rfcControllers;
  final _fechaInicioDia = TextEditingController();
  final _fechaInicioMes = TextEditingController();
  final _fechaInicioAnio = TextEditingController();
  final _fechaFinDia = TextEditingController();
  final _fechaFinMes = TextEditingController();
  final _fechaFinAnio = TextEditingController();

  @override
  void initState() {
    super.initState();
    _curpControllers = List.generate(18, (_) => TextEditingController());
    _rfcControllers = List.generate(13, (_) => TextEditingController());
  }

  @override
  void dispose() {
    // ... dispose methods
    super.dispose();
  }

  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generando PDF..."),
            ],
          ),
        ),
      ),
    );

    try {
      final curp = _curpControllers.map((c) => c.text).join('');
      final rfc = _rfcControllers.map((c) => c.text).join('');
      final fechaInicioStr = '${_fechaInicioDia.text}/${_fechaInicioMes.text}/${_fechaInicioAnio.text}';
      final fechaFinStr = '${_fechaFinDia.text}/${_fechaFinMes.text}/${_fechaFinAnio.text}';

      final fechaInicio = DateFormat('d/M/yyyy').parseStrict(fechaInicioStr);
      final fechaFin = DateFormat('d/M/yyyy').parseStrict(fechaFinStr);

      // --- CAMBIO AQUÍ: Pasamos las claves seleccionadas directamente ---
      final data = DC3Data(
        nombreTrabajador: _nombreTrabajadorController.text,
        curp: curp,
        puesto: _puestoController.text,
        ocupacionEspecificaKey: _selectedOcupacion!, // Pasa la clave, no el valor
        razonSocial: _razonSocialController.text,
        rfc: rfc,
        nombreCurso: _nombreCursoController.text,
        duracionHoras: int.tryParse(_duracionController.text) ?? 0,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        areaTematicaKey: _selectedArea!, // Pasa la clave, no el valor
        nombreAgenteCapacitador: _agenteCapacitadorController.text,
        nombreInstructor: _nombreInstructorController.text,
        nombrePatron: _nombrePatronController.text,
        nombreRepresentanteTrabajadores: _nombreRepresentanteController.text,
      );

      final pdfService = PdfService();
      await pdfService.generateAndSaveDC3(data);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar Constancia DC-3')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Datos del Trabajador', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                controller: _nombreTrabajadorController,
                decoration: const InputDecoration(labelText: 'Nombre (Anotar apellido paterno, apellido materno y nombre (s))'),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_UpperCaseTextFormatter()],
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              const Text('CURP'),
              _SplitInputWidget(controllers: _curpControllers, length: 18, isRequired: true),
              TextFormField(
                controller: _puestoController,
                decoration: const InputDecoration(labelText: 'Puesto*'),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_UpperCaseTextFormatter()],
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedOcupacion,
                hint: const Text('Ocupación Específica (Catálogo)'),
                isExpanded: true,
                items: catalogoOcupaciones.keys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text('$key ${catalogoOcupaciones[key]!.toUpperCase()}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedOcupacion = val),
                validator: (v) => v == null ? 'Seleccione una opción' : null,
              ),
              const SizedBox(height: 20),

              Text('Datos de la Empresa (Opcional)', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                controller: _razonSocialController,
                decoration: const InputDecoration(labelText: 'Nombre o Razón Social'),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 10),
              const Text('RFC con Homoclave'),
              _SplitInputWidget(controllers: _rfcControllers, length: 13, isRequired: false),
              const SizedBox(height: 20),

              Text('Datos del Programa de Capacitación', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                  controller: _nombreCursoController,
                  decoration: const InputDecoration(labelText: 'Nombre del curso'),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [_UpperCaseTextFormatter()],
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
              TextFormField(
                  controller: _duracionController,
                  decoration: const InputDecoration(labelText: 'Duración en horas'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
              const SizedBox(height: 10),
              const Text('Periodo de Ejecución'),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _fechaInicioDia, decoration: const InputDecoration(labelText: 'Día'), keyboardType: TextInputType.number, maxLength: 2)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _fechaInicioMes, decoration: const InputDecoration(labelText: 'Mes'), keyboardType: TextInputType.number, maxLength: 2)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _fechaInicioAnio, decoration: const InputDecoration(labelText: 'Año'), keyboardType: TextInputType.number, maxLength: 4)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('a')),
                  Expanded(child: TextFormField(controller: _fechaFinDia, decoration: const InputDecoration(labelText: 'Día'), keyboardType: TextInputType.number, maxLength: 2)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _fechaFinMes, decoration: const InputDecoration(labelText: 'Mes'), keyboardType: TextInputType.number, maxLength: 2)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _fechaFinAnio, decoration: const InputDecoration(labelText: 'Año'), keyboardType: TextInputType.number, maxLength: 4)),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _selectedArea,
                hint: const Text('Área temática del curso'),
                isExpanded: true,
                items: catalogoAreasTematicas.keys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text('$key ${catalogoAreasTematicas[key]!.toUpperCase()}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedArea = val),
                validator: (v) => v == null ? 'Seleccione una opción' : null,
              ),
              TextFormField(
                  controller: _agenteCapacitadorController,
                  decoration: const InputDecoration(labelText: 'Nombre del agente capacitador o STPS'),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [_UpperCaseTextFormatter()],
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
              const SizedBox(height: 20),
              Text('Firmas', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                  controller: _nombreInstructorController,
                  decoration: const InputDecoration(labelText: 'Nombre Instructor o tutor'),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [_UpperCaseTextFormatter()],
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
              TextFormField(
                controller: _nombrePatronController,
                decoration: const InputDecoration(labelText: 'Nombre Patrón o representante legal'),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_UpperCaseTextFormatter()],
              ),
              TextFormField(
                controller: _nombreRepresentanteController,
                decoration: const InputDecoration(labelText: 'Nombre Representante de los trabajadores'),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generatePdf,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Generar y Descargar PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGETS AUXILIARES (Sin cambios) ---
class _SplitInputWidget extends StatelessWidget {
  final List<TextEditingController> controllers;
  final int length;
  final bool isRequired;

  const _SplitInputWidget({
    required this.controllers,
    required this.length,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      children: List.generate(length, (index) {
        return SizedBox(
          width: 28,
          height: 40,
          child: TextFormField(
            controller: controllers[index],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
            maxLength: 1,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              _UpperCaseTextFormatter(),
            ],
            onChanged: (value) {
              if (value.isNotEmpty && index < length - 1) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
            validator: isRequired ? (v) => v!.isEmpty ? '' : null : null,
          ),
        );
      }),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}