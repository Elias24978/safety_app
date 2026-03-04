import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safety_app/services/certification_service.dart';
import 'package:safety_app/services/marketplace_service.dart';
import 'package:intl/intl.dart';
import 'package:safety_app/utils/dc3_catalogs.dart';

class MarketplaceDC3FormScreen extends StatefulWidget {
  final String cursoId;
  final String cursoNombre;
  final String cursoDuracion;
  final String instructorNombre;
  final String instructorEmail;
  final String instructorStps;
  final String folio;
  final double notaFinal;

  const MarketplaceDC3FormScreen({
    super.key,
    required this.cursoId,
    required this.cursoNombre,
    required this.cursoDuracion,
    required this.instructorNombre,
    required this.instructorEmail,
    required this.instructorStps,
    required this.folio,
    required this.notaFinal,
  });

  @override
  State<MarketplaceDC3FormScreen> createState() => _MarketplaceDC3FormScreenState();
}

class _MarketplaceDC3FormScreenState extends State<MarketplaceDC3FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _certificationService = CertificationService();
  final MarketplaceService _marketplaceService = MarketplaceService();

  late TextEditingController _nombreController;
  late TextEditingController _curpController;
  late TextEditingController _puestoController;
  late TextEditingController _emailController;

  String? _selectedOcupacion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _curpController = TextEditingController();
    _puestoController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _curpController.dispose();
    _puestoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_isLoading) return; // ✅ Anti-Doble Clic
    if (!_formKey.currentState!.validate()) return;

    if (_curpController.text.length != 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La CURP debe tener exactamente 18 caracteres.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String ocupacionFinal = _selectedOcupacion != null
        ? "$_selectedOcupacion - ${catalogoOcupaciones[_selectedOcupacion]}"
        : "No especificada";

    try {
      // 🚨 PASO 1: VALIDACIÓN Y PETICIÓN
      final success = await _certificationService.requestCertificate(
        studentName: _nombreController.text.trim(),
        curp: _curpController.text.trim().toUpperCase(),
        courseName: widget.cursoNombre,
        courseDuration: widget.cursoDuracion,
        instructorName: widget.instructorNombre,
        instructorStps: widget.instructorStps,
        folio: widget.folio,
        instructorEmail: widget.instructorEmail,
        adminEmail: "masterindustrialsafety@gmail.com",
        occupation: ocupacionFinal,
        jobPosition: _puestoController.text.trim().toUpperCase(),
        studentEmail: _emailController.text.trim(),
      );

      if (success) {
        // 🚨 PASO 2: QUEMAR CARTUCHO EN BASE DE DATOS
        bool exitoCierre = await _marketplaceService.marcarCursoComoCompletado(widget.cursoId);

        if (!exitoCierre) {
          debugPrint("Alerta Crítica: El certificado se generó pero Firebase falló al guardar el estado.");
        }

        if (!mounted) return;
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() => _isLoading = false); // Permite reintentar si falló el internet
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¡Solicitud Exitosa! 🚀'),
        content: const Text(
          'Hemos recibido tus datos correctamente.\n\n'
              'El sistema generará tu DC-3 preliminar y lo enviará para validación de firmas. Recibirás el documento final en tu correo en un plazo máximo de 24 horas.\n\nEl curso ha sido marcado como completado.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // 🔒 DESTRUYE EL HISTORIAL Y VUELVE AL INICIO PREVINIENDO ATAQUE DE REENVÍO
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fechaStr = DateFormat('dd/MM/yyyy').format(now);

    // ✅ Prevención de interrupción de transacción: WillPopScope
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Procesando tu certificado, por favor espera..."))
          );
          return false; // Bloquea el botón "Atrás" mientras carga
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Confirmar Datos DC-3'),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("RESUMEN DE CERTIFICACIÓN",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text("Nota: ${widget.notaFinal.toStringAsFixed(1)}",
                                style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      const Divider(),
                      _infoRow(Icons.school, "Curso:", widget.cursoNombre),
                      const SizedBox(height: 6),
                      _infoRow(Icons.timer, "Duración:", widget.cursoDuracion),
                      const SizedBox(height: 6),
                      _infoRow(Icons.date_range, "Periodo:", "$fechaStr - $fechaStr"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.person_pin, "Instructor:", widget.instructorNombre),
                      const SizedBox(height: 6),
                      _infoRow(Icons.qr_code, "Folio:", widget.folio),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "DATOS DEL TRABAJADOR",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const Divider(),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (Anotar apellido paterno, apellido materno y nombre (s))',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [UpperCaseTextFormatter()],
                  validator: (v) => (v == null || v.isEmpty) ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 16),

                const Text("Clave Única de Registro de Población (CURP)",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                _CurpInputBoxes(controller: _curpController),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _puestoController,
                  decoration: const InputDecoration(
                    labelText: 'Puesto',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [UpperCaseTextFormatter()],
                  validator: (v) => (v == null || v.isEmpty) ? 'El puesto es obligatorio' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedOcupacion,
                  isExpanded: true,
                  hint: const Text('Ocupación Específica (Catálogo)'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: catalogoOcupaciones.keys.map((String key) {
                    String texto = '$key - ${catalogoOcupaciones[key]!}';
                    return DropdownMenuItem(
                        value: key,
                        child: Text(
                            texto.length > 35 ? "${texto.substring(0, 35)}..." : texto,
                            style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedOcupacion = val),
                  validator: (v) => v == null ? 'Seleccione opción' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico (Para envío)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitRequest,
                    icon: const Icon(Icons.check_circle_outline, size: 24),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("GENERAR DC-3 Y FINALIZAR", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Text("$label ", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2)),
      ],
    );
  }
}

class _CurpInputBoxes extends StatefulWidget {
  final TextEditingController controller;
  const _CurpInputBoxes({required this.controller});
  @override
  State<_CurpInputBoxes> createState() => _CurpInputBoxesState();
}

class _CurpInputBoxesState extends State<_CurpInputBoxes> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() { setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 1, width: 1,
          child: TextFormField(
            controller: widget.controller,
            autofocus: false,
            maxLength: 18,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(counterText: "", border: InputBorder.none, contentPadding: EdgeInsets.zero),
            cursorColor: Colors.transparent,
            enableInteractiveSelection: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              UpperCaseTextFormatter(),
            ],
          ),
        ),
        GestureDetector(
          onTap: () { FocusScope.of(context).nextFocus(); },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(9, (index) => _buildBox(index)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(9, (index) => _buildBox(index + 9)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBox(int index) {
    String char = "";
    if (index < widget.controller.text.length) {
      char = widget.controller.text[index];
    }
    bool isFocused = index == widget.controller.text.length;
    return Container(
      width: 32, height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isFocused ? const Color(0xFF0D47A1) : Colors.grey.shade400, width: isFocused ? 2 : 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(char, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}