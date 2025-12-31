import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/models/dc3_data.dart';
import 'package:safety_app/services/pdf_service.dart';
import 'package:safety_app/services/marketplace_service.dart';
import 'package:safety_app/utils/dc3_catalogs.dart';

class MarketplaceDC3FormScreen extends StatefulWidget {
  final Curso curso;

  const MarketplaceDC3FormScreen({super.key, required this.curso});

  @override
  State<MarketplaceDC3FormScreen> createState() => _MarketplaceDC3FormScreenState();
}

class _MarketplaceDC3FormScreenState extends State<MarketplaceDC3FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _marketplaceService = MarketplaceService();
  bool _isLoading = false;

  // --- CONTROLADORES TRABAJADOR ---
  final _nombreTrabajadorController = TextEditingController();
  final _puestoController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedOcupacion;
  late List<TextEditingController> _curpControllers;

  // --- CONTROLADORES PROGRAMA (Automáticos desde Airtable) ---
  final _nombreCursoController = TextEditingController();
  final _duracionController = TextEditingController();
  final _areaTematicaController = TextEditingController();
  final _agenteCapacitadorController = TextEditingController();

  // --- CONTROLADORES FECHAS ---
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

    // 1. Llenado automático de datos del curso
    _nombreCursoController.text = widget.curso.titulo;
    _duracionController.text = widget.curso.duracionHoras.toString();
    _areaTematicaController.text = widget.curso.areaTematicaClave;
    _agenteCapacitadorController.text = widget.curso.nombreAgenteCapacitador;

    // 2. Llenado automático de fechas (Hoy)
    final now = DateTime.now();
    _llenarFechas(now);
  }

  void _llenarFechas(DateTime fecha) {
    String dia = fecha.day.toString().padLeft(2, '0');
    String mes = fecha.month.toString().padLeft(2, '0');
    String anio = fecha.year.toString();

    _fechaInicioDia.text = dia; _fechaInicioMes.text = mes; _fechaInicioAnio.text = anio;
    _fechaFinDia.text = dia; _fechaFinMes.text = mes; _fechaFinAnio.text = anio;
  }

  @override
  void dispose() {
    _nombreTrabajadorController.dispose();
    _puestoController.dispose();
    _emailController.dispose();
    for (var c in _curpControllers) {
      c.dispose();
    }
    _nombreCursoController.dispose();
    _duracionController.dispose();
    _areaTematicaController.dispose();
    _agenteCapacitadorController.dispose();
    _fechaInicioDia.dispose(); _fechaInicioMes.dispose(); _fechaInicioAnio.dispose();
    _fechaFinDia.dispose(); _fechaFinMes.dispose(); _fechaFinAnio.dispose();
    super.dispose();
  }

  Future<void> _procesarFlujoFinal() async {
    if (!_formKey.currentState!.validate()) return;

    String curpCompleta = _curpControllers.map((c) => c.text.toUpperCase()).join('');
    if (curpCompleta.length < 18) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La CURP debe tener 18 caracteres')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 🚨 PASO CRÍTICO DE SEGURIDAD 🚨
      // Intentamos "quemar el cartucho" (cambiar estado a certificado_emitido) ANTES de generar el PDF.
      // Si esto falla, es porque el usuario ya lo usó o no tiene permiso.
      bool exitoCierre = await _marketplaceService.marcarCursoComoCompletado(widget.curso.id);

      if (!exitoCierre) {
        throw Exception("Error de validación: Este curso ya fue completado o la sesión expiró. Debes adquirirlo nuevamente para generar otra constancia.");
      }

      // Si pasamos el filtro de seguridad, procedemos a generar el documento
      final fechaCertificacion = DateTime(
        int.parse(_fechaInicioAnio.text),
        int.parse(_fechaInicioMes.text),
        int.parse(_fechaInicioDia.text),
      );

      final data = DC3Data(
        nombreTrabajador: _nombreTrabajadorController.text.toUpperCase(),
        curp: curpCompleta,
        puesto: _puestoController.text.toUpperCase(),
        ocupacionEspecificaKey: _selectedOcupacion!,

        nombreCurso: _nombreCursoController.text,
        duracionHoras: int.tryParse(_duracionController.text) ?? 4,
        fechaInicio: fechaCertificacion,
        fechaFin: fechaCertificacion,
        areaTematicaKey: _areaTematicaController.text,
        nombreAgenteCapacitador: _agenteCapacitadorController.text,
        registroAgente: widget.curso.registroAgenteSTPS,

        razonSocial: "EMPRESA DEMO S.A. DE C.V.",
        rfc: "XAXX010101000",
        nombreInstructor: widget.curso.nombreInstructor.toUpperCase(),
        nombrePatron: "REPRESENTANTE LEGAL",
        nombreRepresentanteTrabajadores: "REP. TRABAJADORES",
      );

      final pdfService = PdfService();
      final File pdfFile = await pdfService.generateAndSaveDC3(data);

      await OpenFilex.open(pdfFile.path);

      if (_emailController.text.isNotEmpty) {
        try {
          final Email email = Email(
            body: 'Hola ${data.nombreTrabajador},\n\nAdjunto encontrarás tu constancia DC-3.',
            subject: 'Certificado DC-3: ${widget.curso.titulo}',
            recipients: [_emailController.text],
            attachmentPaths: [pdfFile.path],
            isHTML: false,
          );
          await FlutterEmailSender.send(email);
        } catch (_) {
          debugPrint("No se pudo abrir app de correo");
        }
      }

      if (!mounted) return;
      setState(() { _isLoading = false; });
      _mostrarDialogoSalida();

    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });

      // Mostrar error claro y sacar al usuario si fue intento de fraude o error de estado
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("⚠️ Acceso Denegado"),
          content: Text(e.toString().replaceAll("Exception: ", "")),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Cierra dialogo
                Navigator.of(context).popUntil((route) => route.isFirst); // Saca al usuario al inicio
              },
              child: const Text("Entendido"),
            )
          ],
        ),
      );
    }
  }

  void _mostrarDialogoSalida() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("✅ COMPLETADO"),
        content: const Text("Tu constancia se ha generado y enviado. El curso se marcará como completado."),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("FINALIZAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabledDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Generar Certificado'), backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("DATOS DEL TRABAJADOR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Divider(),
              TextFormField(
                controller: _nombreTrabajadorController,
                decoration: const InputDecoration(labelText: 'Nombre (Anotar apellido paterno, apellido materno y nombre (s))', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              const Text("CURP"),
              _SplitInputWidget(controllers: _curpControllers, length: 18),
              const SizedBox(height: 10),
              TextFormField(
                controller: _puestoController,
                decoration: const InputDecoration(labelText: 'Puesto', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedOcupacion,
                isExpanded: true,
                hint: const Text('Ocupación Específica (Catálogo)'),
                items: catalogoOcupaciones.keys.map((String key) {
                  String texto = '$key ${catalogoOcupaciones[key]!.toUpperCase()}';
                  return DropdownMenuItem(value: key, child: Text(texto.length > 35 ? "${texto.substring(0, 35)}..." : texto, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) => setState(() => _selectedOcupacion = val),
                validator: (v) => v == null ? 'Seleccione opción' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico (Para envío)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 30),

              const Text("DATOS DEL PROGRAMA DE CAPACITACIÓN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Divider(),

              TextFormField(
                controller: _nombreCursoController,
                enabled: false,
                decoration: disabledDecoration.copyWith(labelText: 'Nombre del curso'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duracionController,
                      enabled: false,
                      decoration: disabledDecoration.copyWith(labelText: 'Duración (Horas)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _areaTematicaController,
                      enabled: false,
                      decoration: disabledDecoration.copyWith(labelText: 'Clave Área Temática'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _agenteCapacitadorController,
                enabled: false,
                decoration: disabledDecoration.copyWith(labelText: 'Nombre del agente capacitador o STPS'),
              ),

              const SizedBox(height: 15),

              const Text('Periodo de Ejecución', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(child: _DateBox(controller: _fechaInicioDia, label: 'Día')),
                  const SizedBox(width: 5),
                  Expanded(child: _DateBox(controller: _fechaInicioMes, label: 'Mes')),
                  const SizedBox(width: 5),
                  Expanded(flex: 2, child: _DateBox(controller: _fechaInicioAnio, label: 'Año')),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('a')),
                  Expanded(child: _DateBox(controller: _fechaFinDia, label: 'Día')),
                  const SizedBox(width: 5),
                  Expanded(child: _DateBox(controller: _fechaFinMes, label: 'Mes')),
                  const SizedBox(width: 5),
                  Expanded(flex: 2, child: _DateBox(controller: _fechaFinAnio, label: 'Año')),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.verified_user),
                  label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("GENERAR DC-3 Y FINALIZAR"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _procesarFlujoFinal,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _DateBox({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: false,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[200]
      ),
    );
  }
}

class _SplitInputWidget extends StatelessWidget {
  final List<TextEditingController> controllers;
  final int length;

  const _SplitInputWidget({required this.controllers, required this.length});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double boxWidth = (constraints.maxWidth - (length * 2)) / length;
      if (boxWidth > 30) boxWidth = 30;
      return Wrap(
        spacing: 2.0,
        runSpacing: 4.0,
        children: List.generate(length, (index) {
          return SizedBox(
            width: boxWidth,
            height: 40,
            child: TextFormField(
              controller: controllers[index],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(contentPadding: EdgeInsets.zero, border: OutlineInputBorder(), counterText: ''),
              maxLength: 1,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                UpperCaseTextFormatter(),
              ],
              onChanged: (value) {
                if (value.isNotEmpty && index < length - 1) {
                  FocusScope.of(context).nextFocus();
                } else if (value.isEmpty && index > 0) {
                  FocusScope.of(context).previousFocus();
                }
              },
            ),
          );
        }),
      );
    });
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}