// lib/screens/bolsa_trabajo/editar_cv_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/services/airtable_service.dart';

class EditarCvScreen extends StatefulWidget {
  final Candidato candidato;

  const EditarCvScreen({super.key, required this.candidato});

  @override
  State<EditarCvScreen> createState() => _EditarCvScreenState();
}

class _EditarCvScreenState extends State<EditarCvScreen> {
  final _formKey = GlobalKey<FormState>();
  final _airtableService = AirtableService();
  bool _isLoading = false;

  // ✅ CAMBIO: Controladores para todos los campos editables
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _fechaNacimientoController;
  late TextEditingController _estadoController;
  late TextEditingController _ciudadController;
  late TextEditingController _resumenController;

  // ✅ CAMBIO: Variable de estado para el dropdown
  String? _selectedNivelEstudios;

  @override
  void initState() {
    super.initState();
    // Pre-llenamos el formulario con los datos existentes del candidato
    _nombreController = TextEditingController(text: widget.candidato.nombre);
    _emailController = TextEditingController(text: widget.candidato.email);
    _telefonoController = TextEditingController(text: widget.candidato.telefono);
    _estadoController = TextEditingController(text: widget.candidato.estado);
    _ciudadController = TextEditingController(text: widget.candidato.ciudad);
    _resumenController = TextEditingController(text: widget.candidato.resumenCv);

    if (widget.candidato.fechaDeNacimiento != null) {
      _fechaNacimientoController = TextEditingController(
        text: DateFormat('dd-MM-yyyy').format(widget.candidato.fechaDeNacimiento!),
      );
    } else {
      _fechaNacimientoController = TextEditingController();
    }

    _selectedNivelEstudios = widget.candidato.nivelDeEstudios;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Formateamos la fecha al formato que Airtable espera (yyyy-MM-dd)
      final fechaNacimientoAirtable = _fechaNacimientoController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(_fechaNacimientoController.text))
          : null;

      // ✅ CAMBIO: Mapa con todos los campos que se van a actualizar
      final Map<String, dynamic> fieldsToUpdate = {
        'Nombre_Completo': _nombreController.text,
        'Email': _emailController.text,
        'Telefono': _telefonoController.text,
        'Fecha_de_Nacimiento': fechaNacimientoAirtable,
        'Estado': _estadoController.text,
        'Ciudad': _ciudadController.text,
        'Resumen_cv': _resumenController.text,
        'Nivel_de_estudios': _selectedNivelEstudios,
      };

      final success = await _airtableService.updateCandidatoProfile(
        widget.candidato.recordId,
        fieldsToUpdate,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Perfil actualizado!')));
        Navigator.of(context).pop(true); // Regresa a la pantalla anterior indicando que hubo cambios
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar el perfil.')));
      }
    }
  }

  // ✅ CAMBIO: Se añade la función para el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.candidato.fechaDeNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre Completo*'), validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email de Contacto*'), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null),
              const SizedBox(height: 16),
              // ✅ CAMBIO: Se añaden los nuevos campos al formulario
              TextFormField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono*'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaNacimientoController,
                decoration: const InputDecoration(labelText: 'Fecha de Nacimiento*', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _estadoController, decoration: const InputDecoration(labelText: 'Estado*'), validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _ciudadController, decoration: const InputDecoration(labelText: 'Ciudad*'), validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null)),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedNivelEstudios,
                hint: const Text('Nivel de estudios*'),
                items: ['Preparatoria', 'Licenciatura', 'Maestría', 'Otro'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedNivelEstudios = newValue),
                validator: (v) => v == null ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _resumenController, decoration: const InputDecoration(labelText: 'Resumen Profesional*', alignLabelWithHint: true), maxLines: 5, validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    _estadoController.dispose();
    _ciudadController.dispose();
    _resumenController.dispose();
    super.dispose();
  }
}